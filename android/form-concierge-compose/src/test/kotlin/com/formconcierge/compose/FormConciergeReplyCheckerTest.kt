package com.formconcierge.compose

import kotlinx.serialization.json.JsonElement
import org.junit.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class FormConciergeReplyCheckerTest {
    @Test
    fun `checker tracks latest reply separately for each response`() =
        kotlinx.coroutines.test.runTest {
            val api = FakeApi("2026-08-16T01:00:00.000Z")
            val store = MemoryStore()
            val checker = FormConciergeReplyChecker(api, "token", store, responseId = 9)

            assertTrue(checker.check().hasNewReplies)
            checker.markLatestSeen()
            assertFalse(checker.check().hasNewReplies)

            api.latest = "2026-08-16T02:00:00.000Z"
            assertTrue(checker.check().hasNewReplies)
            assertTrue(api.hasAnonymousToken())
        }

    private class MemoryStore : FormConciergeSessionStore {
        private val seen = mutableMapOf<Int?, String>()

        override suspend fun readAnonymousToken(): String? = null

        override suspend fun writeAnonymousToken(token: String) = Unit

        override suspend fun readInquiries(): List<InquiryRecord> = emptyList()

        override suspend fun addInquiry(record: InquiryRecord) = Unit

        override suspend fun updateFollowUp(
            responseId: Int,
            followUpItems: List<InquiryContentItem>,
        ) = Unit

        override suspend fun markRepliesSeen(responseId: Int) = Unit

        override suspend fun readLastSeenReplyAt(responseId: Int?): String? = seen[responseId]

        override suspend fun writeLastSeenReplyAt(
            responseId: Int?,
            timestamp: String,
        ) {
            seen[responseId] = timestamp
        }
    }

    private class FakeApi(
        var latest: String?,
    ) : FormConciergeApi {
        private var token: String? = null

        override fun setAnonymousToken(token: String?) {
            this.token = token
        }

        override fun hasAnonymousToken(): Boolean = token != null

        override suspend fun latestReplyAt(responseId: Int?): String? = latest

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

        private fun <T> unused(): T = error("Not used by this test")
    }
}
