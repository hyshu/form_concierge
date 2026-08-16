package com.formconcierge.compose

import kotlinx.serialization.json.Json
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class FormConciergeModelsTest {
    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun `localized text decodes worker map shape`() {
        val project = json.decodeFromString<PublicProject>(projectJson)

        assertEquals("お問い合わせ", project.surveys.single().title("ja_JP"))
        assertEquals("Contact", project.surveys.single().title("en-US"))
        assertTrue(project.surveys.single().captchaRequired)
    }

    @Test
    fun `inquiry record captures text choices images and server timestamp`() {
        val question =
            Question(
                id = 8,
                surveyId = 1,
                textTranslations = LocalizedText(mapOf("ja" to "内容")),
                type = QuestionType.MultipleChoice,
                orderIndex = 0,
                isRequired = true,
            )
        val submission =
            FormConciergeSubmission(
                response =
                    SurveyResponse(
                        id = 42,
                        surveyId = 1,
                        submittedAt = "2026-08-16T01:02:03.456Z",
                    ),
                answers =
                    listOf(
                        Answer(
                            questionId = 8,
                            textValue = "詳しい内容",
                            selectedChoiceIds = listOf(2),
                            fileKeys = listOf("upload/key"),
                        ),
                    ),
                questions = listOf(question),
                choicesByQuestion =
                    mapOf(
                        8 to
                            listOf(
                                Choice(2, 8, LocalizedText(mapOf("ja" to "不具合")), 0),
                            ),
                    ),
                locale = "ja",
            )

        val record = InquiryRecord.fromSubmission(submission)

        assertEquals(42, record.responseId)
        assertEquals("詳しい内容\n不具合", record.items.single().answer)
        assertTrue(record.items.single().hasImages)
        assertEquals(1_786_842_123_456L, record.submittedAtEpochMillis)
    }

    private val projectJson =
        """
        {
          "project": {
            "id": 1,
            "slug": "ambient",
            "customDomain": null,
            "defaultLocale": "ja",
            "supportedLocales": ["ja", "en"],
            "name": "Ambient",
            "createdAt": "2026-01-01T00:00:00.000Z",
            "updatedAt": "2026-01-01T00:00:00.000Z"
          },
          "surveys": [{
            "id": 7,
            "projectId": 1,
            "slug": "inquiries",
            "titleTranslations": {"ja": "お問い合わせ", "en": "Contact"},
            "descriptionTranslations": {},
            "status": "published",
            "webEnabled": true,
            "followUpEnabled": false,
            "captchaEnabled": true,
            "captchaRequired": true,
            "createdAt": "2026-01-01T00:00:00.000Z",
            "updatedAt": "2026-01-01T00:00:00.000Z"
          }]
        }
        """.trimIndent()
}
