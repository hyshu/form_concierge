import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

class HuxIconActionButton extends StatelessWidget {
  const HuxIconActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.destructive = false,
    this.textColor,
    this.size = HuxButtonSize.small,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool destructive;
  final Color? textColor;
  final HuxButtonSize size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: HuxButton(
        onPressed: onPressed,
        variant: HuxButtonVariant.ghost,
        size: size,
        icon: icon,
        textColor:
            textColor ??
            (destructive ? HuxTokens.textDestructive(context) : null),
        child: const SizedBox(width: 0),
      ),
    );
  }
}
