import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

extension QuestionTypePresentation on QuestionType {
  IconData get icon {
    return switch (this) {
      QuestionType.singleChoice => Icons.radio_button_checked,
      QuestionType.multipleChoice => Icons.check_box,
      QuestionType.textSingle => Icons.short_text,
      QuestionType.textMultiLine => Icons.notes,
    };
  }

  String get label {
    return switch (this) {
      QuestionType.singleChoice => 'Single Choice',
      QuestionType.multipleChoice => 'Multiple Choice',
      QuestionType.textSingle => 'Short Text',
      QuestionType.textMultiLine => 'Long Text',
    };
  }
}
