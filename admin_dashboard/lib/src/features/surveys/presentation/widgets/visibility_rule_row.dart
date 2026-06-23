import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_states.dart';

class VisibilityRuleRow extends StatelessWidget {
  const VisibilityRuleRow({
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
                child: HuxLabeledControl(
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
                child: HuxLabeledControl(
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
            _VisibilityRuleValueField(
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

class _VisibilityRuleValueField extends StatefulWidget {
  const _VisibilityRuleValueField({
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
  State<_VisibilityRuleValueField> createState() =>
      _VisibilityRuleValueFieldState();
}

class _VisibilityRuleValueFieldState extends State<_VisibilityRuleValueField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _textValue(widget.value));
  }

  @override
  void didUpdateWidget(_VisibilityRuleValueField oldWidget) {
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
      return HuxLabeledControl(
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
