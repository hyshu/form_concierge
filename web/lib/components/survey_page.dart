import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr/dom.dart';

import 'survey_client.dart';

class SurveyPage extends StatelessComponent {
  const SurveyPage({
    required this.slug,
    required this.serverUrl,
    super.key,
  });

  final String slug;
  final String serverUrl;

  @override
  Component build(BuildContext context) {
    return AsyncBuilder(
      builder: (context) async {
        final client = Client(serverUrl);

        try {
          final survey = await client.survey.getBySlug(slug);

          if (survey == null) {
            return _buildNotFound();
          }

          final questions =
              await client.survey.getQuestionsForSurvey(survey.id!);
          final choicesByQuestion = <int, List<Choice>>{};

          for (final question in questions) {
            if (question.type == QuestionType.singleChoice ||
                question.type == QuestionType.multipleChoice) {
              final choices =
                  await client.survey.getChoicesForQuestion(question.id!);
              choicesByQuestion[question.id!] = choices;
            }
          }

          return Component.fragment([
            Document.head(title: survey.title),
            SurveyClient(
              surveyJson: survey.toJson(),
              questionsJson: questions.map((q) => q.toJson()).toList(),
              choicesByQuestionJson: _encodeChoicesMap(choicesByQuestion),
              serverUrl: serverUrl,
            ),
          ]);
        } catch (e) {
          return _buildError(e.toString());
        }
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> _encodeChoicesMap(
    Map<int, List<Choice>> choices,
  ) {
    return choices.map(
      (k, v) => MapEntry(k.toString(), v.map((c) => c.toJson()).toList()),
    );
  }

  Component _buildNotFound() {
    return div(classes: 'error-page', [
      h1([Component.text('Survey Not Found')]),
      p([
        Component.text(
            'The survey you are looking for does not exist or is not available.')
      ]),
    ]);
  }

  Component _buildError(String message) {
    return div(classes: 'error-page', [
      h1([Component.text('Error')]),
      p([Component.text(message)]),
    ]);
  }
}
