import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

class VisibilityRuleEditor extends StatefulWidget {
  const VisibilityRuleEditor({
    super.key,
    required this.surveyId,
    required this.targetQuestion,
    required this.sourceQuestions,
    required this.choicesByQuestion,
    required this.rules,
    required this.enabled,
    required this.onSave,
  });

  final int surveyId;
  final Question targetQuestion;
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
    final colorScheme = Theme.of(context).colorScheme;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      leading: Icon(Icons.account_tree_outlined, color: colorScheme.primary),
      title: Text(
        'Visibility rules',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(
        _rules.isEmpty
            ? 'Always visible'
            : '${_rules.length} ${_rules.length == 1 ? 'rule' : 'rules'}',
      ),
      children: [
        if (widget.sourceQuestions.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Add an earlier question before creating rules.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          SegmentedButton<VisibilityConditionMode>(
            segments: const [
              ButtonSegment(
                value: VisibilityConditionMode.all,
                label: Text('All'),
              ),
              ButtonSegment(
                value: VisibilityConditionMode.any,
                label: Text('Any'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: widget.enabled
                ? (selection) => setState(() => _mode = selection.first)
                : null,
          ),
          const SizedBox(height: 12),
          ..._rules.asMap().entries.map((entry) {
            return _RuleRow(
              key: ValueKey('visibility_rule_${entry.key}'),
              surveyId: widget.surveyId,
              rule: entry.value,
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
              OutlinedButton.icon(
                onPressed: widget.enabled && !_isSaving ? _addRule : null,
                icon: const Icon(Icons.add),
                label: const Text('Add rule'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: widget.enabled && !_isSaving ? _save : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save rules'),
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
    required this.sourceQuestions,
    required this.choicesByQuestion,
    required this.enabled,
    required this.onChanged,
    required this.onDelete,
  });

  final int surveyId;
  final QuestionVisibilityRule rule;
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  initialValue: source.id,
                  decoration: const InputDecoration(labelText: 'Question'),
                  items: [
                    for (final question in sourceQuestions)
                      DropdownMenuItem(
                        value: question.id,
                        child: Text(
                          question.text,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: enabled
                      ? (value) {
                          final nextSource = sourceQuestions.firstWhere(
                            (question) => question.id == value,
                          );
                          onChanged(_forSource(nextSource));
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<VisibilityOperator>(
                  initialValue: operators.contains(rule.operator)
                      ? rule.operator
                      : operators.first,
                  decoration: const InputDecoration(labelText: 'Condition'),
                  items: [
                    for (final operator in operators)
                      DropdownMenuItem(
                        value: operator,
                        child: Text(_operatorLabel(operator)),
                      ),
                  ],
                  onChanged: enabled
                      ? (operator) {
                          if (operator == null) return;
                          onChanged(
                            rule.copyWith(
                              operator: operator,
                              value: _operatorNeedsValue(operator)
                                  ? rule.value
                                  : null,
                              clearValue: !_operatorNeedsValue(operator),
                            ),
                          );
                        }
                      : null,
                ),
              ),
              IconButton(
                onPressed: enabled ? onDelete : null,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete rule',
              ),
            ],
          ),
          if (_operatorNeedsValue(rule.operator)) ...[
            const SizedBox(height: 8),
            _ValueField(
              source: source,
              value: rule.value,
              choices: choicesByQuestion[source.id] ?? const [],
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

class _ValueField extends StatelessWidget {
  const _ValueField({
    required this.source,
    required this.value,
    required this.choices,
    required this.enabled,
    required this.onChanged,
  });

  final Question source;
  final Object? value;
  final List<Choice> choices;
  final bool enabled;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (source.type.usesChoices) {
      final choiceIds = choices.map((choice) => choice.id).whereType<int>();
      final current = value == null ? null : int.tryParse(value.toString());
      return DropdownButtonFormField<int>(
        initialValue: choiceIds.contains(current)
            ? current
            : _firstOrNull(choices)?.id,
        decoration: const InputDecoration(labelText: 'Choice'),
        items: [
          for (final choice in choices)
            DropdownMenuItem(value: choice.id, child: Text(choice.text)),
        ],
        onChanged: enabled ? onChanged : null,
      );
    }
    return TextFormField(
      initialValue: value?.toString() ?? '',
      enabled: enabled,
      decoration: const InputDecoration(labelText: 'Value'),
      onChanged: onChanged,
    );
  }
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
