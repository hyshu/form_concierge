import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:form_concierge/form_concierge.dart';

const _apiUrl = String.fromEnvironment(
  'FORM_CONCIERGE_API_URL',
  defaultValue: 'http://localhost:8787',
);
const _projectSlug = String.fromEnvironment(
  'FORM_CONCIERGE_PROJECT_SLUG',
  defaultValue: 'demo-project',
);
const _surveySlug = String.fromEnvironment('FORM_CONCIERGE_SURVEY_SLUG');
const _surveyIdValue = int.fromEnvironment('FORM_CONCIERGE_SURVEY_ID');

void main() {
  runApp(const FlutterMobileSimpleApp());
}

class FlutterMobileSimpleApp extends StatefulWidget {
  const FlutterMobileSimpleApp({super.key});

  @override
  State<FlutterMobileSimpleApp> createState() => _FlutterMobileSimpleAppState();
}

class _FlutterMobileSimpleAppState extends State<FlutterMobileSimpleApp> {
  late final Client _client;

  @override
  void initState() {
    super.initState();
    _client = Client(_apiUrl);
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Mobile Simple',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomePage(client: _client),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Mobile Simple')),
      body: Center(
        child: FilledButton(
          onPressed: () => _openForm(context),
          child: const Text('Open form'),
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => SurveyScreen(client: client)),
    );
    if (!context.mounted || submitted != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Form submitted')));
  }
}

class SurveyScreen extends StatelessWidget {
  const SurveyScreen({super.key, required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form')),
      body: FormConciergeSurvey(
        client: client,
        projectSlug: _projectSlug,
        surveySlug: _surveySlug.isEmpty ? null : _surveySlug,
        surveyId: _surveyIdValue == 0 ? null : _surveyIdValue,
        onSubmitted: () {
          Navigator.of(context).pop(true);
        },
      ),
    );
  }
}
