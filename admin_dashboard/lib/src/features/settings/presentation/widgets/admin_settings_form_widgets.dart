import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';

/// Displays the title and icon for an integration settings section.
class AdminSettingsSectionHeader extends StatelessWidget {
  /// Creates AdminSettingsSectionHeader with the supplied values.
  const AdminSettingsSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.configured,
  });

  /// The icon displayed alongside the content or action.
  final IconData icon;

  /// The title displayed by this component.
  final String title;

  /// Whether the integration has the settings required for use.
  final bool configured;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => Row(
    children: [
      Icon(icon, color: HuxTokens.primary(context)),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      HuxBadge(
        label: context.tr(configured ? 'Configured' : 'Not configured'),
        variant: configured
            ? HuxBadgeVariant.success
            : HuxBadgeVariant.secondary,
        size: HuxBadgeSize.small,
      ),
    ],
  );
}

/// Displays a settings toggle with its explanatory label.
class AdminSettingsSwitchRow extends StatelessWidget {
  /// Creates AdminSettingsSwitchRow with the supplied values.
  const AdminSettingsSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  /// A human-readable label.
  final String label;

  /// The current value displayed by the input.
  final bool value;

  /// Called with the updated value when the input changes.
  final ValueChanged<bool> onChanged;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => Row(
    children: [
      Expanded(child: Text(label)),
      HuxSwitch(value: value, onChanged: onChanged),
    ],
  );
}

/// Arranges settings fields to fit the available width.
class AdminSettingsResponsiveFields extends StatelessWidget {
  /// Creates AdminSettingsResponsiveFields with the supplied values.
  const AdminSettingsResponsiveFields({
    super.key,
    required this.children,
  });

  /// The child widgets displayed in order.
  final List<Widget> children;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 620) {
        return Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1) const SizedBox(height: 16),
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            Expanded(child: children[index]),
            if (index != children.length - 1) const SizedBox(width: 16),
          ],
        ],
      );
    },
  );
}
