import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:rearch/rearch.dart';

/// Form controllers for survey editing.
class SurveyFormControllers {
  final TextEditingController title;
  final TextEditingController slug;
  final TextEditingController description;

  SurveyFormControllers({
    required this.title,
    required this.slug,
    required this.description,
  });

  void dispose() {
    title.dispose();
    slug.dispose();
    description.dispose();
  }

  void populateFrom(Survey survey) {
    title.text = survey.title;
    slug.text = survey.slug;
    description.text = survey.description ?? '';
  }
}

/// Capsule for survey form controllers with cleanup.
SurveyFormControllers surveyFormControllersCapsule(CapsuleHandle use) {
  final controllers = use.memo(
    () => SurveyFormControllers(
      title: TextEditingController(),
      slug: TextEditingController(),
      description: TextEditingController(),
    ),
  );

  use.effect(() {
    return controllers.dispose;
  }, []);

  return controllers;
}
