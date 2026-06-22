import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

import '../../../../core/localization/app_localizations.dart';

class LocalizedTextFieldGroup extends StatelessWidget {
  const LocalizedTextFieldGroup({
    super.key,
    required this.controllers,
    required this.primaryLocale,
    required this.labelText,
    this.hintText,
    this.enabled = true,
    this.maxLines = 1,
    this.requiredMessage,
    this.textInputAction,
    this.autofocus = false,
  });

  final Map<String, TextEditingController> controllers;
  final String primaryLocale;
  final String labelText;
  final String? hintText;
  final bool enabled;
  final int maxLines;
  final String? requiredMessage;
  final TextInputAction? textInputAction;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final primary = normalizedPrimaryLocale(primaryLocale);
    final secondaryLocales = formContentLocaleCodes
        .where((locale) => locale != primary)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controllers[primary],
          decoration: InputDecoration(
            labelText: _localizedLabel(labelText, primary),
            hintText: hintText,
          ),
          enabled: enabled,
          maxLines: maxLines,
          textInputAction: textInputAction,
          autofocus: autofocus,
          validator: requiredMessage == null
              ? null
              : (value) {
                  if (value == null || value.trim().isEmpty) {
                    return requiredMessage;
                  }
                  return null;
                },
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: Text(
            context.tr('Other languages'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          children: [
            for (final locale in secondaryLocales) ...[
              TextFormField(
                controller: controllers[locale],
                decoration: InputDecoration(
                  labelText: _localizedLabel(labelText, locale),
                  hintText: hintText,
                ),
                enabled: enabled,
                maxLines: maxLines,
                textInputAction: textInputAction,
              ),
              if (locale != secondaryLocales.last) const SizedBox(height: 12),
            ],
          ],
        ),
      ],
    );
  }

  String _localizedLabel(String label, String locale) {
    return '$label (${formContentLocaleLabels[locale]!})';
  }
}

LocalizedText localizedTextFromControllers(
  Map<String, TextEditingController> controllers, {
  required String primaryLocale,
  bool fallbackEmptyToPrimary = true,
}) {
  final primary = normalizedPrimaryLocale(primaryLocale);
  final primaryValue = controllers[primary]?.text.trim() ?? '';

  return LocalizedText({
    for (final locale in formContentLocaleCodes)
      locale: _localizedControllerValue(
        controllers[locale]?.text.trim() ?? '',
        primaryValue: primaryValue,
        fallbackEmptyToPrimary: fallbackEmptyToPrimary,
      ),
  });
}

String normalizedPrimaryLocale(String locale) {
  final normalized = normalizeFormContentLocale(locale);
  return formContentLocaleCodes.contains(normalized)
      ? normalized
      : defaultFormContentLocale;
}

String _localizedControllerValue(
  String value, {
  required String primaryValue,
  required bool fallbackEmptyToPrimary,
}) {
  if (value.isNotEmpty) return value;
  return fallbackEmptyToPrimary ? primaryValue : '';
}
