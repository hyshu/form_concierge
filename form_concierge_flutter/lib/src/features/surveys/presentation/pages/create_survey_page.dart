import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:go_router/go_router.dart';

import '../capsules/survey_form_capsule.dart';
import '../widgets/survey_form.dart';

/// Page for creating a new survey.
class CreateSurveyPage extends RearchConsumer {
  const CreateSurveyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetHandle use) {
    final formManager = use(surveyFormManagerCapsule);
    final controllers = use(surveyFormControllersCapsule);
    final formState = formManager.getState(null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Survey'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SurveyForm(
                controllers: controllers,
                isSaving: formState.isSaving,
                error: formState.error,
                onSave:
                    ({
                      required String title,
                      required String slug,
                      String? description,
                      required AuthRequirement authRequirement,
                    }) async {
                      final survey = await formManager.createSurvey(
                        title: title,
                        slug: slug,
                        description: description,
                        authRequirement: authRequirement,
                      );
                      if (survey != null && context.mounted) {
                        context.go('/admin/surveys/${survey.id}');
                      }
                    },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
