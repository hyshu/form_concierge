package com.formconcierge.compose

import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import okhttp3.Call
import okhttp3.Callback
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import java.io.IOException
import java.net.URLEncoder
import java.nio.charset.StandardCharsets
import java.util.UUID

public interface FormConciergeApi {
    public fun setAnonymousToken(token: String?)

    public fun hasAnonymousToken(): Boolean

    public suspend fun createAnonymousAccount(displayName: String? = null): AnonymousSession

    public suspend fun project(slug: String): PublicProject

    public suspend fun publicConfig(): PublicConfig

    public suspend fun questions(surveyId: Int): List<Question>

    public suspend fun choices(questionId: Int): List<Choice>

    public suspend fun visibilityRules(surveyId: Int): List<QuestionVisibilityRule>

    public suspend fun submitResponse(
        surveyId: Int,
        answers: List<Answer>,
        deviceInfo: DeviceInfo? = null,
        metadata: Map<String, JsonElement>? = null,
        idempotencyKey: String = UUID.randomUUID().toString().lowercase(),
        captchaToken: String? = null,
    ): SurveyResponse

    public suspend fun generateFollowUp(
        responseId: Int,
        locale: String? = null,
    ): FollowUpGenerateResult

    public suspend fun saveFollowUp(
        responseId: Int,
        answers: List<FollowUpSubmissionAnswer>,
    ): SurveyResponse

    public suspend fun uploadMedia(
        bytes: ByteArray,
        contentType: String,
    ): MediaUpload

    public suspend fun replies(responseId: Int? = null): List<AdminReply>

    public suspend fun latestReplyAt(responseId: Int? = null): String?
}

