import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

class HuxIconTooltipButton extends StatelessWidget {
  const HuxIconTooltipButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.textColor,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: HuxButton(
        onPressed: onPressed,
        variant: HuxButtonVariant.ghost,
        size: HuxButtonSize.small,
        icon: icon,
        textColor: textColor,
        child: const SizedBox(width: 0),
      ),
    );
  }
}
