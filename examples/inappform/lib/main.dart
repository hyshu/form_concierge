import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_survey_widget/form_concierge_survey_widget.dart';

late final Client client;

const _apiUrl = String.fromEnvironment(
  'FORM_CONCIERGE_API_URL',
  defaultValue: 'http://localhost:8787',
);
const _projectSlug = String.fromEnvironment(
  'FORM_CONCIERGE_PROJECT_SLUG',
  defaultValue: 'demo-project',
);
const _surveyIdValue = int.fromEnvironment('FORM_CONCIERGE_SURVEY_ID');
const _locale = String.fromEnvironment('FORM_CONCIERGE_LOCALE');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  client = Client(_apiUrl);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Survey Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('In-App Survey Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tap the button to open a survey'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _openSurvey(context),
              child: const Text('Open Survey'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSurvey(BuildContext context) async {
    final submitted = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (context) => const SurveyPage()));
    if (!context.mounted || submitted != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Survey submitted!')));
  }
}

class SurveyPage extends StatelessWidget {
  const SurveyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Survey')),
      body: FormConciergeSurvey(
        client: client,
        projectSlug: _projectSlug,
        surveyId: _surveyIdValue == 0 ? null : _surveyIdValue,
        locale: _locale.isEmpty ? null : _locale,
        metadata: const {'source': 'inappform-example'},
        onSubmitted: () {
          Navigator.of(context).pop(true);
        },
      ),
    );
  }
}
