import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

/// Builds localized text from the current values of locale-specific controllers.
LocalizedText localizedTextFromControllers(
  Map<String, TextEditingController> controllers, {
  Iterable<String> locales = formContentLocaleCodes,
}) {
  final supportedLocales = orderedFormContentLocales(locales);

  return LocalizedText({
    for (final locale in supportedLocales)
      locale: controllers[locale]?.text.trim() ?? '',
  });
}

/// Creates one text controller per supported locale, optionally filled from existing
/// text.
Map<String, TextEditingController> createLocalizedTextControllers([
  LocalizedText? initialText,
]) => {
  for (final locale in formContentLocaleCodes)
    locale: TextEditingController(text: initialText?.valueFor(locale) ?? ''),
};

/// Updates locale-specific controllers from the supplied translations.
void populateLocalizedTextControllers(
  Map<String, TextEditingController> controllers,
  LocalizedText text,
) {
  for (final locale in formContentLocaleCodes) {
    controllers[locale]!.text = text.values[locale] ?? '';
  }
}

/// Releases every controller in the locale-to-controller map.
void disposeLocalizedTextControllers(
  Map<String, TextEditingController> controllers,
) {
  for (final controller in controllers.values) {
    controller.dispose();
  }
}

/// Normalizes and orders supported locale codes using the built-in locale order.
List<String> orderedFormContentLocales(Iterable<String> locales) {
  final normalized = locales.map(normalizeFormContentLocale).toSet();
  final ordered = formContentLocaleCodes
      .where((locale) => normalized.contains(locale))
      .toList(growable: false);
  return ordered.isEmpty ? const [defaultFormContentLocale] : ordered;
}

/// Normalizes the primary locale and falls back to English if unsupported.
String normalizedPrimaryLocale(String locale) {
  final normalized = normalizeFormContentLocale(locale);
  return formContentLocaleCodes.contains(normalized)
      ? normalized
      : defaultFormContentLocale;
}
