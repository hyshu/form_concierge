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

/**
 * The input format used to collect a question's answer.
 */
@Serializable
public enum class QuestionType {
    /**
     * A question that accepts one selected choice.
     */
    @SerialName("singleChoice")
    SingleChoice,

    /**
     * A question that accepts several selected choices.
     */
    @SerialName("multipleChoice")
    MultipleChoice,

    /**
     * A question that accepts a single line of text.
     */
    @SerialName("textSingle")
    TextSingle,

    /**
     * A question that accepts multiple lines of text.
     */
    @SerialName("textMultiLine")
    TextMultiLine,

    /**
     * A question that accepts uploaded images.
     */
    @SerialName("imageUpload")
    ImageUpload,
}

/**
 * The publication state of a survey.
 */
@Serializable
public enum class SurveyStatus {
    /**
     * A survey that has not been published.
     */
    @SerialName("draft")
    Draft,

    /**
     * A published survey, subject to its availability schedule.
     */
    @SerialName("published")
    Published,

    /**
     * A survey that no longer accepts responses.
     */
    @SerialName("closed")
    Closed,

    /**
     * A survey retained for reference after active use.
     */
    @SerialName("archived")
    Archived,
}

/**
 * How multiple rules combine to control question visibility.
 */
@Serializable
public enum class VisibilityConditionMode {
    /**
     * Shows the question only when every rule matches.
     */
    @SerialName("all")
    All,

    /**
     * Shows the question when at least one rule matches.
     */
    @SerialName("any")
    Any,
}

/**
 * The comparison applied to a source question's answer.
 */
@Serializable
public enum class VisibilityOperator {
    /**
     * Matches equal text or a selected choice.
     */
    @SerialName("equals")
    Equals,

    /**
     * Matches different text or an unselected choice when an answer exists.
     */
    @SerialName("notEquals")
    NotEquals,

    /**
     * Matches text containing a substring or a selected choice.
     */
    @SerialName("contains")
    Contains,

    /**
     * Matches an answer that excludes the text or choice.
     */
    @SerialName("notContains")
    NotContains,

    /**
     * Matches a nonempty answer.
     */
    @SerialName("isAnswered")
    IsAnswered,

    /**
     * Matches a missing or empty answer.
     */
    @SerialName("isNotAnswered")
    IsNotAnswered,
}

/**
 * Locale codes supported by the built-in survey translations.
 */
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

/**
 * Normalizes locale separators and supported language aliases while preserving unrecognized
 * locale codes.
 */
public fun normalizeFormContentLocale(locale: String): String {
    val normalized = locale.replace('_', '-')
    if (normalized in formContentLocaleCodes) return normalized
    return when (normalized.lowercase(Locale.ROOT)) {
        "zh-hans", "zh-cn", "zh-sg" -> "zh-Hans"
        "zh-hant", "zh-tw", "zh-hk", "zh-mo" -> "zh-Hant"
        else -> normalized.substringBefore('-').takeIf { it in formContentLocaleCodes } ?: normalized
    }
}

/**
 * Text translations indexed by locale code.
 */
@Serializable(with = LocalizedTextSerializer::class)
public data class LocalizedText(
    /**
     * Translations indexed by locale code.
     */
    public val values: Map<String, String> = emptyMap(),
) {
    /**
     * Returns a translation for the locale, falling back to English, the first value, then an
     * empty string.
     */
    public fun value(locale: String): String =
        values[normalizeFormContentLocale(locale)]
            ?: values["en"]
            ?: values.values
                .firstOrNull()
                .orEmpty()
}

/**
 * Serializes localized text as a map from locale codes to strings.
 */
public object LocalizedTextSerializer : KSerializer<LocalizedText> {
    private val delegate = MapSerializer(String.serializer(), String.serializer())

    /**
     * The serialization structure of the locale-to-text map.
     */
    override val descriptor: SerialDescriptor = delegate.descriptor

    /**
     * Decodes a locale-to-text map into localized text.
     */
    override fun deserialize(decoder: Decoder): LocalizedText = LocalizedText(decoder.decodeSerializableValue(delegate))

    /**
     * Encodes the translations as a locale-to-text map.
     */
    override fun serialize(
        encoder: Encoder,
        value: LocalizedText,
    ) {
        encoder.encodeSerializableValue(delegate, value.values)
    }
}

