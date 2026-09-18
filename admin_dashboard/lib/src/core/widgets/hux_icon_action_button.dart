import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

/// An icon action with a tooltip and optional destructive styling.
class HuxIconActionButton extends StatelessWidget {
  /// Creates HuxIconActionButton with the supplied values.
  const HuxIconActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.destructive = false,
    this.textColor,
    this.size = HuxButtonSize.small,
  });

  /// The icon displayed alongside the content or action.
  final IconData icon;

  /// Called when the button is activated, or null to disable it.
  final VoidCallback? onPressed;

  /// The accessible text displayed when the action is hovered or focused.
  final String tooltip;

  /// Whether to use styling that indicates a destructive action or error.
  final bool destructive;

  /// An optional color override for the action's foreground.
  final Color? textColor;

  /// The size variant used by the action button.
  final HuxButtonSize size;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => MouseRegion(
    cursor: onPressed == null
        ? SystemMouseCursors.forbidden
        : SystemMouseCursors.click,
    child: Tooltip(
      message: tooltip,
      child: HuxButton(
        onPressed: onPressed,
        variant: HuxButtonVariant.ghost,
        size: size,
        icon: icon,
        textColor: onPressed == null
            ? HuxTokens.textDisabled(context)
            : textColor ??
                  (destructive ? HuxTokens.textDestructive(context) : null),
        child: const SizedBox(width: 0),
      ),
    ),
  );
}
