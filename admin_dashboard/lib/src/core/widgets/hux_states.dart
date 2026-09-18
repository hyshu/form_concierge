import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

import '../localization/app_localizations.dart';
import 'hux_icon_action_button.dart';

/// A scrollable page body with consistent width and padding.
class HuxPageBody extends StatelessWidget {
  /// Creates HuxPageBody with the supplied values.
  const HuxPageBody({
    super.key,
    required this.child,
    this.maxWidth = 960,
    this.padding = const EdgeInsets.all(24),
  });

  /// The content displayed inside this container.
  final Widget child;

  /// The maximum content width in logical pixels.
  final double maxWidth;

  /// The spacing between the container edge and its content.
  final EdgeInsetsGeometry padding;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => SingleChildScrollView(
    padding: padding,
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    ),
  );
}

/// Displays an empty-state icon, message, and optional action.
class HuxEmptyState extends StatelessWidget {
  /// Creates HuxEmptyState with the supplied values.
  const HuxEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  /// The icon displayed alongside the content or action.
  final IconData icon;

  /// The title displayed by this component.
  final String title;

  /// The message displayed to the caller or user.
  final String message;

  /// An optional action displayed below the empty-state message.
  final Widget? action;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => Center(
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

/// Displays a loading indicator with optional explanatory text.
class HuxLoadingState extends StatelessWidget {
  /// Creates HuxLoadingState with the supplied values.
  const HuxLoadingState({
    super.key,
    this.message,
    this.size = HuxLoadingSize.large,
    this.maxWidth = 960,
    this.padding = const EdgeInsets.all(24),
  });

  /// The message displayed to the caller or user.
  final String? message;

  /// The size variant used by the loading indicator.
  final HuxLoadingSize size;

  /// The maximum content width in logical pixels.
  final double maxWidth;

  /// The spacing between the container edge and its content.
  final EdgeInsetsGeometry padding;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => Padding(
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

/// Displays an error message and an optional retry action.
class HuxErrorState extends StatelessWidget {
  /// Creates HuxErrorState with the supplied values.
  const HuxErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  /// The message displayed to the caller or user.
  final String message;

  /// Called when the user requests another attempt, when provided.
  final VoidCallback? onRetry;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => Center(
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

/// Displays dismissible feedback with optional destructive styling.
class HuxMessageCard extends StatelessWidget {
  /// Creates HuxMessageCard with the supplied values.
  const HuxMessageCard({
    super.key,
    required this.icon,
    required this.message,
    this.destructive = false,
    this.onClose,
  });

  /// The icon displayed alongside the content or action.
  final IconData icon;

  /// The message displayed to the caller or user.
  final String message;

  /// Whether to use styling that indicates a destructive action or error.
  final bool destructive;

  /// Called when the user dismisses this component.
  final VoidCallback? onClose;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) {
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
            HuxIconActionButton(
              onPressed: onClose,
              icon: LucideIcons.x,
              tooltip: context.tr('Close'),
              textColor: color,
            ),
        ],
      ),
    );
  }
}

/// Displays current error and success messages with consistent spacing.
class HuxFeedbackMessages extends StatelessWidget {
  /// Creates HuxFeedbackMessages with the supplied values.
  const HuxFeedbackMessages({
    super.key,
    this.error,
    this.successMessage,
    this.onClose,
    this.spacing = 16,
  });

  /// The error message, when the operation could not complete.
  final String? error;

  /// Feedback displayed after an operation succeeds, if any.
  final String? successMessage;

  /// Called when the user dismisses this component.
  final VoidCallback? onClose;

  /// The space between adjacent child elements in logical pixels.
  final double spacing;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (error != null) ...[
        HuxMessageCard(
          icon: LucideIcons.circleAlert,
          message: context.trMessage(error!),
          destructive: true,
          onClose: onClose,
        ),
        SizedBox(height: spacing),
      ],
      if (successMessage != null) ...[
        HuxMessageCard(
          icon: LucideIcons.circleCheck,
          message: context.trMessage(successMessage!),
          onClose: onClose,
        ),
        SizedBox(height: spacing),
      ],
    ],
  );
}

/// Displays a compact icon and text pair for record metadata.
class HuxMetadataItem extends StatelessWidget {
  /// Creates HuxMetadataItem with the supplied values.
  const HuxMetadataItem({
    super.key,
    required this.icon,
    required this.text,
  });

  /// The icon displayed alongside the content or action.
  final IconData icon;

  /// The text displayed by this component.
  final String text;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) {
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

/// Displays a form label above its associated control.
class HuxLabeledControl extends StatelessWidget {
  /// Creates HuxLabeledControl with the supplied values.
  const HuxLabeledControl({
    super.key,
    required this.label,
    required this.child,
  });

  /// A human-readable label.
  final String label;

  /// The content displayed inside this container.
  final Widget child;

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: HuxTokens.textSecondary(context),
        ),
      ),
      const SizedBox(height: 6),
      SizedBox(width: double.infinity, child: child),
    ],
  );
}
