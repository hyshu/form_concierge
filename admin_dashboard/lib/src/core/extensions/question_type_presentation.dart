import 'package:flutter/widgets.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

/// Labels and icons used to present question types in the editor.
extension QuestionTypePresentation on QuestionType {
  /// The icon associated with this question type.
  IconData get icon => switch (this) {
    QuestionType.singleChoice => LucideIcons.circleDot,
    QuestionType.multipleChoice => LucideIcons.squareCheck,
    QuestionType.textSingle => LucideIcons.textCursorInput,
    QuestionType.textMultiLine => LucideIcons.alignLeft,
    QuestionType.imageUpload => LucideIcons.image,
  };

  /// The English display label for this question type.
  String get label => switch (this) {
    QuestionType.singleChoice => 'Single Choice',
    QuestionType.multipleChoice => 'Multiple Choice',
    QuestionType.textSingle => 'Short Text',
    QuestionType.textMultiLine => 'Long Text',
    QuestionType.imageUpload => 'Image Upload',
  };
}
