import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A draft choice before being saved to the server.
class DraftChoice {
  /// A local identifier used before the draft is saved to the server.
  final String tempId;

  /// Display text indexed by locale code.
  final LocalizedText textTranslations;

  /// Creates DraftChoice with the supplied values.
  const DraftChoice({
    required this.tempId,
    required this.textTranslations,
  });

  /// Creates an unsaved choice with a fresh temporary identifier.
  factory DraftChoice.create({required LocalizedText textTranslations}) =>
      DraftChoice(
        tempId: _uuid.v4(),
        textTranslations: textTranslations,
      );

  /// Returns a copy with the supplied state changes.
  DraftChoice copyWith({LocalizedText? textTranslations}) => DraftChoice(
    tempId: tempId,
    textTranslations: textTranslations ?? this.textTranslations,
  );

  /// The text displayed by this component.
  String get text => textTranslations.valueFor(defaultFormContentLocale);
}

/// A draft question before being saved to the server.
class DraftQuestion {
  /// A local identifier used before the draft is saved to the server.
  final String tempId;

  /// Display text indexed by locale code.
  final LocalizedText textTranslations;

  /// The input format used to collect the answer.
  final QuestionType type;

  /// Whether the respondent must answer this question.
  final bool isRequired;

  /// Input hints indexed by locale code.
  final LocalizedText placeholderTranslations;

  /// The minimum accepted text length, or null when no minimum is set.
  final int? minLength;

  /// The maximum accepted text length, or null when no maximum is set.
  final int? maxLength;

  /// The minimum number of choices or uploaded files required, if set.
  final int? minSelected;

  /// The maximum number of choices or uploaded files allowed, if set.
  final int? maxSelected;

  /// The choices available for this question.
  final List<DraftChoice> choices;

  /// Creates DraftQuestion with the supplied values.
  const DraftQuestion({
    required this.tempId,
    required this.textTranslations,
    required this.type,
    required this.isRequired,
    required this.placeholderTranslations,
    this.minLength,
    this.maxLength,
    this.minSelected,
    this.maxSelected,
    this.choices = const [],
  });

  /// Creates an unsaved question with a fresh temporary identifier and initial choices.
  factory DraftQuestion.create({
    required LocalizedText textTranslations,
    required QuestionType type,
    required bool isRequired,
    required LocalizedText placeholderTranslations,
    int? minLength,
    int? maxLength,
    int? minSelected,
    int? maxSelected,
    required LocalizedText firstChoiceTranslations,
    required LocalizedText secondChoiceTranslations,
  }) {
    // Add default choices for choice-type questions
    final choices = <DraftChoice>[];
    if (type.usesChoices) {
      choices.addAll([
        DraftChoice.create(textTranslations: firstChoiceTranslations),
        DraftChoice.create(textTranslations: secondChoiceTranslations),
      ]);
    }

    return DraftQuestion(
      tempId: _uuid.v4(),
      textTranslations: textTranslations,
      type: type,
      isRequired: isRequired,
      placeholderTranslations: placeholderTranslations,
      minLength: minLength,
      maxLength: maxLength,
      minSelected: minSelected,
      maxSelected: maxSelected,
      choices: choices,
    );
  }

  /// Create from QuestionWithChoices (AI generated).
  factory DraftQuestion.fromQuestionWithChoices(QuestionWithChoices q) =>
      DraftQuestion(
        tempId: _uuid.v4(),
        textTranslations: q.textTranslations,
        type: q.type,
        isRequired: q.isRequired,
        placeholderTranslations: q.placeholderTranslations,
        minLength: q.minLength,
        maxLength: q.maxLength,
        minSelected: q.minSelected,
        maxSelected: q.maxSelected,
        choices: q.choiceTranslations
            .map((c) => DraftChoice.create(textTranslations: c))
            .toList(),
      );

  /// Returns a copy with the supplied state changes.
  DraftQuestion copyWith({
    LocalizedText? textTranslations,
    QuestionType? type,
    bool? isRequired,
    LocalizedText? placeholderTranslations,
    int? minLength,
    int? maxLength,
    int? minSelected,
    int? maxSelected,
    List<DraftChoice>? choices,
  }) => DraftQuestion(
    tempId: tempId,
    textTranslations: textTranslations ?? this.textTranslations,
    type: type ?? this.type,
    isRequired: isRequired ?? this.isRequired,
    placeholderTranslations:
        placeholderTranslations ?? this.placeholderTranslations,
    minLength: minLength ?? this.minLength,
    maxLength: maxLength ?? this.maxLength,
    minSelected: minSelected ?? this.minSelected,
    maxSelected: maxSelected ?? this.maxSelected,
    choices: choices ?? this.choices,
  );

  /// Convert to QuestionWithChoices for server submission.
  QuestionWithChoices toQuestionWithChoices() => QuestionWithChoices(
    textTranslations: textTranslations,
    type: type,
    isRequired: isRequired,
    placeholderTranslations: placeholderTranslations,
    minLength: minLength,
    maxLength: maxLength,
    minSelected: minSelected,
    maxSelected: maxSelected,
    choiceTranslations: choices.map((c) => c.textTranslations).toList(),
  );

  /// Whether this question type uses choices.
  bool get hasChoices => type.usesChoices;

  /// The text displayed by this component.
  String get text => textTranslations.valueFor(defaultFormContentLocale);

  /// Hint text displayed when the text input is empty.
  String? get placeholder {
    final value = placeholderTranslations.valueFor(defaultFormContentLocale);
    return value.trim().isEmpty ? null : value;
  }
}
