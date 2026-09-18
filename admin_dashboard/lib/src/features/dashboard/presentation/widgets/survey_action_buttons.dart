import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_icon_action_button.dart';

/// Displays the survey actions permitted by its current status and user role.
class SurveyActionButtons extends StatelessWidget {
  /// Creates SurveyActionButtons with the supplied values.
  const SurveyActionButtons({
    super.key,
    this.onPublish,
    this.onClose,
    this.onReopen,
    this.onViewResponses,
    this.onDelete,
  });

  /// Called when the user requests publication of the survey.
  final VoidCallback? onPublish;

  /// Called when the user requests closing the survey to new responses.
  final VoidCallback? onClose;

  /// Called when the user requests reopening of the survey.
  final VoidCallback? onReopen;

  /// Called when the user opens the survey's response results.
  final VoidCallback? onViewResponses;

  /// Called when the user requests deletion of this item.
  final VoidCallback? onDelete;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (onPublish != null)
        HuxIconActionButton(
          icon: LucideIcons.upload,
          onPressed: onPublish,
          tooltip: context.tr('Publish'),
        ),
      if (onClose != null)
        HuxIconActionButton(
          icon: LucideIcons.circleStop,
          onPressed: onClose,
          tooltip: context.tr('Close'),
        ),
      if (onReopen != null)
        HuxIconActionButton(
          icon: LucideIcons.circlePlay,
          onPressed: onReopen,
          tooltip: context.tr('Reopen'),
        ),
      if (onViewResponses != null)
        HuxIconActionButton(
          icon: LucideIcons.chartNoAxesColumn,
          onPressed: onViewResponses,
          tooltip: context.tr('View Responses'),
        ),
      if (onDelete != null)
        HuxIconActionButton(
          icon: LucideIcons.trash2,
          onPressed: onDelete,
          tooltip: context.tr('Delete'),
          destructive: true,
        ),
    ],
  );
}
