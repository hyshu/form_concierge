import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

import '../../../../core/extensions/question_type_presentation.dart';
import '../../../../core/localization/app_localizations.dart';
import '../models/draft_question.dart';

/// Dialog for previewing AI-generated questions before applying them.
class AiQuestionPreviewDialog extends StatelessWidget {
  final List<DraftQuestion> questions;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  const AiQuestionPreviewDialog({
    super.key,
    required this.questions,
    required this.onApply,
    required this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required List<DraftQuestion> questions,
    required VoidCallback onApply,
    required VoidCallback onCancel,
  }) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AiQuestionPreviewDialog(
      questions: questions,
      onApply: onApply,
      onCancel: onCancel,
    ),
  );

  @override
  Widget build(context) => HuxDialog(
    title: context.tr('Generated Questions'),
    size: HuxDialogSize.large,
    showCloseButton: false,
    content: SizedBox(
      width: 500,
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
              '{count} questions generated. Review and apply to your survey.',
              {
                'count': questions.length,
              },
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HuxTokens.textSecondary(context),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: questions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final question = questions[index];
                return _QuestionPreviewTile(
                  index: index + 1,
                  question: question,
                );
              },
            ),
          ),
        ],
      ),
    ),
    actions: [
      HuxButton(
        onPressed: () {
          Navigator.pop(context);
          onCancel();
        },
        variant: HuxButtonVariant.secondary,
        child: Text(context.tr('Cancel')),
      ),
      HuxButton(
        onPressed: () {
          Navigator.pop(context);
          onApply();
        },
        icon: LucideIcons.check,
        child: Text(context.tr('Apply')),
      ),
    ],
  );
}

class _QuestionPreviewTile extends StatelessWidget {
  final int index;
  final DraftQuestion question;

  const _QuestionPreviewTile({
    required this.index,
    required this.question,
  });

  @override
  Widget build(context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: HuxTokens.primary(context).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$index',
              style: TextStyle(
                color: HuxTokens.primary(context),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    question.type.icon,
                    size: 16,
                    color: HuxTokens.iconSecondary(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.tr(question.type.label),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: HuxTokens.textSecondary(context),
                    ),
                  ),
                  if (question.isRequired) ...[
                    const SizedBox(width: 8),
                    HuxBadge(
                      label: context.tr('Required'),
                      variant: HuxBadgeVariant.primary,
                      size: HuxBadgeSize.small,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                question.text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (question.hasChoices && question.choices.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: question.choices.map((choice) {
                    return HuxBadge(
                      label: choice.text,
                      variant: HuxBadgeVariant.secondary,
                      size: HuxBadgeSize.small,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
