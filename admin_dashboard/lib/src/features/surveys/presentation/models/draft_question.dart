import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A draft choice before being saved to the server.
class DraftChoice {
  final String tempId;
  final LocalizedText textTranslations;

  const DraftChoice({
    required this.tempId,
    required this.textTranslations,
  });

  factory DraftChoice.create({required LocalizedText textTranslations}) =>
      DraftChoice(
        tempId: _uuid.v4(),
        textTranslations: textTranslations,
      );

  DraftChoice copyWith({LocalizedText? textTranslations}) => DraftChoice(
    tempId: tempId,
    textTranslations: textTranslations ?? this.textTranslations,
  );

  String get text => textTranslations.valueFor(defaultFormContentLocale);
}

/// A draft question before being saved to the server.
class DraftQuestion {
  final String tempId;
  final LocalizedText textTranslations;
  final QuestionType type;
  final bool isRequired;
  final LocalizedText placeholderTranslations;
  final int? minLength;
  final int? maxLength;
  final int? minSelected;
  final int? maxSelected;
  final List<DraftChoice> choices;

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

  String get text => textTranslations.valueFor(defaultFormContentLocale);

  String? get placeholder {
    final value = placeholderTranslations.valueFor(defaultFormContentLocale);
    return value.trim().isEmpty ? null : value;
  }
}
