import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';

/// Chip displaying survey status with appropriate colors.
class SurveyStatusChip extends StatelessWidget {
  /// The survey publication status displayed by the chip.
  final SurveyStatus status;

  /// Creates SurveyStatusChip with the supplied values.
  const SurveyStatusChip({super.key, required this.status});

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) {
    final (label, variant) = switch (status) {
      SurveyStatus.draft => ('Draft', HuxBadgeVariant.secondary),
      SurveyStatus.published => ('Published', HuxBadgeVariant.success),
      SurveyStatus.closed => ('Closed', HuxBadgeVariant.outline),
      SurveyStatus.archived => ('Archived', HuxBadgeVariant.secondary),
    };

    return HuxBadge(
      label: context.tr(label),
      variant: variant,
      size: HuxBadgeSize.small,
    );
  }
}