/**
 * A group of surveys with shared locale and domain settings.
 */
@Serializable
public data class Project(
    /**
     * The identifier of this project.
     */
    public val id: Int,
    /**
     * The URL-friendly name used to look up this resource.
     */
    public val slug: String,
    /**
     * The custom host name assigned to the project, if any.
     */
    public val customDomain: String? = null,
    /**
     * The locale used when the respondent's preferred language is unavailable.
     */
    public val defaultLocale: String = "en",
    /**
     * The locale codes enabled for this project.
     */
    public val supportedLocales: List<String> = emptyList(),
    /**
     * The name displayed for the project.
     */
    public val name: String,
    /**
     * When this record was created.
     */
    public val createdAt: String,
    /**
     * When this record was last updated.
     */
    public val updatedAt: String,
)

/**
 * A public project and the surveys available to respondents.
 */
@Serializable
public data class PublicProject(
    /**
     * The project that contains the survey.
     */
    public val project: Project,
    /**
     * The surveys included in the project result.
     */
    public val surveys: List<Survey>,
)

/**
 * Public feature flags and CAPTCHA configuration for clients.
 */
@Serializable
public data class PublicConfig(
    /**
     * Whether the server advertises password reset support.
     */
    public val passwordResetEnabled: Boolean = false,
    /**
     * Whether administrator email verification is required.
     */
    public val requireEmailVerification: Boolean = false,
    /**
     * Whether AI-assisted content generation is available.
     */
    public val aiGenerationEnabled: Boolean = false,
    /**
     * The public Turnstile site key, or null when CAPTCHA is not configured.
     */
    public val turnstileSiteKey: String? = null,
)

/**
 * A form's localized content, availability, and submission settings.
 */
@Serializable
public data class Survey(
    /**
     * The identifier of this survey.
     */
    public val id: Int,
    /**
     * The identifier of the project containing the survey.
     */
    public val projectId: Int,
    /**
     * The URL-friendly name used to look up this resource.
     */
    public val slug: String,
    /**
     * Survey titles indexed by locale code.
     */
    public val titleTranslations: LocalizedText,
    /**
     * Survey descriptions indexed by locale code.
     */
    public val descriptionTranslations: LocalizedText = LocalizedText(),
    /**
     * The current publication state of the survey.
     */
    public val status: SurveyStatus,
    /**
     * Whether the survey is available through its public web page.
     */
    public val webEnabled: Boolean = true,
    /**
     * Whether submissions may receive an adaptive follow-up interview.
     */
    public val followUpEnabled: Boolean = false,
    /**
     * The configured CAPTCHA preference. Use captchaRequired for submission behavior.
     */
    @Deprecated("Use captchaRequired for submission behavior")
    public val captchaEnabled: Boolean = true,
    /**
     * Whether a CAPTCHA token is required when submitting this survey.
     */
    public val captchaRequired: Boolean = captchaEnabled,
    /**
     * When the survey begins accepting responses, if scheduled.
     */
    public val startsAt: String? = null,
    /**
     * When the survey stops accepting responses, if scheduled.
     */
    public val endsAt: String? = null,
    /**
     * When this record was created.
     */
    public val createdAt: String,
    /**
     * When this record was last updated.
     */
    public val updatedAt: String,
) {
    /**
     * Returns the survey title for the requested locale with translation fallback.
     */
    public fun title(locale: String): String = titleTranslations.value(locale)

    /**
     * Returns the survey description for the requested locale with translation fallback.
     */
    public fun description(locale: String): String = descriptionTranslations.value(locale)
}

/**
 * A survey question with input constraints and visibility settings.
 */
