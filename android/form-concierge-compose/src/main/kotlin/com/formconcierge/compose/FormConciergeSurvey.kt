@file:Suppress("ktlint:standard:function-naming")

package com.formconcierge.compose

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddPhotoAlternate
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.JsonElement

/**
 * Survey selection, locale, metadata, and host callbacks for the survey form.
 */
public data class FormConciergeSurveyConfig(
    /**
     * The URL-friendly name of the project to display.
     */
    public val projectSlug: String,
    /**
     * The optional URL-friendly name of the survey to display.
     */
    public val surveySlug: String? = null,
    /**
     * The identifier of the associated survey.
     */
    public val surveyId: Int? = null,
    /**
     * The locale used to display the form content.
     */
    public val locale: String? = null,
    /**
     * Optional device details attached to the submission.
     */
    public val deviceInfo: DeviceInfo? = null,
    /**
     * Application-provided metadata attached to the submission.
     */
    public val metadata: Map<String, JsonElement> = emptyMap(),
    /**
     * Obtains a CAPTCHA token before submission when the survey requires one.
     */
    public val captchaTokenProvider: (suspend () -> String?)? = null,
    /**
     * An optional transformation applied to each image before upload.
     */
    public val processImage: ProcessSurveyImage? = null,
)

/**
 * Loads and displays a survey with validation, image uploads, and adaptive follow-up
 * questions.
 */
@Composable
public fun FormConciergeSurvey(
    client: FormConciergeApi,
    config: FormConciergeSurveyConfig,
    modifier: Modifier = Modifier,
    anonymousToken: String? = null,
    onAnonymousSession: suspend (AnonymousSession) -> Unit = {},
    onResponseSubmitted: suspend (FormConciergeSubmission) -> Unit = {},
    onFollowUpSubmitted: suspend (SurveyResponse) -> Unit = {},
    onDone: (() -> Unit)? = null,
    footer: (@Composable () -> Unit)? = null,
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    val controller =
        rememberSurveyController(
            client = client,
            config = config,
            fallbackDeviceInfo = DeviceInfo.current(context),
            onAnonymousSession = onAnonymousSession,
            onResponseSubmitted = onResponseSubmitted,
            onFollowUpSubmitted = onFollowUpSubmitted,
            scope = coroutineScope,
        )
    val currentAnonymousToken by rememberUpdatedState(anonymousToken)
    LaunchedEffect(controller) {
        client.setAnonymousToken(currentAnonymousToken)
        controller.load()
    }
    LaunchedEffect(client, anonymousToken) {
        client.setAnonymousToken(anonymousToken)
    }

    Box(modifier.fillMaxSize()) {
        when (controller.phase) {
            SurveyPhase.Loading -> {
                LoadingContent(controller.locale)
            }

            SurveyPhase.Form -> {
                SurveyFormContent(controller, footer)
            }

            SurveyPhase.GeneratingFollowUp -> {
                LoadingContent(
                    controller.locale,
                    FormConciergeStrings.text(controller.locale, "followUpLoading"),
                )
            }

            SurveyPhase.FollowUp -> {
                FollowUpContent(controller)
            }

            SurveyPhase.Completed -> {
                CompletedContent(
                    locale = controller.locale,
                    title = controller.survey?.title(controller.locale).orEmpty(),
                    onDone = onDone,
                )
            }

            SurveyPhase.Error -> {
                SurveyErrorContent(
                    locale = controller.locale,
                    error = controller.errorMessage,
                    onRetry = { controller.scope.launch { controller.load() } },
                )
            }
        }
    }
}

@Composable
internal fun rememberSurveyController(
    client: FormConciergeApi,
    config: FormConciergeSurveyConfig,
    fallbackDeviceInfo: DeviceInfo,
    onAnonymousSession: suspend (AnonymousSession) -> Unit,
    onResponseSubmitted: suspend (FormConciergeSubmission) -> Unit,
    onFollowUpSubmitted: suspend (SurveyResponse) -> Unit,
    scope: kotlinx.coroutines.CoroutineScope,
): SurveyController {
    val currentOnAnonymousSession = rememberUpdatedState(onAnonymousSession)
    val currentOnResponseSubmitted = rememberUpdatedState(onResponseSubmitted)
    val currentOnFollowUpSubmitted = rememberUpdatedState(onFollowUpSubmitted)
    return remember(client, config) {
        SurveyController(
            client = client,
            config = config,
            fallbackDeviceInfo = fallbackDeviceInfo,
            onAnonymousSession = { currentOnAnonymousSession.value(it) },
            onResponseSubmitted = { currentOnResponseSubmitted.value(it) },
            onFollowUpSubmitted = { currentOnFollowUpSubmitted.value(it) },
            scope = scope,
        )
    }
}

