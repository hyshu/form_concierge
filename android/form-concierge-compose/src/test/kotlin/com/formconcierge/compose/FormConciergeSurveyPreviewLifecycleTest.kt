package com.formconcierge.compose

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Test
import java.io.IOException
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class FormConciergeSurveyPreviewLifecycleTest {
    @Test
    fun `hiding conditional image question releases its bytes and keeps visible attachment`() =
        runTest {
            val controller = controller(backgroundScope)
            controller.questions = listOf(question(1, QuestionType.TextSingle), question(2), question(3))
            controller.visibilityRules =
                listOf(QuestionVisibilityRule(1, 8, 2, 1, VisibilityOperator.Equals, JsonPrimitive("show")))
            controller.updateAnswer(1, SurveyAnswerValue.Text("show"))
            val visibleBytes = byteArrayOf(3)
            controller.imagePreviews["always-visible"] = visibleBytes
            controller.updateAnswer(3, SurveyAnswerValue.Images(listOf("always-visible")))

            repeat(3) { iteration ->
                controller.updateAnswer(1, SurveyAnswerValue.Text("show"))
                val conditionalKey = "conditional-$iteration"
                controller.imagePreviews[conditionalKey] = byteArrayOf(2)
                controller.updateAnswer(2, SurveyAnswerValue.Images(listOf(conditionalKey)))
                assertEquals(setOf("always-visible", conditionalKey), controller.imagePreviews.keys)

                controller.updateAnswer(1, SurveyAnswerValue.Text("hide"))
                assertNull(controller.answers[2])
                assertEquals(setOf("always-visible"), controller.imagePreviews.keys)
                assertSame(visibleBytes, controller.imagePreviews["always-visible"])
            }
        }

    @Test
    fun `updating attachment list releases removed files and retains remaining bytes`() =
        runTest {
            val controller = controller(backgroundScope)
            controller.imagePreviews["removed"] = byteArrayOf(1)
            val retainedBytes = byteArrayOf(2)
            controller.imagePreviews["retained"] = retainedBytes
            controller.updateAnswer(2, SurveyAnswerValue.Images(listOf("removed", "retained")))
            controller.updateAnswer(2, SurveyAnswerValue.Images(listOf("retained")))
            assertEquals(setOf("retained"), controller.imagePreviews.keys)
            assertSame(retainedBytes, controller.imagePreviews["retained"])
        }

    @Test
    fun `failed original submission keeps preview available for retry`() =
        runTest {
            val client = PreviewApi().apply { failSubmission = true }
            val controller = controller(backgroundScope, client)
            val bytes = byteArrayOf(1)
            controller.imagePreviews["original"] = bytes
            controller.updateAnswer(2, SurveyAnswerValue.Images(listOf("original")))

            controller.submit()

            assertEquals(SurveyPhase.Form, controller.phase)
            assertSame(bytes, controller.imagePreviews["original"])
            assertEquals(SurveyAnswerValue.Images(listOf("original")), controller.answers[2])
        }

    @Test
    fun `follow up transition releases original preview and retry retains follow up image`() =
        runTest {
            val followUpGate = CompletableDeferred<Unit>()
            val client = PreviewApi().apply { generateGate = followUpGate }
            val controller = controller(backgroundScope, client, followUpEnabled = true)
            controller.imagePreviews["original"] = byteArrayOf(1)
            controller.updateAnswer(2, SurveyAnswerValue.Images(listOf("original")))
            controller.scope.launch { controller.submit() }
            runCurrent()

            assertEquals(SurveyPhase.GeneratingFollowUp, controller.phase)
            assertTrue(controller.imagePreviews.isEmpty())
            assertEquals(listOf("original"), client.submittedAnswers.single().fileKeys)
            followUpGate.complete(Unit)
            runCurrent()
            assertEquals(SurveyPhase.FollowUp, controller.phase)

            val bytes = byteArrayOf(2)
            controller.imagePreviews["follow-up"] = bytes
            controller.imagePreviews["obsolete"] = byteArrayOf(3)
            controller.updateFollowUpAnswer("photo", FollowUpAnswerValue.Images(listOf("follow-up")))
            assertEquals(setOf("follow-up"), controller.imagePreviews.keys)
            assertSame(bytes, controller.imagePreviews["follow-up"])
            client.failFollowUp = true
            controller.submitFollowUp()
            assertEquals(SurveyPhase.FollowUp, controller.phase)
            assertSame(bytes, controller.imagePreviews["follow-up"])

            client.failFollowUp = false
            controller.submitFollowUp()
            assertEquals(listOf("follow-up"), client.savedFollowUpAnswers.single().fileKeys)
            assertEquals(SurveyPhase.Completed, controller.phase)
            assertTrue(controller.imagePreviews.isEmpty())
        }

    @Test
    fun `completed form without follow up releases preview after submitting file keys`() =
        runTest {
            val client = PreviewApi()
            val controller = controller(backgroundScope, client)
            controller.imagePreviews["original"] = byteArrayOf(1)
            controller.updateAnswer(2, SurveyAnswerValue.Images(listOf("original")))
            controller.submit()
            assertEquals(listOf("original"), client.submittedAnswers.single().fileKeys)
            assertEquals(SurveyPhase.Completed, controller.phase)
            assertTrue(controller.imagePreviews.isEmpty())
            assertFalse(controller.isSubmitting)
        }

    private fun controller(
        scope: CoroutineScope,
        client: FormConciergeApi = PreviewApi(),
        followUpEnabled: Boolean = false,
    ): SurveyController =
        SurveyController(client, FormConciergeSurveyConfig("project"), DeviceInfo(), {}, {}, {}, scope).apply {
            phase = SurveyPhase.Form
            survey =
                Survey(
                    8,
                    7,
                    "inquiries",
                    LocalizedText(mapOf("en" to "Contact")),
                    status = SurveyStatus.Published,
                    followUpEnabled = followUpEnabled,
                    captchaRequired = false,
                    createdAt = TIMESTAMP,
                    updatedAt = TIMESTAMP,
                )
            questions = listOf(question(2))
        }

    private fun question(
        id: Int,
        type: QuestionType = QuestionType.ImageUpload,
    ): Question = Question(id, 8, LocalizedText(mapOf("en" to "Question $id")), type, id, false)

    private class PreviewApi : FormConciergeApi by FormConciergeClient("https://example.invalid") {
        var failSubmission = false
        var failFollowUp = false
        var generateGate: CompletableDeferred<Unit>? = null
        var submittedAnswers = emptyList<Answer>()
        var savedFollowUpAnswers = emptyList<FollowUpSubmissionAnswer>()

        override fun hasAnonymousToken(): Boolean = true

        override suspend fun submitResponse(
            surveyId: Int,
            answers: List<Answer>,
            deviceInfo: DeviceInfo?,
            metadata: Map<String, JsonElement>?,
            idempotencyKey: String,
            captchaToken: String?,
        ): SurveyResponse {
            if (failSubmission) throw IOException("Submission failed")
            submittedAnswers = answers
            return SurveyResponse(31, surveyId, submittedAt = TIMESTAMP)
        }

        override suspend fun generateFollowUp(
            responseId: Int,
            locale: String?,
        ): FollowUpGenerateResult {
            generateGate?.await()
            return FollowUpGenerateResult(
                true,
                FollowUp(
                    1,
                    FollowUpStatus.Pending,
                    TIMESTAMP,
                    locale = "en",
                    items = listOf(FollowUpItem("photo", QuestionType.ImageUpload, "Photo")),
                ),
            )
        }

        override suspend fun saveFollowUp(
            responseId: Int,
            answers: List<FollowUpSubmissionAnswer>,
        ): SurveyResponse {
            if (failFollowUp) throw IOException("Follow-up failed")
            savedFollowUpAnswers = answers
            return SurveyResponse(responseId, 8, submittedAt = TIMESTAMP)
        }
    }

    companion object {
        private const val TIMESTAMP = "2026-10-07T00:00:00Z"
    }
}
