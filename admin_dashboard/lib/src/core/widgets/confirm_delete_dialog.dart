import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

import '../localization/app_localizations.dart';

/// Asks the user to confirm a destructive action.
class ConfirmDeleteDialog extends StatelessWidget {
  /// The title displayed by this component.
  final String title;

  /// The explanation displayed in the confirmation dialog.
  final String content;

  /// The label used for the confirmation action.
  final String confirmLabel;

  /// The label used for the cancellation action.
  final String cancelLabel;

  /// Creates ConfirmDeleteDialog with the supplied values.
  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'Delete',
    this.cancelLabel = 'Cancel',
  });

  /// Displays the confirmation dialog and returns true only when deletion is confirmed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDeleteDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    );
    return result ?? false;
  }

  /// Builds the widget tree for the current input and state.
  @override
  Widget build(context) => HuxDialog(
    title: title,
    variant: HuxDialogVariant.destructive,
    size: HuxDialogSize.small,
    showCloseButton: false,
    content: Text(content),
    actions: [
      HuxButton(
        onPressed: () => Navigator.pop(context, false),
        variant: HuxButtonVariant.secondary,
        child: Text(context.tr(cancelLabel)),
      ),
      HuxButton(
        onPressed: () => Navigator.pop(context, true),
        variant: HuxButtonVariant.primary,
        primaryColor: HuxTokens.textDestructive(context),
        child: Text(context.tr(confirmLabel)),
      ),
    ],
  );
}
