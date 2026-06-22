part of form_concierge_client;

class Answer {
  final int? id;
  final int surveyResponseId;
  final int questionId;
  final String? textValue;
  final List<int>? selectedChoiceIds;

  const Answer({
    this.id,
    required this.surveyResponseId,
    required this.questionId,
    this.textValue,
    this.selectedChoiceIds,
  });

  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
    id: json['id'] == null ? null : _int(json['id']),
    surveyResponseId: _int(json['surveyResponseId']),
    questionId: _int(json['questionId']),
    textValue: json['textValue'] as String?,
    selectedChoiceIds: _intList(json['selectedChoiceIds']),
  );

  Map<String, dynamic> toJson() => _withoutNulls({
    'id': id,
    'surveyResponseId': surveyResponseId,
    'questionId': questionId,
    'textValue': textValue,
    'selectedChoiceIds': selectedChoiceIds,
  });

  Answer copyWith({
    int? id,
    int? surveyResponseId,
    int? questionId,
    String? textValue,
    List<int>? selectedChoiceIds,
  }) {
    return Answer(
      id: id ?? this.id,
      surveyResponseId: surveyResponseId ?? this.surveyResponseId,
      questionId: questionId ?? this.questionId,
      textValue: textValue ?? this.textValue,
      selectedChoiceIds: selectedChoiceIds ?? this.selectedChoiceIds,
    );
  }
}

List<Answer> buildAnswers(
  Map<int, dynamic> answerValues,
  Iterable<Question> questions, {
  int surveyResponseId = 0,
}) {
  final result = <Answer>[];

  for (final question in questions) {
    final questionId = question.id;
    if (questionId == null) continue;

    final value = answerValues[questionId];
    if (value == null) continue;

    switch (question.type) {
      case QuestionType.singleChoice:
        if (value is int) {
          result.add(
            Answer(
              surveyResponseId: surveyResponseId,
              questionId: questionId,
              selectedChoiceIds: [value],
            ),
          );
        }
      case QuestionType.multipleChoice:
        if (value is List<int> && value.isNotEmpty) {
          result.add(
            Answer(
              surveyResponseId: surveyResponseId,
              questionId: questionId,
              selectedChoiceIds: value,
            ),
          );
        }
      case QuestionType.textSingle:
      case QuestionType.textMultiLine:
        if (value is String && value.trim().isNotEmpty) {
          result.add(
            Answer(
              surveyResponseId: surveyResponseId,
              questionId: questionId,
              textValue: value.trim(),
            ),
          );
        }
    }
  }

  return result;
}