@Composable
private fun LoadingContent(
    locale: String,
    label: String = FormConciergeStrings.text(locale, "loadingSurvey"),
) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        CircularProgressIndicator()
        Spacer(Modifier.height(16.dp))
        Text(label, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun SurveyErrorContent(
    locale: String,
    error: String?,
    onRetry: () -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            FormConciergeStrings.text(locale, "surveyUnavailable"),
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            error ?: FormConciergeStrings.text(locale, "tryAgainLater"),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(20.dp))
        OutlinedButton(onClick = onRetry) {
            Text(FormConciergeStrings.text(locale, "retry"))
        }
    }
}

@Composable
private fun SurveyFormContent(
    controller: SurveyController,
    footer: (@Composable () -> Unit)?,
) {
    val survey = controller.survey ?: return
    val visibleQuestions = controller.visibleQuestions
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding =
            androidx.compose.foundation.layout
                .PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        item {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    survey.title(controller.locale),
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                )
                survey.description(controller.locale).takeIf(String::isNotBlank)?.let {
                    Text(it, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
        items(visibleQuestions, key = Question::id) { question ->
            QuestionEditor(
                client = controller.client,
                question = question,
                choices = controller.choicesByQuestion[question.id].orEmpty(),
                answer = controller.answers[question.id],
                locale = controller.locale,
                isEnabled = !controller.isSubmitting,
                ensureAuthenticated = controller::ensureAuthenticated,
                processImage = controller.config.processImage,
                imagePreviews = controller.imagePreviews,
                onAnswer = { controller.updateAnswer(question.id, it) },
            )
        }
        controller.errorMessage?.let { error ->
            item {
                Text(
                    error,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodyMedium,
                )
            }
        }
        item {
            Button(
                onClick = { controller.scope.launch { controller.submit() } },
                enabled = !controller.isSubmitting,
                modifier = Modifier.fillMaxWidth().height(52.dp),
            ) {
                if (controller.isSubmitting) {
                    CircularProgressIndicator(
                        modifier = Modifier.width(22.dp).height(22.dp),
                        strokeWidth = 2.dp,
                    )
                    Spacer(Modifier.width(10.dp))
                }
                Text(
                    FormConciergeStrings.text(
                        controller.locale,
                        if (controller.isSubmitting) "submitting" else "submit",
                    ),
                )
            }
        }
        footer?.let { content -> item { content() } }
    }
}

@Composable
private fun QuestionEditor(
    client: FormConciergeApi,
    question: Question,
    choices: List<Choice>,
    answer: SurveyAnswerValue?,
    locale: String,
    isEnabled: Boolean,
    ensureAuthenticated: suspend () -> Unit,
    processImage: ProcessSurveyImage?,
    imagePreviews: MutableMap<String, ByteArray>,
    onAnswer: (SurveyAnswerValue) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                question.text(locale),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.weight(1f),
            )
            if (question.isRequired) {
                Text(" *", color = MaterialTheme.colorScheme.error)
            }
        }
        when (question.type) {
            QuestionType.TextSingle,
            QuestionType.TextMultiLine,
            -> {
                OutlinedTextField(
                    value = (answer as? SurveyAnswerValue.Text)?.value.orEmpty(),
                    onValueChange = { onAnswer(SurveyAnswerValue.Text(it)) },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = isEnabled,
                    placeholder = {
                        question.placeholder(locale).takeIf(String::isNotBlank)?.let { Text(it) }
                    },
                    minLines = if (question.type == QuestionType.TextMultiLine) 5 else 1,
                    maxLines = if (question.type == QuestionType.TextMultiLine) 10 else 1,
                    keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences),
                )
            }

            QuestionType.SingleChoice -> {
                choices.forEach { choice ->
                    val selected = (answer as? SurveyAnswerValue.Single)?.choiceId == choice.id
                    Row(
                        modifier =
                            Modifier
                                .fillMaxWidth()
                                .clickable(enabled = isEnabled) { onAnswer(SurveyAnswerValue.Single(choice.id)) }
                                .padding(vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        RadioButton(
                            selected = selected,
                            onClick = null,
                            enabled = isEnabled,
                        )
                        Text(choice.text(locale))
                    }
                }
            }

            QuestionType.MultipleChoice -> {
                val selected = (answer as? SurveyAnswerValue.Multiple)?.choiceIds.orEmpty()
                val reachedMax = question.maxSelected?.let { selected.size >= it } == true
                choices.forEach { choice ->
                    val checked = choice.id in selected
                    val canToggle = isEnabled && (checked || !reachedMax)
                    Row(
                        modifier =
                            Modifier
                                .fillMaxWidth()
                                .clickable(enabled = canToggle) {
                                    val next =
                                        selected.toMutableSet().apply {
                                            if (!add(choice.id)) remove(choice.id)
                                        }
                                    onAnswer(SurveyAnswerValue.Multiple(next))
                                }.padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Checkbox(checked = checked, onCheckedChange = null, enabled = canToggle)
                        Text(choice.text(locale))
                    }
                }
            }

            QuestionType.ImageUpload -> {
                ImageUploadEditor(
                    client = client,
                    fileKeys = (answer as? SurveyAnswerValue.Images)?.fileKeys.orEmpty(),
                    maxFiles = question.maxSelected ?: 3,
                    locale = locale,
                    isEnabled = isEnabled,
                    ensureAuthenticated = ensureAuthenticated,
                    processImage = processImage,
                    imagePreviews = imagePreviews,
                    onChange = { onAnswer(SurveyAnswerValue.Images(it)) },
                )
            }
        }
    }
}

