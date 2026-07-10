import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/hux_icon_action_button.dart';

class SurveyActionButtons extends StatelessWidget {
  const SurveyActionButtons({
    super.key,
    this.onPublish,
    this.onClose,
    this.onReopen,
    required this.onViewResponses,
    this.onDelete,
  });

  final VoidCallback? onPublish;
  final VoidCallback? onClose;
  final VoidCallback? onReopen;
  final VoidCallback onViewResponses;
  final VoidCallback? onDelete;

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
