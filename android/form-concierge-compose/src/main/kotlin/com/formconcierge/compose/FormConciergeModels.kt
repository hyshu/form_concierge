package com.formconcierge.compose

import android.content.Context
import android.os.Build
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonElement
import java.util.Locale
import java.util.TimeZone

@Serializable
public enum class QuestionType {
    @SerialName("singleChoice")
    SingleChoice,

    @SerialName("multipleChoice")
    MultipleChoice,

    @SerialName("textSingle")
    TextSingle,

    @SerialName("textMultiLine")
    TextMultiLine,

    @SerialName("imageUpload")
    ImageUpload,
}

@Serializable
public enum class SurveyStatus {
    @SerialName("draft")
    Draft,

    @SerialName("published")
    Published,

    @SerialName("closed")
    Closed,

    @SerialName("archived")
    Archived,
}

@Serializable
public enum class VisibilityConditionMode {
    @SerialName("all")
    All,

    @SerialName("any")
    Any,
}

@Serializable
public enum class VisibilityOperator {
    @SerialName("equals")
    Equals,

    @SerialName("notEquals")
    NotEquals,

    @SerialName("contains")
    Contains,

    @SerialName("notContains")
    NotContains,

    @SerialName("isAnswered")
    IsAnswered,

    @SerialName("isNotAnswered")
    IsNotAnswered,
}

public val formContentLocaleCodes: Set<String> =
    setOf(
        "en",
        "ja",
        "zh-Hans",
        "zh-Hant",
        "ko",
        "de",
        "es",
        "fr",
        "it",
        "th",
        "tr",
    )

public fun normalizeFormContentLocale(locale: String): String {
    val normalized = locale.replace('_', '-')
    if (normalized in formContentLocaleCodes) return normalized
    return when (normalized.lowercase(Locale.ROOT)) {
        "zh-hans", "zh-cn", "zh-sg" -> "zh-Hans"
        "zh-hant", "zh-tw", "zh-hk", "zh-mo" -> "zh-Hant"
        else -> normalized.substringBefore('-').takeIf { it in formContentLocaleCodes } ?: normalized
    }
}

@Serializable(with = LocalizedTextSerializer::class)
public data class LocalizedText(
    public val values: Map<String, String> = emptyMap(),
) {
    public fun value(locale: String): String =
        values[normalizeFormContentLocale(locale)]
            ?: values["en"]
            ?: values.values
                .firstOrNull()
                .orEmpty()
}

public object LocalizedTextSerializer : KSerializer<LocalizedText> {
    private val delegate = MapSerializer(String.serializer(), String.serializer())
    override val descriptor: SerialDescriptor = delegate.descriptor

    override fun deserialize(decoder: Decoder): LocalizedText = LocalizedText(decoder.decodeSerializableValue(delegate))

    override fun serialize(
        encoder: Encoder,
        value: LocalizedText,
    ) {
        encoder.encodeSerializableValue(delegate, value.values)
    }
}

@Serializable
public data class Project(
    public val id: Int,
    public val slug: String,
    public val customDomain: String? = null,
    public val defaultLocale: String = "en",
    public val supportedLocales: List<String> = emptyList(),
    public val name: String,
    public val createdAt: String,
    public val updatedAt: String,
)

@Serializable
public data class PublicProject(
    public val project: Project,
    public val surveys: List<Survey>,
)

@Serializable
public data class PublicConfig(
    public val passwordResetEnabled: Boolean = false,
    public val requireEmailVerification: Boolean = false,
    public val aiGenerationEnabled: Boolean = false,
    public val turnstileSiteKey: String? = null,
)

@Serializable
public data class Survey(
    public val id: Int,
    public val projectId: Int,
    public val slug: String,
    public val titleTranslations: LocalizedText,
    public val descriptionTranslations: LocalizedText = LocalizedText(),
    public val status: SurveyStatus,
    public val webEnabled: Boolean = true,
    public val followUpEnabled: Boolean = false,
    @Deprecated("Use captchaRequired for submission behavior")
    public val captchaEnabled: Boolean = true,
    public val captchaRequired: Boolean = captchaEnabled,
    public val startsAt: String? = null,
    public val endsAt: String? = null,
    public val createdAt: String,
    public val updatedAt: String,
) {
    public fun title(locale: String): String = titleTranslations.value(locale)

    public fun description(locale: String): String = descriptionTranslations.value(locale)
}

@Serializable
public data class Question(
    public val id: Int,
    public val surveyId: Int,
    public val textTranslations: LocalizedText,
    public val type: QuestionType,
    public val orderIndex: Int,
    public val isRequired: Boolean,
    public val placeholderTranslations: LocalizedText = LocalizedText(),
    public val minLength: Int? = null,
    public val maxLength: Int? = null,
    public val minSelected: Int? = null,
    public val maxSelected: Int? = null,
    public val visibilityConditionMode: VisibilityConditionMode = VisibilityConditionMode.All,
) {
    public fun text(locale: String): String = textTranslations.value(locale)

    public fun placeholder(locale: String): String = placeholderTranslations.value(locale)
}

@Serializable
public data class QuestionVisibilityRule(
    public val id: Int,
    public val surveyId: Int,
    public val targetQuestionId: Int,
    public val sourceQuestionId: Int,
    public val operator: VisibilityOperator,
    public val value: JsonElement? = null,
    public val createdAt: String? = null,
    public val updatedAt: String? = null,
)

@Serializable
public data class Choice(
    public val id: Int,
    public val questionId: Int,
    public val textTranslations: LocalizedText,
    public val orderIndex: Int,
    public val value: String? = null,
) {
    public fun text(locale: String): String = textTranslations.value(locale)
}

