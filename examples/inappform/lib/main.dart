import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge_survey_widget/form_concierge_survey_widget.dart';
import 'package:serverpod_auth_core_flutter/serverpod_auth_core_flutter.dart';

late final Client client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  client = Client('http://localhost:8080/')
    ..authSessionManager = FlutterAuthSessionManager();

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
      appBar: AppBar(
        title: const Text('In-App Survey Example'),
      ),
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

  void _openSurvey(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SurveyPage(),
      ),
    );
  }
}

class SurveyPage extends StatelessWidget {
  const SurveyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey'),
      ),
      body: FormConciergeSurvey(
        client: client,
        surveySlug: 'demo-survey',
        onSubmitted: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Survey submitted!')),
          );
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