@Composable
private fun ImageUploadEditor(
    client: FormConciergeApi,
    fileKeys: List<String>,
    maxFiles: Int,
    locale: String,
    isEnabled: Boolean,
    ensureAuthenticated: suspend () -> Unit,
    processImage: ProcessSurveyImage?,
    imagePreviews: MutableMap<String, ByteArray>,
    onChange: (List<String>) -> Unit,
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var uploading by remember { mutableStateOf(false) }
    var localError by remember { mutableStateOf<String?>(null) }
    val launcher =
        rememberLauncherForActivityResult(ActivityResultContracts.GetMultipleContents()) { uris ->
            if (uris.isEmpty()) return@rememberLauncherForActivityResult
            scope.launch {
                uploading = true
                localError = null
                try {
                    ensureAuthenticated()
                    uploadSurveyImages(
                        sources = uris,
                        existingFileKeys = fileKeys,
                        maxFiles = maxFiles,
                        loadImage = { context.imagePayload(it) },
                        processImage = processImage,
                        uploadImage = { client.uploadMedia(it.bytes, it.contentType).key },
                        onUploaded = { keys, payload ->
                            imagePreviews[keys.last()] = payload.bytes
                            onChange(keys)
                        },
                    )
                } catch (cancelled: CancellationException) {
                    throw cancelled
                } catch (_: Throwable) {
                    localError = FormConciergeStrings.text(locale, "photoUploadFailed")
                } finally {
                    uploading = false
                }
            }
        }

    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        fileKeys.forEachIndexed { index, key ->
            Card(modifier = Modifier.fillMaxWidth()) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(start = 14.dp, top = 8.dp, bottom = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    androidx.compose.runtime.key(key) {
                        ImageUploadPreview(imagePreviews[key])
                    }
                    Spacer(Modifier.width(10.dp))
                    Text(
                        "${index + 1} / $maxFiles",
                        modifier = Modifier.weight(1f),
                        style = MaterialTheme.typography.bodyMedium,
                    )
                    IconButton(
                        onClick = {
                            imagePreviews.remove(key)
                            onChange(fileKeys.filterNot { it == key })
                        },
                        enabled = isEnabled && !uploading,
                    ) {
                        Icon(
                            Icons.Default.Close,
                            contentDescription = FormConciergeStrings.text(locale, "removePhoto"),
                        )
                    }
                }
            }
        }
        Text(
            FormConciergeStrings.text(locale, "maxPhotosReached", "count" to maxFiles),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        OutlinedButton(
            onClick = { launcher.launch("image/*") },
            enabled = isEnabled && !uploading && fileKeys.size < maxFiles,
        ) {
            Icon(Icons.Default.AddPhotoAlternate, contentDescription = null)
            Spacer(Modifier.width(8.dp))
            Text(
                FormConciergeStrings.text(
                    locale,
                    if (uploading) "uploadingPhotos" else "addPhotos",
                ),
            )
        }
        localError?.let {
            Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
        }
    }
}

