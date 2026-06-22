import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';
import 'package:hux/hux.dart';

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
        _LocalizedField(
          controller: controllers[primary],
          label: _localizedLabel(labelText, primary),
          hint: hintText,
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
              _LocalizedField(
                controller: controllers[locale],
                label: _localizedLabel(labelText, locale),
                hint: hintText,
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

class _LocalizedField extends StatelessWidget {
  const _LocalizedField({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.maxLines,
    this.hint,
    this.textInputAction,
    this.autofocus = false,
    this.validator,
  });

  final TextEditingController? controller;
  final String label;
  final bool enabled;
  final int maxLines;
  final String? hint;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    if (maxLines > 1) {
      return HuxTextarea(
        controller: controller,
        label: label,
        hint: hint,
        enabled: enabled,
        minLines: maxLines,
        maxLines: maxLines + 2,
        textInputAction: textInputAction,
        validator: validator,
      );
    }

    return HuxInput(
      controller: controller,
      label: label,
      hint: hint,
      enabled: enabled,
      textInputAction: textInputAction,
      validator: validator,
    );
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
