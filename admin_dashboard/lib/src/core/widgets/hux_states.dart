import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

import '../localization/app_localizations.dart';

class HuxPageBody extends StatelessWidget {
  const HuxPageBody({
    super.key,
    required this.child,
    this.maxWidth = 960,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

class HuxEmptyState extends StatelessWidget {
  const HuxEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: HuxCard(
        size: HuxCardSize.large,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: HuxTokens.iconSecondary(context)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: HuxTokens.textSecondary(context)),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class HuxLoadingState extends StatelessWidget {
  const HuxLoadingState({
    super.key,
    this.message,
    this.size = HuxLoadingSize.large,
    this.maxWidth = 960,
    this.padding = const EdgeInsets.all(24),
  });

  final String? message;
  final HuxLoadingSize size;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactWidth = maxWidth < 280 ? maxWidth : 280.0;
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth.clamp(0.0, compactWidth).toDouble()
              : compactWidth;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: HuxCard(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HuxLoading(size: size),
                      if (message != null && message!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: HuxTokens.textSecondary(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class HuxErrorState extends StatelessWidget {
  const HuxErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: HuxCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: 40,
              color: HuxTokens.textDestructive(context),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: HuxTokens.textDestructive(context)),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              HuxButton(
                onPressed: onRetry,
                variant: HuxButtonVariant.secondary,
                child: Text(context.tr('Retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HuxMessageCard extends StatelessWidget {
  const HuxMessageCard({
    super.key,
    required this.icon,
    required this.message,
    this.destructive = false,
    this.onClose,
  });

  final IconData icon;
  final String message;
  final bool destructive;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? HuxTokens.textDestructive(context)
        : HuxTokens.textSuccess(context);
    return HuxCard(
      backgroundColor: destructive
          ? HuxTokens.surfaceDestructive(context)
          : HuxTokens.surfaceSuccess(context),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          ),
          if (onClose != null)
            HuxButton(
              onPressed: onClose,
              variant: HuxButtonVariant.ghost,
              size: HuxButtonSize.small,
              icon: LucideIcons.x,
              textColor: color,
              child: const SizedBox(width: 0),
            ),
        ],
      ),
    );
  }
}

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

class HuxMetadataItem extends StatelessWidget {
  const HuxMetadataItem({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = HuxTokens.textSecondary(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
