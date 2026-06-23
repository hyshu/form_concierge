import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import 'visibility_rule_row.dart';

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
            return VisibilityRuleRow(
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

T? _firstOrNull<T>(List<T>? values) {
  if (values == null || values.isEmpty) return null;
  return values.first;
}
