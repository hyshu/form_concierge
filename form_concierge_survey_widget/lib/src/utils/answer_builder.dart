import 'package:form_concierge_client/form_concierge_client.dart';

List<Answer> buildAnswers(Map<int, dynamic> answers, List<Question> questions) {
  final result = <Answer>[];

  for (final question in questions) {
    final value = answers[question.id];
    if (value == null) continue;

    switch (question.type) {
      case QuestionType.singleChoice:
        if (value is int) {
          result.add(
            Answer(
              surveyResponseId: 0, // Set by server
              questionId: question.id!,
              selectedOptionIds: [value],
            ),
          );
        }
      case QuestionType.multipleChoice:
        if (value is List<int> && value.isNotEmpty) {
          result.add(
            Answer(
              surveyResponseId: 0, // Set by server
              questionId: question.id!,
              selectedOptionIds: value,
            ),
          );
        }
      case QuestionType.textSingle:
      case QuestionType.textMultiLine:
        if (value is String && value.trim().isNotEmpty) {
          result.add(
            Answer(
              surveyResponseId: 0, // Set by server
              questionId: question.id!,
              textValue: value.trim(),
            ),
          );
        }
    }
  }

  return result;
}
