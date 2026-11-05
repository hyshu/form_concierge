import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import 'visibility_rule_row.dart';

enum _VisibilityMatch { always, all, any }

/// Edits visibility conditions locally as part of a question form.
class QuestionVisibilityFields extends StatelessWidget {
  /// Creates rule controls whose changes are saved with the question.
  const QuestionVisibilityFields({
    super.key,
    required this.sourceQuestions,
    required this.choicesByQuestion,
    required this.rules,
    required this.mode,
    required this.primaryLocale,
    required this.onModeChanged,
    required this.onRulesChanged,
    this.error,
  });

  /// Earlier questions available as condition sources.
  final List<Question> sourceQuestions;

  /// Source choices indexed by the identifiers used in these controls.
  final Map<int, List<Choice>> choicesByQuestion;

  /// The unsaved visibility conditions.
  final List<QuestionVisibilityRule> rules;

  /// Whether all conditions or any condition must match.
  final VisibilityConditionMode mode;

  /// The main language used to display questions and choices.
  final String primaryLocale;

  /// Called when the condition combination changes.
  final ValueChanged<VisibilityConditionMode> onModeChanged;

  /// Called with the complete edited condition list.
  final ValueChanged<List<QuestionVisibilityRule>> onRulesChanged;

  /// A validation error shown beside the condition controls.
  final String? error;

  /// Builds the condition selector and its editable rule rows.
  @override
  Widget build(BuildContext context) {
    if (sourceQuestions.isEmpty) {
      return Text(context.tr('The first question is always visible.'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HuxDropdown<_VisibilityMatch>(
          value: rules.isEmpty
              ? _VisibilityMatch.always
              : mode == VisibilityConditionMode.any
              ? _VisibilityMatch.any
              : _VisibilityMatch.all,
          useItemWidgetAsValue: true,
          items: [
            HuxDropdownItem(
              value: _VisibilityMatch.always,
              child: Text(context.tr('Always visible')),
            ),
            HuxDropdownItem(
              value: _VisibilityMatch.all,
              child: Text(context.tr('When all conditions match')),
            ),
            HuxDropdownItem(
              value: _VisibilityMatch.any,
              child: Text(context.tr('When any condition matches')),
            ),
          ],
          onChanged: (value) {
            if (value == _VisibilityMatch.always) {
              onModeChanged(VisibilityConditionMode.all);
              onRulesChanged(const []);
            } else {
              onModeChanged(
                value == _VisibilityMatch.any
                    ? VisibilityConditionMode.any
                    : VisibilityConditionMode.all,
              );
              if (rules.isEmpty) onRulesChanged([_newRule()]);
            }
          },
        ),
        if (rules.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (var index = 0; index < rules.length; index++)
            VisibilityRuleRow(
              key: ValueKey('question_visibility_rule_$index'),
              surveyId: 0,
              rule: rules[index],
              primaryLocale: primaryLocale,
              sourceQuestions: sourceQuestions,
              choicesByQuestion: choicesByQuestion,
              enabled: true,
              onChanged: (rule) => onRulesChanged([
                for (var i = 0; i < rules.length; i++)
                  if (i == index) rule else rules[i],
              ]),
              onDelete: () => onRulesChanged([
                for (var i = 0; i < rules.length; i++)
                  if (i != index) rules[i],
              ]),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: HuxButton(
              variant: HuxButtonVariant.outline,
              icon: LucideIcons.plus,
              onPressed: () => onRulesChanged([...rules, _newRule()]),
              child: Text(context.tr('Add rule')),
            ),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            context.tr(error!),
            style: TextStyle(color: HuxTokens.textDestructive(context)),
          ),
        ],
      ],
    );
  }

  QuestionVisibilityRule _newRule() {
    final source = sourceQuestions.first;
    final choices = choicesByQuestion[source.id] ?? const [];
    return QuestionVisibilityRule(
      surveyId: 0,
      targetQuestionId: 0,
      sourceQuestionId: source.id!,
      operator: source.type.usesChoices && choices.isNotEmpty
          ? VisibilityOperator.equals
          : VisibilityOperator.isAnswered,
      value: source.type.usesChoices && choices.isNotEmpty
          ? choices.first.id
          : null,
    );
  }
}
