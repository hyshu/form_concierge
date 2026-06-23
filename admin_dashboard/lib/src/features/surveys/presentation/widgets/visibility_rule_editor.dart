import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';

class VisibilityRuleEditor extends StatefulWidget {
  const VisibilityRuleEditor({
    super.key,
    required this.surveyId,
    required this.targetQuestion,
    required this.primaryLocale,
    required this.sourceQuestions,
    required this.choicesByQuestion,
    required this.rules,
    required this.enabled,
    required this.onSave,
  });

  final int surveyId;
  final Question targetQuestion;
  final String primaryLocale;
  final List<Question> sourceQuestions;
  final Map<int, List<Choice>> choicesByQuestion;
  final List<QuestionVisibilityRule> rules;
  final bool enabled;
  final Future<void> Function({
    required VisibilityConditionMode mode,
    required List<QuestionVisibilityRule> rules,
  })
  onSave;

  @override
  State<VisibilityRuleEditor> createState() => _VisibilityRuleEditorState();
}

class _VisibilityRuleEditorState extends State<VisibilityRuleEditor> {
  late VisibilityConditionMode _mode;
  late List<QuestionVisibilityRule> _rules;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.targetQuestion.visibilityConditionMode;
    _rules = List<QuestionVisibilityRule>.from(widget.rules);
  }

  @override
  void didUpdateWidget(VisibilityRuleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rules != widget.rules ||
        oldWidget.targetQuestion.visibilityConditionMode !=
            widget.targetQuestion.visibilityConditionMode) {
      _mode = widget.targetQuestion.visibilityConditionMode;
      _rules = List<QuestionVisibilityRule>.from(widget.rules);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      leading: Icon(LucideIcons.workflow, color: HuxTokens.primary(context)),
      title: Text(
        context.tr('Visibility rules'),
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(
        _rules.isEmpty
            ? context.tr('Always visible')
            : context.tr(
                _rules.length == 1 ? '{count} rule' : '{count} rules',
                {'count': _rules.length},
              ),
      ),
      children: [
        if (widget.sourceQuestions.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.tr('Add an earlier question before creating rules.'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HuxTokens.textSecondary(context),
              ),
            ),
          )
        else ...[
          SizedBox(
            width: 220,
            child: HuxDropdown<VisibilityConditionMode>(
              value: _mode,
              useItemWidgetAsValue: true,
              enabled: widget.enabled,
              items: [
                HuxDropdownItem(
                  value: VisibilityConditionMode.all,
                  child: Text(context.tr('All')),
                ),
                HuxDropdownItem(
                  value: VisibilityConditionMode.any,
                  child: Text(context.tr('Any')),
                ),
              ],
              onChanged: (value) => setState(() => _mode = value),
            ),
          ),
          const SizedBox(height: 12),
          ..._rules.asMap().entries.map((entry) {
            return _RuleRow(
              key: ValueKey('visibility_rule_${entry.key}'),
              surveyId: widget.surveyId,
              rule: entry.value,
              primaryLocale: widget.primaryLocale,
              sourceQuestions: widget.sourceQuestions,
              choicesByQuestion: widget.choicesByQuestion,
              enabled: widget.enabled && !_isSaving,
              onChanged: (rule) => _replaceRule(entry.key, rule),
              onDelete: () => _deleteRule(entry.key),
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              HuxButton(
                onPressed: widget.enabled && !_isSaving ? _addRule : null,
                variant: HuxButtonVariant.outline,
                icon: LucideIcons.plus,
                child: Text(context.tr('Add rule')),
              ),
              const Spacer(),
              HuxButton(
                onPressed: widget.enabled && !_isSaving ? _save : null,
                isLoading: _isSaving,
                icon: LucideIcons.save,
                child: Text(context.tr('Save rules')),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _addRule() {
    final source = widget.sourceQuestions.first;
    final sourceId = source.id!;
    final firstChoice = _firstOrNull(widget.choicesByQuestion[sourceId]);
    setState(() {
      _rules = [
        ..._rules,
        QuestionVisibilityRule(
          surveyId: widget.surveyId,
          targetQuestionId: widget.targetQuestion.id!,
          sourceQuestionId: sourceId,
          operator: firstChoice == null
              ? VisibilityOperator.isAnswered
              : VisibilityOperator.equals,
          value: firstChoice?.id,
        ),
      ];
    });
  }

  void _replaceRule(int index, QuestionVisibilityRule rule) {
    setState(() {
      _rules = [
        for (var i = 0; i < _rules.length; i++)
          if (i == index) rule else _rules[i],
      ];
    });
  }

  void _deleteRule(int index) {
    setState(() {
      _rules = [
        for (var i = 0; i < _rules.length; i++)
          if (i != index) _rules[i],
      ];
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(mode: _mode, rules: _rules);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    super.key,
    required this.surveyId,
    required this.rule,
    required this.primaryLocale,
    required this.sourceQuestions,
    required this.choicesByQuestion,
    required this.enabled,
    required this.onChanged,
    required this.onDelete,
  });

  final int surveyId;
  final QuestionVisibilityRule rule;
  final String primaryLocale;
  final List<Question> sourceQuestions;
  final Map<int, List<Choice>> choicesByQuestion;
  final bool enabled;
  final ValueChanged<QuestionVisibilityRule> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final source = sourceQuestions.firstWhere(
      (question) => question.id == rule.sourceQuestionId,
      orElse: () => sourceQuestions.first,
    );
    final operators = _operatorsFor(source);

    return HuxCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      backgroundColor: HuxTokens.surfaceSecondary(context),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _LabeledControl(
                  label: context.tr('Question'),
                  child: HuxDropdown<int>(
                    value: source.id,
                    useItemWidgetAsValue: true,
                    enabled: enabled,
                    items: [
                      for (final question in sourceQuestions)
                        HuxDropdownItem(
                          value: question.id!,
                          child: Text(
                            question.textFor(primaryLocale),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      final nextSource = sourceQuestions.firstWhere(
                        (question) => question.id == value,
                      );
                      onChanged(_forSource(nextSource));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LabeledControl(
                  label: context.tr('Condition'),
                  child: HuxDropdown<VisibilityOperator>(
                    value: operators.contains(rule.operator)
                        ? rule.operator
                        : operators.first,
                    useItemWidgetAsValue: true,
                    enabled: enabled,
                    items: [
                      for (final operator in operators)
                        HuxDropdownItem(
                          value: operator,
                          child: Text(context.tr(_operatorLabel(operator))),
                        ),
                    ],
                    onChanged: (operator) {
                      onChanged(
                        rule.copyWith(
                          operator: operator,
                          value: _operatorNeedsValue(operator)
                              ? rule.value
                              : null,
                          clearValue: !_operatorNeedsValue(operator),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: context.tr('Delete rule'),
                child: HuxButton(
                  onPressed: enabled ? onDelete : null,
                  variant: HuxButtonVariant.ghost,
                  size: HuxButtonSize.small,
                  icon: LucideIcons.trash2,
                  textColor: HuxTokens.textDestructive(context),
                  child: const SizedBox(width: 0),
                ),
              ),
            ],
          ),
          if (_operatorNeedsValue(rule.operator)) ...[
            const SizedBox(height: 8),
            _ValueField(
              source: source,
              value: rule.value,
              choices: choicesByQuestion[source.id] ?? const [],
              primaryLocale: primaryLocale,
              enabled: enabled,
              onChanged: (value) => onChanged(rule.copyWith(value: value)),
            ),
          ],
        ],
      ),
    );
  }

  QuestionVisibilityRule _forSource(Question source) {
    final choices = choicesByQuestion[source.id] ?? const [];
    final operator = source.type.usesChoices && choices.isNotEmpty
        ? VisibilityOperator.equals
        : VisibilityOperator.isAnswered;
    return QuestionVisibilityRule(
      surveyId: surveyId,
      targetQuestionId: rule.targetQuestionId,
      sourceQuestionId: source.id!,
      operator: operator,
      value: operator == VisibilityOperator.equals ? choices.first.id : null,
    );
  }
}

class _LabeledControl extends StatelessWidget {
  const _LabeledControl({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: HuxTokens.textSecondary(context),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(width: double.infinity, child: child),
      ],
    );
  }
}

class _ValueField extends StatefulWidget {
  const _ValueField({
    required this.source,
    required this.value,
    required this.choices,
    required this.primaryLocale,
    required this.enabled,
    required this.onChanged,
  });

  final Question source;
  final Object? value;
  final List<Choice> choices;
  final String primaryLocale;
  final bool enabled;
  final ValueChanged<Object?> onChanged;

  @override
  State<_ValueField> createState() => _ValueFieldState();
}

class _ValueFieldState extends State<_ValueField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _textValue(widget.value));
  }

  @override
  void didUpdateWidget(_ValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = _textValue(widget.value);
    if (oldWidget.value != widget.value && _controller.text != nextText) {
      _controller.text = nextText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.source.type.usesChoices) {
      final choiceIds = widget.choices
          .map((choice) => choice.id)
          .whereType<int>();
      final current = widget.value is int ? widget.value as int : null;
      return _LabeledControl(
        label: context.tr('Choice'),
        child: HuxDropdown<int>(
          value: choiceIds.contains(current) ? current : null,
          useItemWidgetAsValue: true,
          enabled: widget.enabled,
          items: [
            for (final choice in widget.choices)
              HuxDropdownItem(
                value: choice.id!,
                child: Text(choice.textFor(widget.primaryLocale)),
              ),
          ],
          onChanged: widget.onChanged,
        ),
      );
    }
    return HuxInput(
      controller: _controller,
      enabled: widget.enabled,
      label: context.tr('Value'),
      onChanged: widget.onChanged,
    );
  }

  String _textValue(Object? value) => value is String ? value : '';
}

List<VisibilityOperator> _operatorsFor(Question source) {
  if (source.type.usesTextAnswer) {
    return const [
      VisibilityOperator.equals,
      VisibilityOperator.notEquals,
      VisibilityOperator.contains,
      VisibilityOperator.notContains,
      VisibilityOperator.isAnswered,
      VisibilityOperator.isNotAnswered,
    ];
  }
  return const [
    VisibilityOperator.equals,
    VisibilityOperator.notEquals,
    VisibilityOperator.isAnswered,
    VisibilityOperator.isNotAnswered,
  ];
}

bool _operatorNeedsValue(VisibilityOperator operator) {
  return operator != VisibilityOperator.isAnswered &&
      operator != VisibilityOperator.isNotAnswered;
}

String _operatorLabel(VisibilityOperator operator) {
  return switch (operator) {
    VisibilityOperator.equals => 'equals',
    VisibilityOperator.notEquals => 'does not equal',
    VisibilityOperator.contains => 'contains',
    VisibilityOperator.notContains => 'does not contain',
    VisibilityOperator.isAnswered => 'is answered',
    VisibilityOperator.isNotAnswered => 'is not answered',
  };
}

T? _firstOrNull<T>(List<T>? values) {
  if (values == null || values.isEmpty) return null;
  return values.first;
}
