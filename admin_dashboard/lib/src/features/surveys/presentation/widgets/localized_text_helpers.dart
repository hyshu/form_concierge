import 'package:flutter/material.dart';
import 'package:form_concierge_client/form_concierge_client.dart';

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

Map<String, TextEditingController> createLocalizedTextControllers([
  LocalizedText? initialText,
]) => {
  for (final locale in formContentLocaleCodes)
    locale: TextEditingController(text: initialText?.valueFor(locale) ?? ''),
};

void populateLocalizedTextControllers(
  Map<String, TextEditingController> controllers,
  LocalizedText text,
) {
  for (final locale in formContentLocaleCodes) {
    controllers[locale]!.text = text.values[locale] ?? '';
  }
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
