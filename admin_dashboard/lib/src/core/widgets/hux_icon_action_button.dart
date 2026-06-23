import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

class HuxIconActionButton extends StatelessWidget {
  const HuxIconActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.destructive = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: HuxButton(
        onPressed: onPressed,
        variant: HuxButtonVariant.ghost,
        size: HuxButtonSize.small,
        icon: icon,
        textColor: destructive ? HuxTokens.textDestructive(context) : null,
        child: const SizedBox(width: 0),
      ),
    );
  }
}
