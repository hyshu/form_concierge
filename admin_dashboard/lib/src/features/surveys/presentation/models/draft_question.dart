import 'package:form_concierge_client/form_concierge_client.dart';

const _uuid = Uuid();

/// A draft choice before being saved to the server.
class DraftChoice {
  final String tempId;
  final String text;

  const DraftChoice({
    required this.tempId,
    required this.text,
  });

  factory DraftChoice.create({required String text}) {
    return DraftChoice(
      tempId: _uuid.v4(),
      text: text,
    );
  }

  DraftChoice copyWith({String? text}) {
    return DraftChoice(
      tempId: tempId,
      text: text ?? this.text,
    );
  }
}

/// A draft question before being saved to the server.
class DraftQuestion {
  final String tempId;
  final String text;
  final QuestionType type;
  final bool isRequired;
  final String? placeholder;
  final List<DraftChoice> choices;

  const DraftQuestion({
    required this.tempId,
    required this.text,
    required this.type,
    required this.isRequired,
    this.placeholder,
    this.choices = const [],
  });

  factory DraftQuestion.create({
    required String text,
    required QuestionType type,
    required bool isRequired,
    String? placeholder,
  }) {
    // Add default choices for choice-type questions
    final choices = <DraftChoice>[];
    if (type == QuestionType.singleChoice ||
        type == QuestionType.multipleChoice) {
      choices.addAll([
        DraftChoice.create(text: 'Choice 1'),
        DraftChoice.create(text: 'Choice 2'),
      ]);
    }

    return DraftQuestion(
      tempId: _uuid.v4(),
      text: text,
      type: type,
      isRequired: isRequired,
      placeholder: placeholder,
      choices: choices,
    );
  }

  /// Create from QuestionWithChoices (AI generated).
  factory DraftQuestion.fromQuestionWithChoices(QuestionWithChoices q) {
    return DraftQuestion(
      tempId: _uuid.v4(),
      text: q.text,
      type: q.type,
      isRequired: q.isRequired,
      placeholder: q.placeholder,
      choices: q.choices.map((c) => DraftChoice.create(text: c)).toList(),
    );
  }

  DraftQuestion copyWith({
    String? text,
    QuestionType? type,
    bool? isRequired,
    String? placeholder,
    List<DraftChoice>? choices,
  }) {
    return DraftQuestion(
      tempId: tempId,
      text: text ?? this.text,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      placeholder: placeholder ?? this.placeholder,
      choices: choices ?? this.choices,
    );
  }

  /// Convert to QuestionWithChoices for server submission.
  QuestionWithChoices toQuestionWithChoices() {
    return QuestionWithChoices(
      text: text,
      type: type,
      isRequired: isRequired,
      placeholder: placeholder,
      choices: choices.map((c) => c.text).toList(),
    );
  }

  /// Whether this question type uses choices.
  bool get hasChoices =>
      type == QuestionType.singleChoice || type == QuestionType.multipleChoice;
}
