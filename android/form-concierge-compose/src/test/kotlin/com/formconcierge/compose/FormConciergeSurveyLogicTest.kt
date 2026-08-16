package com.formconcierge.compose

import kotlinx.serialization.json.JsonPrimitive
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class FormConciergeSurveyLogicTest {
    @Test
    fun `any visibility mode shows target when one rule matches`() {
        val sourceOne = question(1, QuestionType.SingleChoice)
        val sourceTwo = question(2, QuestionType.TextSingle)
        val target =
            question(
                id = 3,
                type = QuestionType.TextMultiLine,
                mode = VisibilityConditionMode.Any,
            )
        val rules =
            listOf(
                rule(1, targetId = 3, sourceId = 1, value = JsonPrimitive(99)),
                rule(
                    id = 2,
                    targetId = 3,
                    sourceId = 2,
                    operator = VisibilityOperator.Contains,
                    value = JsonPrimitive("rain"),
                ),
            )

        val visible =
            FormConciergeSurveyLogic.visibleQuestions(
                questions = listOf(sourceOne, sourceTwo, target),
                rules = rules,
                answers =
                    mapOf(
                        1 to SurveyAnswerValue.Single(1),
                        2 to SurveyAnswerValue.Text("heavy rain"),
                    ),
            )

        assertEquals(listOf(1, 2, 3), visible.map(Question::id))
    }

    @Test
    fun `target stays hidden when source question is itself hidden`() {
        val source = question(1, QuestionType.TextSingle)
        val conditionalSource = question(2, QuestionType.TextSingle)
        val target = question(3, QuestionType.TextSingle)
        val rules =
            listOf(
                rule(1, targetId = 2, sourceId = 1, value = JsonPrimitive("show")),
                rule(2, targetId = 3, sourceId = 2, value = JsonPrimitive("yes")),
            )

        val visible =
            FormConciergeSurveyLogic.visibleQuestions(
                listOf(source, conditionalSource, target),
                rules,
                mapOf(2 to SurveyAnswerValue.Text("yes")),
            )

        assertEquals(listOf(1), visible.map(Question::id))
    }

    @Test
    fun `validation enforces required text length and maximum choices`() {
        val text =
            question(
                id = 1,
                type = QuestionType.TextSingle,
                required = true,
                minLength = 3,
            )
        val choices =
            question(
                id = 2,
                type = QuestionType.MultipleChoice,
                maxSelected = 1,
            )

        assertTrue(
            FormConciergeSurveyLogic
                .validationError(listOf(text), emptyMap(), "ja")
                .orEmpty()
                .contains("必須"),
        )
        assertTrue(
            FormConciergeSurveyLogic
                .validationError(
                    listOf(text),
                    mapOf(1 to SurveyAnswerValue.Text("ab")),
                    "ja",
                ).orEmpty()
                .contains("3文字"),
        )
        assertTrue(
            FormConciergeSurveyLogic
                .validationError(
                    listOf(choices),
                    mapOf(2 to SurveyAnswerValue.Multiple(setOf(10, 11))),
                    "en",
                ).orEmpty()
                .contains("at most 1"),
        )
        assertNull(
            FormConciergeSurveyLogic.validationError(
                listOf(text, choices),
                mapOf(
                    1 to SurveyAnswerValue.Text("abc"),
                    2 to SurveyAnswerValue.Multiple(setOf(10)),
                ),
                "en",
            ),
        )
    }

    @Test
    fun `answer payload trims text and omits empty answers`() {
        val questions =
            listOf(
                question(1, QuestionType.TextSingle),
                question(2, QuestionType.MultipleChoice),
                question(3, QuestionType.ImageUpload),
            )

        val payload =
            FormConciergeSurveyLogic.answerPayload(
                questions,
                mapOf(
                    1 to SurveyAnswerValue.Text("  hello  "),
                    2 to SurveyAnswerValue.Multiple(emptySet()),
                    3 to SurveyAnswerValue.Images(listOf("media/key")),
                ),
            )

        assertEquals(2, payload.size)
        assertEquals("hello", payload.first().textValue)
        assertEquals(listOf("media/key"), payload.last().fileKeys)
    }

    @Test
    fun `answer value emptiness matches each variant`() {
        assertTrue(SurveyAnswerValue.Text("  ").isEmpty())
        assertTrue(SurveyAnswerValue.Multiple(emptySet()).isEmpty())
        assertTrue(SurveyAnswerValue.Images(emptyList()).isEmpty())
        assertFalse(SurveyAnswerValue.Single(1).isEmpty())
    }

    private fun question(
        id: Int,
        type: QuestionType,
        mode: VisibilityConditionMode = VisibilityConditionMode.All,
        required: Boolean = false,
        minLength: Int? = null,
        maxSelected: Int? = null,
    ) = Question(
        id = id,
        surveyId = 1,
        textTranslations = LocalizedText(mapOf("en" to "Question $id", "ja" to "質問$id")),
        type = type,
        orderIndex = id,
        isRequired = required,
        minLength = minLength,
        maxSelected = maxSelected,
        visibilityConditionMode = mode,
    )

    private fun rule(
        id: Int,
        targetId: Int,
        sourceId: Int,
        operator: VisibilityOperator = VisibilityOperator.Equals,
        value: JsonPrimitive,
    ) = QuestionVisibilityRule(
        id = id,
        surveyId = 1,
        targetQuestionId = targetId,
        sourceQuestionId = sourceId,
        operator = operator,
        value = value,
    )
}