@Serializable
public data class Question(
    /**
     * The identifier of this question.
     */
    public val id: Int,
    /**
     * The identifier of the associated survey.
     */
    public val surveyId: Int,
    /**
     * Display text indexed by locale code.
     */
    public val textTranslations: LocalizedText,
    /**
     * The input format used to collect the answer.
     */
    public val type: QuestionType,
    /**
     * The position of this item in its ordered question or choice list.
     */
    public val orderIndex: Int,
    /**
     * Whether the respondent must answer this question.
     */
    public val isRequired: Boolean,
    /**
     * Input hints indexed by locale code.
     */
    public val placeholderTranslations: LocalizedText = LocalizedText(),
    /**
     * The minimum accepted text length, or null when no minimum is set.
     */
    public val minLength: Int? = null,
    /**
     * The maximum accepted text length, or null when no maximum is set.
     */
    public val maxLength: Int? = null,
    /**
     * The minimum number of choices or uploaded files required, if set.
     */
    public val minSelected: Int? = null,
    /**
     * The maximum number of choices or uploaded files allowed, if set.
     */
    public val maxSelected: Int? = null,
    /**
     * Whether all visibility rules or any one rule must match.
     */
    public val visibilityConditionMode: VisibilityConditionMode = VisibilityConditionMode.All,
) {
    /**
     * Returns display text for the requested locale with translation fallback.
     */
    public fun text(locale: String): String = textTranslations.value(locale)

    /**
     * Returns the input hint for the requested locale with translation fallback.
     */
    public fun placeholder(locale: String): String = placeholderTranslations.value(locale)
}

/**
 * A condition on another answer that controls question visibility.
 */
@Serializable
public data class QuestionVisibilityRule(
    /**
     * The identifier of this question visibility rule.
     */
    public val id: Int,
    /**
     * The identifier of the associated survey.
     */
    public val surveyId: Int,
    /**
     * The identifier of the question whose visibility is controlled.
     */
    public val targetQuestionId: Int,
    /**
     * The identifier of the question whose answer is tested.
     */
    public val sourceQuestionId: Int,
    /**
     * The comparison applied to the source answer.
     */
    public val operator: VisibilityOperator,
    /**
     * The text or choice identifier to compare with the source answer.
     */
    public val value: JsonElement? = null,
    /**
     * When this record was created.
     */
    public val createdAt: String? = null,
    /**
     * When this record was last updated.
     */
    public val updatedAt: String? = null,
)

/**
 * A localized answer option belonging to a choice question.
 */
@Serializable
public data class Choice(
    /**
     * The identifier of this choice.
     */
    public val id: Int,
    /**
     * The identifier of the associated question.
     */
    public val questionId: Int,
    /**
     * Display text indexed by locale code.
     */
    public val textTranslations: LocalizedText,
    /**
     * The position of this item in its ordered question or choice list.
     */
    public val orderIndex: Int,
    /**
     * An optional application-defined value for this choice.
     */
    public val value: String? = null,
) {
    /**
     * Returns display text for the requested locale with translation fallback.
     */
    public fun text(locale: String): String = textTranslations.value(locale)
}

/**
 * A submitted answer to one survey question.
 */
@Serializable
public data class Answer(
    /**
     * The identifier of the associated survey response.
     */
    public val surveyResponseId: Int = 0,
    /**
     * The identifier of the associated question.
     */
    public val questionId: Int,
    /**
     * The submitted text for a text question, when present.
     */
    public val textValue: String? = null,
    /**
     * The identifiers of the selected answer choices.
     */
    public val selectedChoiceIds: List<Int>? = null,
    /**
     * Storage keys for the uploaded files attached to the answer.
     */
    public val fileKeys: List<String>? = null,
)

/**
 * The storage key and metadata of an uploaded file.
 */
@Serializable
public data class MediaUpload(
    /**
     * The storage key used to retrieve the uploaded file.
     */
    public val key: String,
    /**
     * The MIME type of the content.
     */
    public val contentType: String,
    /**
     * The size of the uploaded file in bytes.
     */
    public val size: Int,
)

/**
 * The progress of an adaptive follow-up interview.
 */
@Serializable
public enum class FollowUpStatus {
    /**
     * No follow-up interview is required.
     */
    @SerialName("skipped")
    Skipped,

    /**
     * The follow-up interview is waiting for answers.
     */
    @SerialName("pending")
    Pending,

    /**
     * The follow-up answers have been saved.
     */
    @SerialName("completed")
    Completed,
}

/**
 * A selectable option in a follow-up question.
 */
@Serializable
public data class FollowUpChoice(
    /**
     * The identifier of this follow up choice.
     */
    public val id: String,
    /**
     * A human-readable label.
     */
    public val label: String,
)

/**
 * An answer to an adaptive follow-up question.
 */
@Serializable
public data class FollowUpAnswer(
    /**
     * The submitted text for a text question, when present.
     */
    public val textValue: String? = null,
    /**
     * The identifiers of the selected answer choices.
     */
    public val selectedChoiceIds: List<String> = emptyList(),
    /**
     * Storage keys for the uploaded files attached to the answer.
     */
    public val fileKeys: List<String> = emptyList(),
)