@Serializable
public data class Answer(
    public val surveyResponseId: Int = 0,
    public val questionId: Int,
    public val textValue: String? = null,
    public val selectedChoiceIds: List<Int>? = null,
    public val fileKeys: List<String>? = null,
)

@Serializable
public data class MediaUpload(
    public val key: String,
    public val contentType: String,
    public val size: Int,
)

@Serializable
public enum class FollowUpStatus {
    @SerialName("skipped")
    Skipped,

    @SerialName("pending")
    Pending,

    @SerialName("completed")
    Completed,
}

@Serializable
public data class FollowUpChoice(
    public val id: String,
    public val label: String,
)

@Serializable
public data class FollowUpAnswer(
    public val textValue: String? = null,
    public val selectedChoiceIds: List<String> = emptyList(),
    public val fileKeys: List<String> = emptyList(),
)

@Serializable
public data class FollowUpSubmissionAnswer(
    public val id: String,
    public val textValue: String? = null,
    public val selectedChoiceIds: List<String> = emptyList(),
    public val fileKeys: List<String> = emptyList(),
)

@Serializable
public data class FollowUpItem(
    public val id: String,
    public val type: QuestionType,
    public val text: String,
    public val required: Boolean = false,
    public val placeholder: String? = null,
    public val maxFiles: Int? = null,
    public val choices: List<FollowUpChoice> = emptyList(),
    public val answer: FollowUpAnswer? = null,
)

@Serializable
public data class FollowUp(
    public val version: Int,
    public val status: FollowUpStatus,
    public val generatedAt: String,
    public val completedAt: String? = null,
    public val locale: String,
    public val items: List<FollowUpItem>,
)

@Serializable
public data class FollowUpGenerateResult(
    public val needed: Boolean,
    public val followUp: FollowUp,
    public val error: String? = null,
)

@Serializable
public data class SurveyResponse(
    public val id: Int,
    public val surveyId: Int,
    public val anonymousId: String? = null,
    public val anonymousAccountId: String? = null,
    public val submittedAt: String,
    public val deviceInfo: DeviceInfo? = null,
    public val metadata: Map<String, JsonElement>? = null,
    public val followUp: FollowUp? = null,
    public val replyCount: Int = 0,
)

@Serializable
public data class AnonymousAccount(
    public val id: String,
    public val displayName: String? = null,
    public val createdAt: String,
    public val lastSeenAt: String,
)

@Serializable
public data class AnonymousSession(
    public val account: AnonymousAccount,
    public val token: String,
)

@Serializable
public data class AdminReply(
    public val id: Int,
    public val surveyResponseId: Int,
    public val anonymousAccountId: String,
    public val adminId: String? = null,
    public val body: String,
    public val createdAt: String,
    public val readAt: String? = null,
)

@Serializable
public data class DeviceInfo(
    public val deviceId: String? = null,
    public val label: String? = null,
    public val platform: String? = null,
    public val os: String? = null,
    public val osVersion: String? = null,
    public val browser: String? = null,
    public val browserVersion: String? = null,
    public val appVersion: String? = null,
    public val appBuild: String? = null,
    public val model: String? = null,
    public val manufacturer: String? = null,
    public val locale: String? = null,
    public val timezone: String? = null,
    public val screenWidth: Int? = null,
    public val screenHeight: Int? = null,
    public val devicePixelRatio: Double? = null,
    public val userAgent: String? = null,
) {
    public companion object {
        public fun current(context: Context): DeviceInfo {
            val metrics = context.resources.displayMetrics
            val packageInfo =
                runCatching {
                    context.packageManager.getPackageInfo(context.packageName, 0)
                }.getOrNull()

            @Suppress("DEPRECATION")
            val versionCode =
                packageInfo?.let {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        it.longVersionCode
                    } else {
                        it.versionCode.toLong()
                    }
                }
            return DeviceInfo(
                label = "${Build.MANUFACTURER} ${Build.MODEL}".trim(),
                platform = "android",
                os = "Android",
                osVersion = Build.VERSION.RELEASE,
                appVersion = packageInfo?.versionName,
                appBuild = versionCode?.toString(),
                model = Build.MODEL,
                manufacturer = Build.MANUFACTURER,
                locale = Locale.getDefault().toLanguageTag(),
                timezone = TimeZone.getDefault().id,
                screenWidth = metrics.widthPixels,
                screenHeight = metrics.heightPixels,
                devicePixelRatio = metrics.density.toDouble(),
            )
        }
    }
}

public data class SurveyImagePayload(
    public val bytes: ByteArray,
    public val contentType: String,
)

public typealias ProcessSurveyImage = suspend (SurveyImagePayload) -> SurveyImagePayload?

public sealed interface SurveyAnswerValue {
    public data class Text(
        public val value: String,
    ) : SurveyAnswerValue

    public data class Single(
        public val choiceId: Int,
    ) : SurveyAnswerValue

    public data class Multiple(
        public val choiceIds: Set<Int>,
    ) : SurveyAnswerValue

    public data class Images(
        public val fileKeys: List<String>,
    ) : SurveyAnswerValue
}

internal fun SurveyAnswerValue.isEmpty(): Boolean =
    when (this) {
        is SurveyAnswerValue.Text -> value.isBlank()
        is SurveyAnswerValue.Single -> false
        is SurveyAnswerValue.Multiple -> choiceIds.isEmpty()
        is SurveyAnswerValue.Images -> fileKeys.isEmpty()
    }

public data class FormConciergeSubmission(
    public val response: SurveyResponse,
    public val answers: List<Answer>,
    public val questions: List<Question>,
    public val choicesByQuestion: Map<Int, List<Choice>>,
    public val locale: String,
)
