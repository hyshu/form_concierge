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

/// A condition referencing stable local question and choice identifiers.
class DraftVisibilityRule {
  /// The stable local identifier of the earlier source question.
  final String sourceQuestionTempId;

  /// The comparison applied to the earlier answer.
  final VisibilityOperator operator;

  /// Expected text or the stable local identifier of a source choice.
  final String? value;

  /// Creates an unsaved visibility condition.
  const DraftVisibilityRule({
    required this.sourceQuestionTempId,
    required this.operator,
    this.value,
  });
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

  /// Whether all visibility rules or any one rule must match.
  final VisibilityConditionMode visibilityConditionMode;

  /// Conditions referencing earlier draft questions by stable local identifiers.
  final List<DraftVisibilityRule> visibilityRules;

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
    this.visibilityConditionMode = VisibilityConditionMode.all,
    this.visibilityRules = const [],
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
    VisibilityConditionMode visibilityConditionMode =
        VisibilityConditionMode.all,
    List<DraftVisibilityRule> visibilityRules = const [],
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
      visibilityConditionMode: visibilityConditionMode,
      visibilityRules: visibilityRules,
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
        visibilityConditionMode: q.visibilityConditionMode,
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
    VisibilityConditionMode? visibilityConditionMode,
    List<DraftVisibilityRule>? visibilityRules,
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
    visibilityConditionMode:
        visibilityConditionMode ?? this.visibilityConditionMode,
    visibilityRules: visibilityRules ?? this.visibilityRules,
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
    visibilityConditionMode: visibilityConditionMode,
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

/// Supplies local question and choice identifiers to the shared rule controls.
class DraftVisibilityContext {
  /// The current ordered draft questions.
  final List<DraftQuestion> questions;

  /// The position of the question being added or edited.
  final int targetIndex;

  /// Creates a context without persisting any draft data.
  const DraftVisibilityContext(this.questions, this.targetIndex);

  /// Earlier questions available to the rule controls.
  List<Question> get sourceQuestions => [
    for (var index = 0; index < targetIndex; index++)
      Question(
        id: index + 1,
        surveyId: 0,
        textTranslations: questions[index].textTranslations,
        type: questions[index].type,
        orderIndex: index,
        isRequired: questions[index].isRequired,
        placeholderTranslations: questions[index].placeholderTranslations,
      ),
  ];

  /// Source choices with temporary positional identifiers for the controls.
  Map<int, List<Choice>> get choicesByQuestion => {
    for (var index = 0; index < targetIndex; index++)
      index + 1: [
        for (var choice = 0; choice < questions[index].choices.length; choice++)
          Choice(
            id: choice + 1,
            questionId: index + 1,
            textTranslations: questions[index].choices[choice].textTranslations,
            orderIndex: choice,
          ),
      ],
  };

  /// Converts stable draft references for display in the shared rule controls.
  List<QuestionVisibilityRule> toEditorRules(
    List<DraftVisibilityRule> rules,
  ) => [
    for (final rule in rules)
      QuestionVisibilityRule(
        surveyId: 0,
        targetQuestionId: targetIndex + 1,
        sourceQuestionId: _sourceIndex(rule) + 1,
        operator: rule.operator,
        value:
            questions[_sourceIndex(rule)].type.usesChoices && rule.value != null
            ? questions[_sourceIndex(rule)].choices.indexWhere(
                    (choice) => choice.tempId == rule.value,
                  ) +
                  1
            : rule.value,
      ),
  ];

  /// Converts edited controls back to stable draft references.
  List<DraftVisibilityRule> fromEditorRules(
    List<QuestionVisibilityRule> rules,
  ) => [
    for (final rule in rules)
      DraftVisibilityRule(
        sourceQuestionTempId: questions[rule.sourceQuestionId - 1].tempId,
        operator: rule.operator,
        value: rule.value == null
            ? null
            : questions[rule.sourceQuestionId - 1].type.usesChoices
            ? questions[rule.sourceQuestionId - 1]
                  .choices[(rule.value as int) - 1]
                  .tempId
            : rule.value as String,
      ),
  ];

  /// Resolves stable draft references for the single survey creation request.
  List<SurveyVisibilityRuleInput> toCreationRules(
    List<DraftVisibilityRule> rules,
  ) => [
    for (final rule in rules)
      SurveyVisibilityRuleInput(
        targetQuestionIndex: targetIndex,
        sourceQuestionIndex: _sourceIndex(rule),
        operator: rule.operator,
        textValue: questions[_sourceIndex(rule)].type.usesTextAnswer
            ? rule.value
            : null,
        choiceIndex:
            questions[_sourceIndex(rule)].type.usesChoices && rule.value != null
            ? questions[_sourceIndex(rule)].choices.indexWhere(
                (choice) => choice.tempId == rule.value,
              )
            : null,
      ),
  ];

  int _sourceIndex(DraftVisibilityRule rule) => questions.indexWhere(
    (question) => question.tempId == rule.sourceQuestionTempId,
  );
}
