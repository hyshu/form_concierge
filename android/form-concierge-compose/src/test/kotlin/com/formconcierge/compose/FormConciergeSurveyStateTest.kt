package com.formconcierge.compose

import androidx.compose.runtime.AbstractApplier
import androidx.compose.runtime.Composition
import androidx.compose.runtime.MonotonicFrameClock
import androidx.compose.runtime.Recomposer
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.snapshots.Snapshot
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonElement
import org.junit.Test
import kotlin.test.assertSame
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class FormConciergeSurveyStateTest {
    @Test
    fun `anonymous token update does not recreate controller`() =
        runTest {
            val recomposer = Recomposer(coroutineContext)
            val composition = Composition(EmptyApplier(), recomposer)
            val client = FakeApi()
            val config = FormConciergeSurveyConfig(projectSlug = "project", surveySlug = "survey")
            val anonymousToken = mutableStateOf<String?>(null)
            val controllerScope = CoroutineScope(coroutineContext)
            var observedController: SurveyController? = null
            var compositionCount = 0
            val recomposerJob =
                launch(ImmediateFrameClock) {
                    recomposer.runRecomposeAndApplyChanges()
                }

            composition.setContent {
                compositionCount += 1
                val currentToken = anonymousToken.value
                observedController =
                    rememberSurveyController(
                        client = client,
                        config = config,
                        fallbackDeviceInfo = DeviceInfo(),
                        onAnonymousSession = { check(currentToken != "unexpected") },
                        onResponseSubmitted = {},
                        onFollowUpSubmitted = {},
                        scope = controllerScope,
                    )
            }
            recomposer.awaitIdle()
            val initialController = checkNotNull(observedController)

            anonymousToken.value = "new-token"
            Snapshot.sendApplyNotifications()
            runCurrent()
            recomposer.awaitIdle()

            assertSame(initialController, observedController)
            assertTrue(compositionCount >= 2)
            composition.dispose()
            recomposer.cancel()
            recomposerJob.join()
        }

    private object ImmediateFrameClock : MonotonicFrameClock {
        override suspend fun <R> withFrameNanos(onFrame: (Long) -> R): R = onFrame(System.nanoTime())
    }

    private class FakeApi : FormConciergeApi {
        override fun setAnonymousToken(token: String?) = Unit

        override fun hasAnonymousToken(): Boolean = false

        override suspend fun createAnonymousAccount(displayName: String?): AnonymousSession = unused()

        override suspend fun project(slug: String): PublicProject = unused()

        override suspend fun publicConfig(): PublicConfig = unused()

        override suspend fun questions(surveyId: Int): List<Question> = unused()

        override suspend fun choices(questionId: Int): List<Choice> = unused()

        override suspend fun visibilityRules(surveyId: Int): List<QuestionVisibilityRule> = unused()

        override suspend fun submitResponse(
            surveyId: Int,
            answers: List<Answer>,
            deviceInfo: DeviceInfo?,
            metadata: Map<String, JsonElement>?,
            idempotencyKey: String,
            captchaToken: String?,
        ): SurveyResponse = unused()

        override suspend fun generateFollowUp(
            responseId: Int,
            locale: String?,
        ): FollowUpGenerateResult = unused()

        override suspend fun saveFollowUp(
            responseId: Int,
            answers: List<FollowUpSubmissionAnswer>,
        ): SurveyResponse = unused()

        override suspend fun uploadMedia(
            bytes: ByteArray,
            contentType: String,
        ): MediaUpload = unused()

        override suspend fun replies(responseId: Int?): List<AdminReply> = unused()

        override suspend fun latestReplyAt(responseId: Int?): String? = unused()

        private fun <T> unused(): T = error("Unexpected API call")
    }

    private class EmptyApplier : AbstractApplier<Unit>(Unit) {
        override fun insertTopDown(
            index: Int,
            instance: Unit,
        ) = Unit

        override fun insertBottomUp(
            index: Int,
            instance: Unit,
        ) = Unit

        override fun remove(
            index: Int,
            count: Int,
        ) = Unit

        override fun move(
            from: Int,
            to: Int,
            count: Int,
        ) = Unit

        override fun onClear() = Unit
    }
}
