import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';

class AdminSettingsSectionHeader extends StatelessWidget {
  const AdminSettingsSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.configured,
  });

  final IconData icon;
  final String title;
  final bool configured;

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

class AdminSettingsSwitchRow extends StatelessWidget {
  const AdminSettingsSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(context) => Row(
    children: [
      Expanded(child: Text(label)),
      HuxSwitch(value: value, onChanged: onChanged),
    ],
  );
}

class AdminSettingsResponsiveFields extends StatelessWidget {
  const AdminSettingsResponsiveFields({
    super.key,
    required this.children,
  });

  final List<Widget> children;

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