@Composable
private fun ImageUploadPreview(bytes: ByteArray?) {
    val preview by produceState<ImageBitmap?>(initialValue = null, bytes) {
        value =
            if (bytes == null) {
                null
            } else {
                withContext(Dispatchers.IO) {
                    try {
                        decodeSurveyImagePreview(bytes)?.asImageBitmap()
                    } catch (cancelled: CancellationException) {
                        throw cancelled
                    } catch (_: Exception) {
                        null
                    }
                }
            }
    }
    val bitmap = preview
    val modifier = Modifier.size(64.dp).clip(RoundedCornerShape(8.dp))
    if (bitmap == null) {
        Box(modifier, contentAlignment = Alignment.Center) {
            Icon(Icons.Default.AddPhotoAlternate, contentDescription = null)
        }
    } else {
        Image(
            bitmap = bitmap,
            contentDescription = null,
            modifier = modifier,
            contentScale = ContentScale.Crop,
        )
    }
}

@Composable
private fun FollowUpContent(controller: SurveyController) {
    val followUp = controller.followUp ?: return
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding =
            androidx.compose.foundation.layout
                .PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        item {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    FormConciergeStrings.text(controller.locale, "followUpTitle"),
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    FormConciergeStrings.text(controller.locale, "followUpSubtitle"),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        items(followUp.items, key = FollowUpItem::id) { item ->
            FollowUpEditor(
                client = controller.client,
                item = item,
                answer = controller.followUpAnswers[item.id],
                locale = controller.locale,
                enabled = !controller.isSubmitting,
                ensureAuthenticated = controller::ensureAuthenticated,
                processImage = controller.config.processImage,
                imagePreviews = controller.imagePreviews,
                onAnswer = { controller.updateFollowUpAnswer(item.id, it) },
            )
        }
        controller.errorMessage?.let { error ->
            item { Text(error, color = MaterialTheme.colorScheme.error) }
        }
        item {
            Button(
                onClick = { controller.scope.launch { controller.submitFollowUp() } },
                enabled = !controller.isSubmitting,
                modifier = Modifier.fillMaxWidth().height(52.dp),
            ) {
                if (controller.isSubmitting) {
                    CircularProgressIndicator(
                        modifier = Modifier.width(22.dp).height(22.dp),
                        strokeWidth = 2.dp,
                    )
                    Spacer(Modifier.width(10.dp))
                }
                Text(
                    FormConciergeStrings.text(
                        controller.locale,
                        if (controller.isSubmitting) "followUpSubmitting" else "followUpContinue",
                    ),
                )
            }
        }
    }
}

