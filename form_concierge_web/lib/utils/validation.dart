import 'package:form_concierge_client/form_concierge_client.dart';

Map<int, String> validateAnswers(
  Map<int, dynamic> answers,
  List<Question> questions,
) {
  final errors = <int, String>{};

  for (final question in questions) {
    final answer = answers[question.id];

    // Required validation
    if (question.isRequired) {
      if (answer == null ||
          (answer is String && answer.trim().isEmpty) ||
          (answer is List && answer.isEmpty)) {
        errors[question.id!] = 'This question is required';
        continue;
      }
    }

    // Length validation for text questions
    if (answer is String && answer.isNotEmpty) {
      if (question.minLength != null && answer.length < question.minLength!) {
        errors[question.id!] =
            'Minimum ${question.minLength} characters required';
      }
      if (question.maxLength != null && answer.length > question.maxLength!) {
        errors[question.id!] =
            'Maximum ${question.maxLength} characters allowed';
      }
    }
  }

  return errors;
}
