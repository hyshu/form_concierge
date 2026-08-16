package com.formconcierge.compose

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.edit
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.security.KeyStore
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

@Serializable
public data class InquiryContentItem(
    public val question: String,
    public val answer: String? = null,
    public val hasImages: Boolean = false,
)

@Serializable
public data class InquiryRecord(
    public val responseId: Int,
    public val submittedAtEpochMillis: Long,
    public val items: List<InquiryContentItem>,
    public val followUpItems: List<InquiryContentItem> = emptyList(),
    public val repliesSeen: Boolean = false,
) {
    public val title: String
        get() =
            items.firstNotNullOfOrNull { it.answer?.trim()?.takeIf(String::isNotEmpty) }
                ?: items.firstOrNull()?.question
                ?: ""

    public val hasImages: Boolean
        get() = items.any(InquiryContentItem::hasImages)

    public companion object {
        public fun fromSubmission(
            submission: FormConciergeSubmission,
            fallbackTimeMillis: Long = System.currentTimeMillis(),
        ): InquiryRecord {
            val questions = submission.questions.associateBy(Question::id)
            val items =
                submission.answers.mapNotNull { answer ->
                    val question = questions[answer.questionId] ?: return@mapNotNull null
                    val labels =
                        submission.choicesByQuestion[answer.questionId]
                            .orEmpty()
                            .associate { it.id to it.text(submission.locale) }
                    val selected =
                        answer.selectedChoiceIds
                            .orEmpty()
                            .mapNotNull(labels::get)
                    val answerText =
                        buildList {
                            answer.textValue
                                ?.trim()
                                ?.takeIf(String::isNotEmpty)
                                ?.let(::add)
                            addAll(selected)
                        }.joinToString("\n").takeIf(String::isNotEmpty)
                    InquiryContentItem(
                        question = question.text(submission.locale),
                        answer = answerText,
                        hasImages = !answer.fileKeys.isNullOrEmpty(),
                    )
                }
            return InquiryRecord(
                responseId = submission.response.id,
                submittedAtEpochMillis =
                    parseApiTimestamp(submission.response.submittedAt)
                        ?: fallbackTimeMillis,
                items = items,
            )
        }
    }
}

public interface FormConciergeSessionStore {
    public suspend fun readAnonymousToken(): String?

    public suspend fun writeAnonymousToken(token: String)

    public suspend fun readInquiries(): List<InquiryRecord>

    public suspend fun addInquiry(record: InquiryRecord)

    public suspend fun updateFollowUp(
        responseId: Int,
        followUpItems: List<InquiryContentItem>,
    )

    public suspend fun markRepliesSeen(responseId: Int)

    public suspend fun readLastSeenReplyAt(responseId: Int? = null): String?

    public suspend fun writeLastSeenReplyAt(
        responseId: Int? = null,
        timestamp: String,
    )
}

public class AndroidFormConciergeSessionStore(
    context: Context,
    namespace: String = context.packageName,
    private val retentionMonths: Int = 3,
    private val now: () -> Long = System::currentTimeMillis,
) : FormConciergeSessionStore {
    private val preferences =
        context.applicationContext.getSharedPreferences(
            "form_concierge.${namespace.sha256Prefix()}",
            Context.MODE_PRIVATE,
        )
    private val cipher = AndroidKeystoreCipher("form_concierge_${namespace.sha256Prefix()}")
    private val mutex = Mutex()
    private val json =
        Json {
            ignoreUnknownKeys = true
            encodeDefaults = true
        }

    override suspend fun readAnonymousToken(): String? = readEncrypted(TOKEN_KEY)

    override suspend fun writeAnonymousToken(token: String): Unit = writeEncrypted(TOKEN_KEY, token)

    override suspend fun readInquiries(): List<InquiryRecord> =
        mutex.withLock {
            withContext(Dispatchers.IO) {
                val records =
                    preferences
                        .getString(INQUIRIES_KEY, null)
                        ?.let(cipher::decrypt)
                        ?.let { runCatching { json.decodeFromString<List<InquiryRecord>>(it) }.getOrNull() }
                        .orEmpty()
                val retained =
                    records
                        .filter { it.submittedAtEpochMillis >= retentionCutoff(now(), retentionMonths) }
                        .sortedByDescending(InquiryRecord::submittedAtEpochMillis)
                if (retained != records) writeInquiriesLocked(retained)
                retained
            }
        }

    override suspend fun addInquiry(record: InquiryRecord): Unit =
        mutateInquiries { records ->
            if (records.any { it.responseId == record.responseId }) records else listOf(record) + records
        }

    override suspend fun updateFollowUp(
        responseId: Int,
        followUpItems: List<InquiryContentItem>,
    ): Unit =
        mutateInquiries { records ->
            records.map { record ->
                if (record.responseId == responseId) record.copy(followUpItems = followUpItems) else record
            }
        }

    override suspend fun markRepliesSeen(responseId: Int): Unit =
        mutateInquiries { records ->
            records.map { record ->
                if (record.responseId == responseId) record.copy(repliesSeen = true) else record
            }
        }

    override suspend fun readLastSeenReplyAt(responseId: Int?): String? = readEncrypted(lastSeenKey(responseId))

    override suspend fun writeLastSeenReplyAt(
        responseId: Int?,
        timestamp: String,
    ): Unit = writeEncrypted(lastSeenKey(responseId), timestamp)

    private suspend fun mutateInquiries(mutation: (List<InquiryRecord>) -> List<InquiryRecord>) {
        mutex.withLock {
            withContext(Dispatchers.IO) {
                val current =
                    preferences
                        .getString(INQUIRIES_KEY, null)
                        ?.let(cipher::decrypt)
                        ?.let { runCatching { json.decodeFromString<List<InquiryRecord>>(it) }.getOrNull() }
                        .orEmpty()
                        .filter { it.submittedAtEpochMillis >= retentionCutoff(now(), retentionMonths) }
                writeInquiriesLocked(mutation(current).sortedByDescending(InquiryRecord::submittedAtEpochMillis))
            }
        }
    }

    private fun writeInquiriesLocked(records: List<InquiryRecord>) {
        preferences.edit {
            if (records.isEmpty()) {
                remove(INQUIRIES_KEY)
            } else {
                putString(INQUIRIES_KEY, cipher.encrypt(json.encodeToString(records)))
            }
        }
    }

    private suspend fun readEncrypted(key: String): String? =
        mutex.withLock {
            withContext(Dispatchers.IO) {
                preferences.getString(key, null)?.let(cipher::decrypt)
            }
        }

    private suspend fun writeEncrypted(
        key: String,
        value: String,
    ) {
        mutex.withLock {
            withContext(Dispatchers.IO) {
                preferences.edit { putString(key, cipher.encrypt(value)) }
            }
        }
    }

    private fun lastSeenKey(responseId: Int?): String = if (responseId == null) LAST_SEEN_KEY else "$LAST_SEEN_KEY.$responseId"

    private companion object {
        const val TOKEN_KEY = "anonymous_token"
        const val INQUIRIES_KEY = "inquiries"
        const val LAST_SEEN_KEY = "last_seen_reply_at"
    }
}

