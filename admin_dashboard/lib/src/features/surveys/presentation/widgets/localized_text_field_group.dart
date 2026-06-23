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
    this.locales = formContentLocaleCodes,
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
  final Iterable<String> locales;
  final String? hintText;
  final bool enabled;
  final int maxLines;
  final String? requiredMessage;
  final TextInputAction? textInputAction;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final supportedLocales = orderedFormContentLocales(locales);
    final normalizedPrimary = normalizedPrimaryLocale(primaryLocale);
    final primary = supportedLocales.contains(normalizedPrimary)
        ? normalizedPrimary
        : supportedLocales.first;
    final secondaryLocales = supportedLocales
        .where((locale) => locale != primary)
        .toList();

    String? requiredValidator(String? value) {
      if (requiredMessage != null && (value == null || value.trim().isEmpty)) {
        return requiredMessage;
      }
      return null;
    }

    Widget fieldFor(String locale, {TextInputAction? action}) {
      return _LocalizedField(
        controller: controllers[locale],
        label: _localizedLabel(labelText, locale),
        hint: hintText,
        enabled: enabled,
        maxLines: maxLines,
        textInputAction: action ?? textInputAction,
        autofocus: locale == primary && autofocus,
        validator: requiredMessage == null ? null : requiredValidator,
      );
    }

    final primaryField = fieldFor(primary);

    if (secondaryLocales.isEmpty) {
      return primaryField;
    }

    if (requiredMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primaryField,
          for (final locale in secondaryLocales) ...[
            const SizedBox(height: 12),
            fieldFor(locale),
          ],
        ],
      );
    }

    if (secondaryLocales.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primaryField,
          const SizedBox(height: 12),
          fieldFor(secondaryLocales.single),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        primaryField,
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
              fieldFor(locale),
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
  Iterable<String> locales = formContentLocaleCodes,
}) {
  final supportedLocales = orderedFormContentLocales(locales);

  return LocalizedText({
    for (final locale in supportedLocales)
      locale: controllers[locale]?.text.trim() ?? '',
  });
}

Map<String, TextEditingController> createLocalizedTextControllers([
  LocalizedText? initialText,
]) {
  return {
    for (final locale in formContentLocaleCodes)
      locale: TextEditingController(text: initialText?.valueFor(locale) ?? ''),
  };
}

void disposeLocalizedTextControllers(
  Map<String, TextEditingController> controllers,
) {
  for (final controller in controllers.values) {
    controller.dispose();
  }
}

List<String> orderedFormContentLocales(Iterable<String> locales) {
  final normalized = locales.map(normalizeFormContentLocale).toSet();
  final ordered = formContentLocaleCodes
      .where((locale) => normalized.contains(locale))
      .toList(growable: false);
  return ordered.isEmpty ? const [defaultFormContentLocale] : ordered;
}

String normalizedPrimaryLocale(String locale) {
  final normalized = normalizeFormContentLocale(locale);
  return formContentLocaleCodes.contains(normalized)
      ? normalized
      : defaultFormContentLocale;
}
