import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../widgets/localized_text_helpers.dart';

/// Form controllers for survey editing.
class SurveyFormControllers {
  final TextEditingController slug;
  final Map<String, TextEditingController> titleTranslations;
  final Map<String, TextEditingController> descriptionTranslations;

  SurveyFormControllers({
    required this.slug,
    required this.titleTranslations,
    required this.descriptionTranslations,
  });

  void dispose() {
    slug.dispose();
    disposeLocalizedTextControllers(titleTranslations);
    disposeLocalizedTextControllers(descriptionTranslations);
  }

  void populateFrom(Survey survey) {
    slug.text = survey.slug;
    populateLocalizedTextControllers(
      titleTranslations,
      survey.titleTranslations,
    );
    populateLocalizedTextControllers(
      descriptionTranslations,
      survey.descriptionTranslations,
    );
  }

  LocalizedText titleValue() => localizedTextFromControllers(titleTranslations);

  LocalizedText descriptionValue() =>
      localizedTextFromControllers(descriptionTranslations);
}

/// Capsule for survey form controllers with cleanup.
SurveyFormControllers surveyFormControllersCapsule(CapsuleHandle use) {
  final controllers = use.memo(
    () => SurveyFormControllers(
      slug: TextEditingController(),
      titleTranslations: createLocalizedTextControllers(),
      descriptionTranslations: createLocalizedTextControllers(),
    ),
  );

  use.effect(() => controllers.dispose, []);

  return controllers;
}
