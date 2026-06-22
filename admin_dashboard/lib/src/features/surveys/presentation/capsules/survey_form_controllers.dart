import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

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
    for (final controller in titleTranslations.values) {
      controller.dispose();
    }
    for (final controller in descriptionTranslations.values) {
      controller.dispose();
    }
  }

  void populateFrom(Survey survey) {
    slug.text = survey.slug;
    for (final locale in formContentLocaleCodes) {
      titleTranslations[locale]!.text = survey.titleTranslations.valueFor(
        locale,
      );
      descriptionTranslations[locale]!.text = survey.descriptionTranslations
          .valueFor(locale);
    }
  }

  LocalizedText titleValue() {
    return LocalizedText({
      for (final locale in formContentLocaleCodes)
        locale: titleTranslations[locale]!.text.trim(),
    });
  }

  LocalizedText descriptionValue() {
    return LocalizedText({
      for (final locale in formContentLocaleCodes)
        locale: descriptionTranslations[locale]!.text.trim(),
    });
  }
}

/// Capsule for survey form controllers with cleanup.
SurveyFormControllers surveyFormControllersCapsule(CapsuleHandle use) {
  final controllers = use.memo(
    () => SurveyFormControllers(
      slug: TextEditingController(),
      titleTranslations: {
        for (final locale in formContentLocaleCodes)
          locale: TextEditingController(),
      },
      descriptionTranslations: {
        for (final locale in formContentLocaleCodes)
          locale: TextEditingController(),
      },
    ),
  );

  use.effect(() {
    return controllers.dispose;
  }, []);

  return controllers;
}
