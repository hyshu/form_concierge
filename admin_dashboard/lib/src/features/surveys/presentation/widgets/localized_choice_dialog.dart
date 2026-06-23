import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

import '../../../../core/localization/app_localizations.dart';
import 'localized_text_field_group.dart';

Future<void> showLocalizedChoiceDialog(
  BuildContext context, {
  required String title,
  required String primaryLocale,
  required Iterable<String> locales,
  required void Function(LocalizedText textTranslations) onSubmit,
  LocalizedText? initialText,
}) {
  final formKey = GlobalKey<FormState>();
  final controllers = {
    for (final locale in formContentLocaleCodes)
      locale: TextEditingController(text: initialText?.valueFor(locale) ?? ''),
  };

  return showDialog<void>(
    context: context,
    builder: (context) => HuxDialog(
      title: title,
      size: HuxDialogSize.medium,
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: LocalizedTextFieldGroup(
              controllers: controllers,
              primaryLocale: primaryLocale,
              locales: locales,
              labelText: context.tr('Choice text'),
              requiredMessage: context.tr('Choice text is required'),
              autofocus: initialText == null,
            ),
          ),
        ),
      ),
      actions: [
        HuxButton(
          onPressed: () => Navigator.pop(context),
          variant: HuxButtonVariant.secondary,
          child: Text(context.tr('Cancel')),
        ),
        HuxButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              onSubmit(
                localizedTextFromControllers(
                  controllers,
                  primaryLocale: primaryLocale,
                  locales: locales,
                ),
              );
              Navigator.pop(context);
            }
          },
          icon: initialText == null ? LucideIcons.plus : LucideIcons.save,
          child: Text(context.tr(initialText == null ? 'Add' : 'Save')),
        ),
      ],
    ),
  ).whenComplete(() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
  });
}