/**
 * An answer payload for one adaptive follow-up item.
 */
@Serializable
public data class FollowUpSubmissionAnswer(
    /**
     * The identifier of this follow up submission answer.
     */
    public val id: String,
    /**
     * The submitted text for a text question, when present.
     */
    public val textValue: String? = null,
    /**
     * The identifiers of the selected answer choices.
     */
    public val selectedChoiceIds: List<String> = emptyList(),
    /**
     * Storage keys for the uploaded files attached to the answer.
     */
    public val fileKeys: List<String> = emptyList(),
)

/**
 * A follow-up question with its choices and any saved answer.
 */
@Serializable
public data class FollowUpItem(
    /**
     * The identifier of this follow up item.
     */
    public val id: String,
    /**
     * The input format used to collect the answer.
     */
    public val type: QuestionType,
    /**
     * The question text shown to the respondent.
     */
    public val text: String,
    /**
     * Whether the respondent must answer this question.
     */
    public val required: Boolean = false,
    /**
     * Hint text displayed when the text input is empty.
     */
    public val placeholder: String? = null,
    /**
     * The maximum number of files allowed for this question.
     */
    public val maxFiles: Int? = null,
    /**
     * The choices available for this question.
     */
    public val choices: List<FollowUpChoice> = emptyList(),
    /**
     * The saved answer, if the follow-up question has been answered.
     */
    public val answer: FollowUpAnswer? = null,
)

/**
 * An adaptive interview generated from a submitted survey response.
 */
@Serializable
public data class FollowUp(
    /**
     * The version associated with this record.
     */
    public val version: Int,
    /**
     * The current progress of the follow-up interview.
     */
    public val status: FollowUpStatus,
    /**
     * When the follow-up interview was generated.
     */
    public val generatedAt: String,
    /**
     * When the follow-up interview was completed, if applicable.
     */
    public val completedAt: String? = null,
    /**
     * The locale used to display the form content.
     */
    public val locale: String,
    /**
     * The questions in the follow-up interview.
     */
    public val items: List<FollowUpItem>,
)

/**
 * The outcome of requesting an adaptive follow-up interview.
 */
@Serializable
public data class FollowUpGenerateResult(
    /**
     * Whether the generated follow-up requires additional answers.
     */
    public val needed: Boolean,
    /**
     * The adaptive follow-up interview associated with the response.
     */
    public val followUp: FollowUp,
    /**
     * The error message, when the operation could not complete.
     */
    public val error: String? = null,
)

/**
 * A recorded survey submission and its associated metadata.
 */
@Serializable
public data class SurveyResponse(
    /**
     * The identifier of this survey response.
     */
    public val id: Int,
    /**
     * The identifier of the associated survey.
     */
    public val surveyId: Int,
    /**
     * An optional respondent identifier supplied by the host application.
     */
    public val anonymousId: String? = null,
    /**
     * The anonymous account that owns the response or reply.
     */
    public val anonymousAccountId: String? = null,
    /**
     * When the survey response was submitted.
     */
    public val submittedAt: String,
    /**
     * Optional device details attached to the submission.
     */
    public val deviceInfo: DeviceInfo? = null,
    /**
     * Application-provided metadata attached to the submission.
     */
    public val metadata: Map<String, JsonElement>? = null,
    /**
     * The adaptive follow-up interview associated with the response.
     */
    public val followUp: FollowUp? = null,
    /**
     * The number of administrator replies attached to the response.
     */
    public val replyCount: Int = 0,
)

/**
 * An anonymous respondent identity used to own submissions and receive replies.
 */
@Serializable
public data class AnonymousAccount(
    /**
     * The identifier of this anonymous account.
     */
    public val id: String,
    /**
     * The optional display name attached to the anonymous account.
     */
    public val displayName: String? = null,
    /**
     * When this record was created.
     */
    public val createdAt: String,
    /**
     * When the anonymous account was last active.
     */
    public val lastSeenAt: String,
)

/**
 * An anonymous account and the bearer token used to access it.
 */
@Serializable
public data class AnonymousSession(
    /**
     * The anonymous account associated with the current session, if known.
     */
    public val account: AnonymousAccount,
    /**
     * The bearer token used to authenticate requests.
     */
    public val token: String,
)

