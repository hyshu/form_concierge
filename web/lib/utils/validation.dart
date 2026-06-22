import 'package:form_concierge_client/form_concierge_client.dart';

Map<int, String> validateAnswers(
  Map<int, dynamic> answers,
  List<Question> questions,
) {
  return validateSurveyAnswers(answers, questions);
}