@Composable
private fun FollowUpEditor(
    client: FormConciergeApi,
    item: FollowUpItem,
    answer: FollowUpAnswerValue?,
    locale: String,
    enabled: Boolean,
    ensureAuthenticated: suspend () -> Unit,
    processImage: ProcessSurveyImage?,
    imagePreviews: MutableMap<String, ByteArray>,
    onAnswer: (FollowUpAnswerValue) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(item.text, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        when (item.type) {
            QuestionType.TextSingle,
            QuestionType.TextMultiLine,
            -> {
                OutlinedTextField(
                    value = (answer as? FollowUpAnswerValue.Text)?.value.orEmpty(),
                    onValueChange = { onAnswer(FollowUpAnswerValue.Text(it)) },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { item.placeholder?.let { Text(it) } },
                    enabled = enabled,
                    minLines = if (item.type == QuestionType.TextMultiLine) 5 else 1,
                    maxLines = if (item.type == QuestionType.TextMultiLine) 10 else 1,
                )
            }

            QuestionType.SingleChoice -> {
                item.choices.forEach { choice ->
                    Row(
                        modifier =
                            Modifier
                                .fillMaxWidth()
                                .clickable(enabled) {
                                    onAnswer(FollowUpAnswerValue.Single(choice.id))
                                }.padding(vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        RadioButton(
                            selected = (answer as? FollowUpAnswerValue.Single)?.choiceId == choice.id,
                            onClick = null,
                            enabled = enabled,
                        )
                        Text(choice.label)
                    }
                }
            }

            QuestionType.MultipleChoice -> {
                val selected = (answer as? FollowUpAnswerValue.Multiple)?.choiceIds.orEmpty()
                item.choices.forEach { choice ->
                    Row(
                        modifier =
                            Modifier
                                .fillMaxWidth()
                                .clickable(enabled) {
                                    val next =
                                        selected.toMutableSet().apply {
                                            if (!add(choice.id)) remove(choice.id)
                                        }
                                    onAnswer(FollowUpAnswerValue.Multiple(next))
                                }.padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Checkbox(choice.id in selected, onCheckedChange = null, enabled = enabled)
                        Text(choice.label)
                    }
                }
            }

            QuestionType.ImageUpload -> {
                ImageUploadEditor(
                    client = client,
                    fileKeys = (answer as? FollowUpAnswerValue.Images)?.fileKeys.orEmpty(),
                    maxFiles = item.maxFiles ?: 1,
                    locale = locale,
                    isEnabled = enabled,
                    ensureAuthenticated = ensureAuthenticated,
                    processImage = processImage,
                    imagePreviews = imagePreviews,
                    onChange = { onAnswer(FollowUpAnswerValue.Images(it)) },
                )
            }
        }
    }
}

@Composable
private fun CompletedContent(
    locale: String,
    title: String,
    onDone: (() -> Unit)?,
) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Icon(
            Icons.Default.CheckCircle,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
        )
        Spacer(Modifier.height(14.dp))
        Text(
            FormConciergeStrings.text(locale, "thankYou"),
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            FormConciergeStrings.text(locale, "submittedWithTitle", "title" to title),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        onDone?.let {
            Spacer(Modifier.height(20.dp))
            Button(onClick = it) { Text(FormConciergeStrings.text(locale, "done")) }
        }
    }
}

