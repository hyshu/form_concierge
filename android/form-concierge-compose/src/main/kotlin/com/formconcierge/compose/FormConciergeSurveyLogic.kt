package com.formconcierge.compose

import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonPrimitive

public object FormConciergeSurveyLogic {
    public fun visibleQuestions(
        questions: List<Question>,
        rules: List<QuestionVisibilityRule>,
        answers: Map<Int, SurveyAnswerValue>,
    ): List<Question> {
        val questionsById = questions.associateBy(Question::id)
        val rulesByTarget = rules.groupBy(QuestionVisibilityRule::targetQuestionId)
        val visibleIds = mutableSetOf<Int>()
        return questions.filter { question ->
            val questionRules = rulesByTarget[question.id].orEmpty()
            val visible =
                if (questionRules.isEmpty()) {
                    true
                } else {
                    val outcomes =
                        questionRules.map { rule ->
                            val source = questionsById[rule.sourceQuestionId]
                            source != null && source.id in visibleIds &&
                                matchesRule(source, rule, answers[source.id])
                        }
                    when (question.visibilityConditionMode) {
                        VisibilityConditionMode.Any -> outcomes.any { it }
                        VisibilityConditionMode.All -> outcomes.all { it }
                    }
                }
            if (visible) visibleIds += question.id
            visible
        }
    }

    public fun validationError(
        questions: List<Question>,
        answers: Map<Int, SurveyAnswerValue>,
        locale: String,
    ): String? {
        questions.forEach { question ->
            val value = answers[question.id]
            val questionText = question.text(locale)
            if (question.isRequired && (value == null || value.isEmpty())) {
                return FormConciergeStrings.text(
                    locale,
                    "requiredQuestion",
                    "question" to questionText,
                )
            }
            if (value is SurveyAnswerValue.Text) {
                val count = value.value.trim().length
                if (count > 0 && question.minLength != null && count < question.minLength) {
                    return FormConciergeStrings.text(
                        locale,
                        "minCharacters",
                        "question" to questionText,
                        "count" to question.minLength,
                    )
                }
                if (question.maxLength != null && count > question.maxLength) {
                    return FormConciergeStrings.text(
                        locale,
                        "maxCharacters",
                        "question" to questionText,
                        "count" to question.maxLength,
                    )
                }
            }

            val selectedCount =
                when (value) {
                    is SurveyAnswerValue.Single -> 1
                    is SurveyAnswerValue.Multiple -> value.choiceIds.size
                    is SurveyAnswerValue.Images -> value.fileKeys.size
                    is SurveyAnswerValue.Text, null -> 0
                }
            if (question.type in selectableQuestionTypes) {
                if (question.minSelected != null && selectedCount < question.minSelected) {
                    return FormConciergeStrings.text(
                        locale,
                        "minChoices",
                        "question" to questionText,
                        "count" to question.minSelected,
                    )
                }
                if (question.maxSelected != null && selectedCount > question.maxSelected) {
                    return FormConciergeStrings.text(
                        locale,
                        "maxChoices",
                        "question" to questionText,
                        "count" to question.maxSelected,
                    )
                }
            }
        }
        return null
    }

    public fun answerPayload(
        questions: List<Question>,
        answers: Map<Int, SurveyAnswerValue>,
    ): List<Answer> =
        questions.mapNotNull { question ->
            when (val value = answers[question.id]) {
                is SurveyAnswerValue.Text -> {
                    value.value.trim().takeIf(String::isNotEmpty)?.let {
                        Answer(questionId = question.id, textValue = it)
                    }
                }

                is SurveyAnswerValue.Single -> {
                    Answer(
                        questionId = question.id,
                        selectedChoiceIds = listOf(value.choiceId),
                    )
                }

                is SurveyAnswerValue.Multiple -> {
                    value.choiceIds.takeIf(Set<Int>::isNotEmpty)?.let {
                        Answer(questionId = question.id, selectedChoiceIds = it.sorted())
                    }
                }

                is SurveyAnswerValue.Images -> {
                    value.fileKeys.takeIf(List<String>::isNotEmpty)?.let {
                        Answer(questionId = question.id, fileKeys = it)
                    }
                }

                null -> {
                    null
                }
            }
        }

    private fun matchesRule(
        source: Question,
        rule: QuestionVisibilityRule,
        answer: SurveyAnswerValue?,
    ): Boolean {
        val hasAnswer = answer != null && !answer.isEmpty()
        when (rule.operator) {
            VisibilityOperator.IsAnswered -> return hasAnswer
            VisibilityOperator.IsNotAnswered -> return !hasAnswer
            else -> if (!hasAnswer) return false
        }

        return when (source.type) {
            QuestionType.TextSingle,
            QuestionType.TextMultiLine,
            -> {
                val actual = (answer as? SurveyAnswerValue.Text)?.value?.trim().orEmpty()
                val expected =
                    runCatching { rule.value?.jsonPrimitive?.content }.getOrNull()
                        ?: return false
                when (rule.operator) {
                    VisibilityOperator.Equals -> actual == expected

                    VisibilityOperator.NotEquals -> actual != expected

                    VisibilityOperator.Contains -> expected in actual

                    VisibilityOperator.NotContains -> expected !in actual

                    VisibilityOperator.IsAnswered,
                    VisibilityOperator.IsNotAnswered,
                    -> false
                }
            }

            QuestionType.SingleChoice,
            QuestionType.MultipleChoice,
            -> {
                val expected =
                    runCatching { rule.value?.jsonPrimitive?.intOrNull }.getOrNull()
                        ?: return false
                val selected =
                    when (answer) {
                        is SurveyAnswerValue.Single -> setOf(answer.choiceId)
                        is SurveyAnswerValue.Multiple -> answer.choiceIds
                        else -> emptySet()
                    }
                when (rule.operator) {
                    VisibilityOperator.Equals,
                    VisibilityOperator.Contains,
                    -> expected in selected

                    VisibilityOperator.NotEquals,
                    VisibilityOperator.NotContains,
                    -> expected !in selected

                    VisibilityOperator.IsAnswered,
                    VisibilityOperator.IsNotAnswered,
                    -> false
                }
            }

            QuestionType.ImageUpload -> {
                hasAnswer
            }
        }
    }

    private val selectableQuestionTypes =
        setOf(
            QuestionType.SingleChoice,
            QuestionType.MultipleChoice,
            QuestionType.ImageUpload,
        )
}