@Composable
public fun rememberFormConciergeSessionStore(namespace: String = LocalContext.current.packageName): FormConciergeSessionStore {
    val applicationContext = LocalContext.current.applicationContext
    return remember(applicationContext, namespace) {
        AndroidFormConciergeSessionStore(applicationContext, namespace)
    }
}

public fun followUpItemsFromResponse(response: SurveyResponse): List<InquiryContentItem> =
    response.followUp?.items.orEmpty().mapNotNull { item ->
        val answer = item.answer
        val labels = item.choices.associate { it.id to it.label }
        val answerText =
            buildList {
                answer
                    ?.textValue
                    ?.trim()
                    ?.takeIf(String::isNotEmpty)
                    ?.let(::add)
                answer?.selectedChoiceIds.orEmpty().mapNotNullTo(this, labels::get)
            }.joinToString("\n").takeIf(String::isNotEmpty)
        val hasImages = !answer?.fileKeys.isNullOrEmpty()
        if (answerText == null && !hasImages) return@mapNotNull null
        InquiryContentItem(item.text, answerText, hasImages)
    }

private class AndroidKeystoreCipher(
    private val alias: String,
) {
    fun encrypt(plainText: String): String {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, secretKey())
        val encrypted = cipher.doFinal(plainText.toByteArray(Charsets.UTF_8))
        return listOf(
            VERSION,
            Base64.encodeToString(cipher.iv, Base64.NO_WRAP),
            Base64.encodeToString(encrypted, Base64.NO_WRAP),
        ).joinToString(":")
    }

    fun decrypt(encoded: String): String? =
        runCatching {
            val parts = encoded.split(':', limit = 3)
            require(parts.size == 3 && parts[0] == VERSION)
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(
                Cipher.DECRYPT_MODE,
                secretKey(),
                GCMParameterSpec(128, Base64.decode(parts[1], Base64.NO_WRAP)),
            )
            String(
                cipher.doFinal(Base64.decode(parts[2], Base64.NO_WRAP)),
                Charsets.UTF_8,
            )
        }.getOrNull()

    private fun secretKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (keyStore.getKey(alias, null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").run {
            init(
                KeyGenParameterSpec
                    .Builder(
                        alias,
                        KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
                    ).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .build(),
            )
            generateKey()
        }
    }

    private companion object {
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val VERSION = "v1"
    }
}

private fun String.sha256Prefix(): String =
    MessageDigest
        .getInstance("SHA-256")
        .digest(toByteArray(Charsets.UTF_8))
        .take(12)
        .joinToString("") { "%02x".format(it.toInt() and 0xff) }

private fun retentionCutoff(
    nowMillis: Long,
    months: Int,
): Long =
    Calendar.getInstance().run {
        timeInMillis = nowMillis
        add(Calendar.MONTH, -months)
        timeInMillis
    }

internal fun parseApiTimestamp(value: String): Long? {
    val patterns =
        listOf(
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
            "yyyy-MM-dd'T'HH:mm:ssXXX",
            "yyyy-MM-dd HH:mm:ss.SSS",
            "yyyy-MM-dd HH:mm:ss",
        )
    return patterns.firstNotNullOfOrNull { pattern ->
        runCatching {
            SimpleDateFormat(pattern, Locale.US)
                .apply {
                    isLenient = false
                    timeZone = TimeZone.getTimeZone("UTC")
                }.parse(value)
                ?.time
        }.getOrNull()
    }
}
