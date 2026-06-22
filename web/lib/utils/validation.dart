import 'package:form_concierge_client/form_concierge_client.dart';

Map<int, String> validateAnswers(
  AnswerValues answers,
  List<Question> questions,
  String locale,
) {
  return validateSurveyAnswers(answers, questions, locale);
}
