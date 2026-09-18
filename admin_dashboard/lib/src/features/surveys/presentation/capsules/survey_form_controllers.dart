import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

import '../widgets/localized_text_helpers.dart';

/// Form controllers for survey editing.
class SurveyFormControllers {
  /// Controls the slug input.
  final TextEditingController slug;

  /// Text controllers indexed by locale for the title inputs.
  final Map<String, TextEditingController> titleTranslations;

  /// Text controllers indexed by locale for the description inputs.
  final Map<String, TextEditingController> descriptionTranslations;

  /// Controls the follow up prompt input.
  final TextEditingController followUpPrompt;

  /// Creates SurveyFormControllers with the supplied values.
  SurveyFormControllers({
    required this.slug,
    required this.titleTranslations,
    required this.descriptionTranslations,
    required this.followUpPrompt,
  });

  /// Releases all text controllers owned by the survey form.
  void dispose() {
    slug.dispose();
    disposeLocalizedTextControllers(titleTranslations);
    disposeLocalizedTextControllers(descriptionTranslations);
    followUpPrompt.dispose();
  }

  /// Fills the controllers with the localized values of an existing survey.
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
    followUpPrompt.text = survey.followUpPrompt ?? '';
  }

  /// Clears the localized text and follow-up prompt inputs.
  void clear() {
    slug.clear();
    for (final controller in titleTranslations.values) {
      controller.clear();
    }
    for (final controller in descriptionTranslations.values) {
      controller.clear();
    }
    followUpPrompt.clear();
  }

  /// Collects the current localized survey titles from their controllers.
  LocalizedText titleValue() => localizedTextFromControllers(titleTranslations);

  /// Collects the current localized survey descriptions from their controllers.
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
      followUpPrompt: TextEditingController(),
    ),
  );

  use.effect(() => controllers.dispose, []);

  return controllers;
}