/**
 * An administrator's message to the owner of a survey response.
 */
@Serializable
public data class AdminReply(
    /**
     * The identifier of this admin reply.
     */
    public val id: Int,
    /**
     * The identifier of the associated survey response.
     */
    public val surveyResponseId: Int,
    /**
     * The anonymous account that owns the response or reply.
     */
    public val anonymousAccountId: String,
    /**
     * The identifier of the administrator who wrote the reply, if available.
     */
    public val adminId: String? = null,
    /**
     * The reply text sent to the respondent.
     */
    public val body: String,
    /**
     * When this record was created.
     */
    public val createdAt: String,
    /**
     * When the reply was marked as read, if available.
     */
    public val readAt: String? = null,
)

/**
 * Optional device and application details attached to a survey response.
 */
@Serializable
public data class DeviceInfo(
    /**
     * An application-provided identifier for the device.
     */
    public val deviceId: String? = null,
    /**
     * A human-readable label.
     */
    public val label: String? = null,
    /**
     * The platform on which the respondent is running the form.
     */
    public val platform: String? = null,
    /**
     * The name of the operating system.
     */
    public val os: String? = null,
    /**
     * The version of the operating system.
     */
    public val osVersion: String? = null,
    /**
     * The browser name, when available.
     */
    public val browser: String? = null,
    /**
     * The browser version, when available.
     */
    public val browserVersion: String? = null,
    /**
     * The application's public version string.
     */
    public val appVersion: String? = null,
    /**
     * The application's build identifier.
     */
    public val appBuild: String? = null,
    /**
     * The hardware model reported by the device.
     */
    public val model: String? = null,
    /**
     * The hardware manufacturer reported by the device.
     */
    public val manufacturer: String? = null,
    /**
     * The locale reported by the respondent's device.
     */
    public val locale: String? = null,
    /**
     * The device's time zone identifier.
     */
    public val timezone: String? = null,
    /**
     * The screen width reported by the host platform.
     */
    public val screenWidth: Int? = null,
    /**
     * The screen height reported by the host platform.
     */
    public val screenHeight: Int? = null,
    /**
     * The number of physical pixels per logical screen pixel.
     */
    public val devicePixelRatio: Double? = null,
    /**
     * The user agent reported by the client, when available.
     */
    public val userAgent: String? = null,
) {
    /**
     * Factory helpers and shared values for DeviceInfo.
     */
    public companion object {
        /**
         * Collects available device, locale, and screen details from the current platform.
         */
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

/**
 * Image bytes and their MIME type prepared for upload.
 */
public data class SurveyImagePayload(
    /**
     * The file contents as raw bytes.
     */
    public val bytes: ByteArray,
    /**
     * The MIME type of the content.
     */
    public val contentType: String,
)

public typealias ProcessSurveyImage = suspend (SurveyImagePayload) -> SurveyImagePayload?

/**
 * An in-memory answer value used by the survey interface.
 */
public sealed interface SurveyAnswerValue {
    /**
     * A text answer entered by the respondent.
     */
    public data class Text(
        /**
         * The current value displayed by the input.
         */
        public val value: String,
    ) : SurveyAnswerValue

    /**
     * One selected choice identifier.
     */
    public data class Single(
        /**
         * The identifier of the selected choice.
         */
        public val choiceId: Int,
    ) : SurveyAnswerValue

    /**
     * A set of selected choice identifiers.
     */
    public data class Multiple(
        /**
         * The identifiers of the selected choices.
         */
        public val choiceIds: Set<Int>,
    ) : SurveyAnswerValue

    /**
     * Storage keys for uploaded images.
     */
    public data class Images(
        /**
         * Storage keys for the uploaded files attached to the answer.
         */
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

/**
 * A submitted response together with its questions, choices, answers, and locale.
 */
public data class FormConciergeSubmission(
    /**
     * The response returned by the server after submission.
     */
    public val response: SurveyResponse,
    /**
     * The answers sent with the submission.
     */
    public val answers: List<Answer>,
    /**
     * The survey questions in display order.
     */
    public val questions: List<Question>,
    /**
     * Available choices indexed by question identifier.
     */
    public val choicesByQuestion: Map<Int, List<Choice>>,
    /**
     * The locale used to display the form content.
     */
    public val locale: String,
)