public class FormConciergeClient(
    baseUrl: String,
    private val httpClient: OkHttpClient = OkHttpClient(),
) : FormConciergeApi {
    private val baseUrl: String = baseUrl.trimEnd('/')
    private val json =
        Json {
            ignoreUnknownKeys = true
            explicitNulls = false
            encodeDefaults = true
        }

    @Volatile
    private var anonymousToken: String? = null

    override fun setAnonymousToken(token: String?) {
        anonymousToken = token?.takeIf(String::isNotBlank)
    }

    override fun hasAnonymousToken(): Boolean = anonymousToken != null

    override suspend fun createAnonymousAccount(displayName: String?): AnonymousSession {
        val session: AnonymousSession =
            request(
                method = "POST",
                path = "/api/anonymous/accounts",
                body = json.encodeToString(CreateAnonymousAccountPayload(displayName)),
            )
        anonymousToken = session.token
        return session
    }

    override suspend fun project(slug: String): PublicProject =
        request(
            method = "GET",
            path = "/api/projects/${slug.urlPathSegment()}",
        )

    override suspend fun publicConfig(): PublicConfig =
        request(
            method = "GET",
            path = "/api/config",
        )

    override suspend fun questions(surveyId: Int): List<Question> =
        request(
            method = "GET",
            path = "/api/surveys/id/$surveyId/questions",
        )

    override suspend fun choices(questionId: Int): List<Choice> =
        request(
            method = "GET",
            path = "/api/questions/$questionId/choices",
        )

    override suspend fun visibilityRules(surveyId: Int): List<QuestionVisibilityRule> =
        request(
            method = "GET",
            path = "/api/surveys/id/$surveyId/visibility-rules",
        )

    override suspend fun submitResponse(
        surveyId: Int,
        answers: List<Answer>,
        deviceInfo: DeviceInfo?,
        metadata: Map<String, JsonElement>?,
        idempotencyKey: String,
        captchaToken: String?,
    ): SurveyResponse {
        if (!hasAnonymousToken()) createAnonymousAccount()
        return request(
            method = "POST",
            path = "/api/surveys/id/$surveyId/responses",
            body =
                json.encodeToString(
                    SubmitResponsePayload(
                        answers = answers,
                        deviceInfo = deviceInfo,
                        metadata = metadata,
                        idempotencyKey = idempotencyKey,
                        captchaToken = captchaToken,
                    ),
                ),
            bearerToken = anonymousToken,
        )
    }

    override suspend fun generateFollowUp(
        responseId: Int,
        locale: String?,
    ): FollowUpGenerateResult =
        request(
            method = "POST",
            path = "/api/responses/$responseId/follow-up/generate",
            body = json.encodeToString(FollowUpGeneratePayload(locale)),
            bearerToken = anonymousToken,
        )

    override suspend fun saveFollowUp(
        responseId: Int,
        answers: List<FollowUpSubmissionAnswer>,
    ): SurveyResponse =
        request(
            method = "PUT",
            path = "/api/responses/$responseId/follow-up",
            body = json.encodeToString(SaveFollowUpPayload(answers)),
            bearerToken = anonymousToken,
        )

    override suspend fun uploadMedia(
        bytes: ByteArray,
        contentType: String,
    ): MediaUpload {
        if (!hasAnonymousToken()) createAnonymousAccount()
        val request =
            Request
                .Builder()
                .url(resolveUrl("/api/media"))
                .header("Accept", "application/json")
                .header("Content-Type", contentType)
                .apply {
                    anonymousToken?.let { header("Authorization", "Bearer $it") }
                }.post(bytes.toRequestBody(contentType.toMediaType()))
                .build()
        return execute(request)
    }

    override suspend fun replies(responseId: Int?): List<AdminReply> =
        request(
            method = "GET",
            path = "/api/anonymous/replies" + responseId?.let { "?responseId=$it" }.orEmpty(),
            bearerToken = anonymousToken,
        )

    override suspend fun latestReplyAt(responseId: Int?): String? {
        val payload: LatestReplyPayload =
            request(
                method = "GET",
                path =
                    "/api/anonymous/replies/latest" +
                        responseId?.let { "?responseId=$it" }.orEmpty(),
                bearerToken = anonymousToken,
            )
        return payload.latestReplyAt
    }

    private suspend inline fun <reified T> request(
        method: String,
        path: String,
        body: String? = null,
        bearerToken: String? = null,
    ): T {
        val request =
            Request
                .Builder()
                .url(resolveUrl(path))
                .header("Accept", "application/json")
                .apply {
                    bearerToken?.let { header("Authorization", "Bearer $it") }
                    if (body != null) {
                        header("Content-Type", "application/json")
                        method(method, body.toRequestBody(JSON_MEDIA_TYPE))
                    } else {
                        method(method, null)
                    }
                }.build()
        return execute(request)
    }

    private suspend inline fun <reified T> execute(request: Request): T =
        suspendCancellableCoroutine { continuation ->
            val call = httpClient.newCall(request)
            continuation.invokeOnCancellation { call.cancel() }
            call.enqueue(
                object : Callback {
                    override fun onFailure(
                        call: Call,
                        e: IOException,
                    ) {
                        if (continuation.isActive) {
                            continuation.resumeWith(Result.failure(e))
                        }
                    }

                    override fun onResponse(
                        call: Call,
                        response: Response,
                    ) {
                        response.use {
                            if (!continuation.isActive) return
                            val result =
                                runCatching {
                                    val body = response.body.string()
                                    if (!response.isSuccessful) {
                                        val message =
                                            runCatching {
                                                json.decodeFromString<ApiErrorPayload>(body).error
                                            }.getOrNull()?.takeIf(String::isNotBlank)
                                                ?: "Request failed with status ${response.code}"
                                        throw FormConciergeException.Api(response.code, message)
                                    }
                                    runCatching { json.decodeFromString<T>(body) }
                                        .getOrElse { cause ->
                                            throw FormConciergeException.InvalidResponse(cause)
                                        }
                                }
                            if (continuation.isActive) continuation.resumeWith(result)
                        }
                    }
                },
            )
        }

    private fun resolveUrl(path: String): String = baseUrl + if (path.startsWith('/')) path else "/$path"

    private fun String.urlPathSegment(): String = URLEncoder.encode(this, StandardCharsets.UTF_8.toString()).replace("+", "%20")

    private companion object {
        val JSON_MEDIA_TYPE = "application/json; charset=utf-8".toMediaType()
    }
}

public sealed class FormConciergeException(
    message: String,
    cause: Throwable? = null,
) : Exception(message, cause) {
    public class Api(
        public val statusCode: Int,
        message: String,
    ) : FormConciergeException(message)

    public class InvalidResponse(
        cause: Throwable,
    ) : FormConciergeException("The server returned an invalid response.", cause)
}

@Serializable
private data class CreateAnonymousAccountPayload(
    val displayName: String? = null,
)

@Serializable
private data class SubmitResponsePayload(
    val answers: List<Answer>,
    val deviceInfo: DeviceInfo? = null,
    val metadata: Map<String, JsonElement>? = null,
    val idempotencyKey: String,
    val captchaToken: String? = null,
)

@Serializable
private data class FollowUpGeneratePayload(
    val locale: String? = null,
)

@Serializable
private data class SaveFollowUpPayload(
    val answers: List<FollowUpSubmissionAnswer>,
)

@Serializable
private data class LatestReplyPayload(
    val latestReplyAt: String? = null,
)

@Serializable
private data class ApiErrorPayload(
    val error: String,
)
