import 'package:flutter/widgets.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

extension QuestionTypePresentation on QuestionType {
  IconData get icon => switch (this) {
    QuestionType.singleChoice => LucideIcons.circleDot,
    QuestionType.multipleChoice => LucideIcons.squareCheck,
    QuestionType.textSingle => LucideIcons.textCursorInput,
    QuestionType.textMultiLine => LucideIcons.alignLeft,
    QuestionType.imageUpload => LucideIcons.image,
  };

  String get label => switch (this) {
    QuestionType.singleChoice => 'Single Choice',
    QuestionType.multipleChoice => 'Multiple Choice',
    QuestionType.textSingle => 'Short Text',
    QuestionType.textMultiLine => 'Long Text',
    QuestionType.imageUpload => 'Image Upload',
  };
}
