import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

import '../localization/app_localizations.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;

  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'Delete',
    this.cancelLabel = 'Cancel',
  });

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
