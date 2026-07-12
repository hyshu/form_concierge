import 'package:flutter/material.dart';
import 'package:form_concierge/form_concierge.dart';

void main() {
  runApp(const FormConciergeExample());
}

class FormConciergeExample extends StatelessWidget {
  const FormConciergeExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Form Concierge')),
        body: FormConciergeSurvey(
          client: Client('https://your-worker.example.com'),
          projectSlug: 'demo-project',
          surveySlug: 'customer-feedback',
          onAnonymousSession: (session) async {
            // Persist session.token and pass it back as anonymousToken.
          },
        ),
      ),
    );
  }
}