internal class SurveyController(
    val client: FormConciergeApi,
    val config: FormConciergeSurveyConfig,
    private val fallbackDeviceInfo: DeviceInfo,
    private val onAnonymousSession: suspend (AnonymousSession) -> Unit,
    private val onResponseSubmitted: suspend (FormConciergeSubmission) -> Unit,
    private val onFollowUpSubmitted: suspend (SurveyResponse) -> Unit,
    val scope: kotlinx.coroutines.CoroutineScope,
) {
    var phase by mutableStateOf(SurveyPhase.Loading)
    var survey by mutableStateOf<Survey?>(null)
    var project by mutableStateOf<Project?>(null)
    var questions by mutableStateOf<List<Question>>(emptyList())
    var visibilityRules by mutableStateOf<List<QuestionVisibilityRule>>(emptyList())
    var choicesByQuestion by mutableStateOf<Map<Int, List<Choice>>>(emptyMap())
    val answers = mutableStateMapOf<Int, SurveyAnswerValue>()
    val followUpAnswers = mutableStateMapOf<String, FollowUpAnswerValue>()
    val imagePreviews = mutableStateMapOf<String, ByteArray>()
    var followUp by mutableStateOf<FollowUp?>(null)
    var submittedResponse by mutableStateOf<SurveyResponse?>(null)
    var errorMessage by mutableStateOf<String?>(null)
    var isSubmitting by mutableStateOf(false)

    val locale: String
        get() = normalizeFormContentLocale(config.locale ?: project?.defaultLocale ?: "en")

    val visibleQuestions: List<Question>
        get() = FormConciergeSurveyLogic.visibleQuestions(questions, visibilityRules, answers)

    suspend fun load() {
        phase = SurveyPhase.Loading
        errorMessage = null
        try {
            val loadedProject = client.project(config.projectSlug)
            val loadedSurvey =
                when {
                    config.surveySlug != null -> {
                        loadedProject.surveys.firstOrNull {
                            it.slug == config.surveySlug
                        }
                    }

                    config.surveyId != null -> {
                        loadedProject.surveys.firstOrNull {
                            it.id == config.surveyId
                        }
                    }

                    loadedProject.surveys.size == 1 -> {
                        loadedProject.surveys.first()
                    }

                    else -> {
                        null
                    }
                } ?: error("Survey not found")
            val loadedQuestions = client.questions(loadedSurvey.id).sortedBy(Question::orderIndex)
            val loadedChoices =
                loadedQuestions
                    .filter { it.type == QuestionType.SingleChoice || it.type == QuestionType.MultipleChoice }
                    .associate { question ->
                        question.id to client.choices(question.id).sortedBy(Choice::orderIndex)
                    }
            project = loadedProject.project
            survey = loadedSurvey
            questions = loadedQuestions
            visibilityRules = client.visibilityRules(loadedSurvey.id)
            choicesByQuestion = loadedChoices
            answers.clear()
            imagePreviews.clear()
            phase = SurveyPhase.Form
        } catch (error: Throwable) {
            errorMessage = error.message
            phase = SurveyPhase.Error
        }
    }

    fun updateAnswer(
        questionId: Int,
        answer: SurveyAnswerValue,
    ) {
        answers[questionId] = answer
        val visibleIds =
            FormConciergeSurveyLogic
                .visibleQuestions(questions, visibilityRules, answers)
                .mapTo(mutableSetOf(), Question::id)
        answers.keys
            .toList()
            .filterNot(visibleIds::contains)
            .forEach(answers::remove)
        discardUnusedImagePreviews()
    }

    fun updateFollowUpAnswer(
        itemId: String,
        answer: FollowUpAnswerValue,
    ) {
        followUpAnswers[itemId] = answer
        discardUnusedImagePreviews()
    }

    private fun discardUnusedImagePreviews() {
        val referencedKeys =
            when (phase) {
                SurveyPhase.Form -> {
                    answers.values.filterIsInstance<SurveyAnswerValue.Images>().flatMap { it.fileKeys }
                }

                SurveyPhase.FollowUp -> {
                    followUp
                        ?.items
                        .orEmpty()
                        .mapNotNull { followUpAnswers[it.id] as? FollowUpAnswerValue.Images }
                        .flatMap { it.fileKeys }
                }

                else -> {
                    emptyList()
                }
            }.toSet()
        imagePreviews.keys
            .toList()
            .filterNot(referencedKeys::contains)
            .forEach(imagePreviews::remove)
    }

    suspend fun ensureAuthenticated() {
        if (client.hasAnonymousToken()) return
        val session = client.createAnonymousAccount()
        onAnonymousSession(session)
    }

    suspend fun submit() {
        val loadedSurvey = survey ?: return
        errorMessage = FormConciergeSurveyLogic.validationError(visibleQuestions, answers, locale)
        if (errorMessage != null) return
        isSubmitting = true
        try {
            ensureAuthenticated()
            val captchaToken =
                if (loadedSurvey.captchaRequired) {
                    config.captchaTokenProvider?.invoke()?.takeIf(String::isNotBlank)
                        ?: run {
                            errorMessage = FormConciergeStrings.text(locale, "captchaRequired")
                            return
                        }
                } else {
                    null
                }
            val visible = visibleQuestions
            val payload = FormConciergeSurveyLogic.answerPayload(visible, answers)
            val idempotencyKey =
                java.util.UUID
                    .randomUUID()
                    .toString()
                    .lowercase()
            val response =
                try {
                    submitResponse(loadedSurvey, payload, idempotencyKey, captchaToken)
                } catch (error: FormConciergeException.Api) {
                    if (error.statusCode != 401) throw error
                    client.setAnonymousToken(null)
                    val session = client.createAnonymousAccount()
                    onAnonymousSession(session)
                    submitResponse(loadedSurvey, payload, idempotencyKey, captchaToken)
                }
            submittedResponse = response
            onResponseSubmitted(
                FormConciergeSubmission(
                    response = response,
                    answers = payload,
                    questions = visible,
                    choicesByQuestion = choicesByQuestion,
                    locale = locale,
                ),
            )
            if (loadedSurvey.followUpEnabled) {
                startFollowUp(response.id)
            } else {
                phase = SurveyPhase.Completed
                discardUnusedImagePreviews()
            }
        } catch (error: Throwable) {
            errorMessage = error.message ?: FormConciergeStrings.text(locale, "tryAgainLater")
        } finally {
            isSubmitting = false
        }
    }

    private suspend fun submitResponse(
        survey: Survey,
        payload: List<Answer>,
        idempotencyKey: String,
        captchaToken: String?,
    ): SurveyResponse =
        client.submitResponse(
            surveyId = survey.id,
            answers = payload,
            deviceInfo = config.deviceInfo ?: fallbackDeviceInfo,
            metadata = config.metadata.takeIf(Map<String, JsonElement>::isNotEmpty),
            idempotencyKey = idempotencyKey,
            captchaToken = captchaToken,
        )

    private suspend fun startFollowUp(responseId: Int) {
        phase = SurveyPhase.GeneratingFollowUp
        discardUnusedImagePreviews()
        try {
            val result = client.generateFollowUp(responseId, locale)
            if (result.needed && result.followUp.status == FollowUpStatus.Pending &&
                result.followUp.items.isNotEmpty()
            ) {
                followUp = result.followUp
                followUpAnswers.clear()
                phase = SurveyPhase.FollowUp
            } else {
                phase = SurveyPhase.Completed
            }
        } catch (_: Throwable) {
            phase = SurveyPhase.Completed
        }
    }

    suspend fun submitFollowUp() {
        val responseId = submittedResponse?.id ?: return
        val loadedFollowUp = followUp ?: return
        isSubmitting = true
        errorMessage = null
        try {
            val payload =
                loadedFollowUp.items.map { item ->
                    when (val answer = followUpAnswers[item.id]) {
                        is FollowUpAnswerValue.Text -> {
                            FollowUpSubmissionAnswer(
                                id = item.id,
                                textValue = answer.value.trim(),
                            )
                        }

                        is FollowUpAnswerValue.Single -> {
                            FollowUpSubmissionAnswer(
                                id = item.id,
                                selectedChoiceIds = listOf(answer.choiceId),
                            )
                        }

                        is FollowUpAnswerValue.Multiple -> {
                            FollowUpSubmissionAnswer(
                                id = item.id,
                                selectedChoiceIds = answer.choiceIds.sorted(),
                            )
                        }

                        is FollowUpAnswerValue.Images -> {
                            FollowUpSubmissionAnswer(
                                id = item.id,
                                fileKeys = answer.fileKeys,
                            )
                        }

                        null -> {
                            FollowUpSubmissionAnswer(id = item.id)
                        }
                    }
                }
            val response = client.saveFollowUp(responseId, payload)
            submittedResponse = response
            followUp = null
            onFollowUpSubmitted(response)
            phase = SurveyPhase.Completed
            discardUnusedImagePreviews()
        } catch (error: Throwable) {
            errorMessage = error.message ?: FormConciergeStrings.text(locale, "tryAgainLater")
        } finally {
            isSubmitting = false
        }
    }
}

internal enum class SurveyPhase {
    Loading,
    Form,
    GeneratingFollowUp,
    FollowUp,
    Completed,
    Error,
}

internal sealed interface FollowUpAnswerValue {
    data class Text(
        val value: String,
    ) : FollowUpAnswerValue

    data class Single(
        val choiceId: String,
    ) : FollowUpAnswerValue

    data class Multiple(
        val choiceIds: Set<String>,
    ) : FollowUpAnswerValue

    data class Images(
        val fileKeys: List<String>,
    ) : FollowUpAnswerValue
}

private suspend fun android.content.Context.imagePayload(uri: Uri): SurveyImagePayload? =
    withContext(Dispatchers.IO) {
        val contentType = contentResolver.getType(uri) ?: "application/octet-stream"
        val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() } ?: return@withContext null
        SurveyImagePayload(bytes, contentType)
    }
