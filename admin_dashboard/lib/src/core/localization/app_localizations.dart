import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'admin_messages.g.dart';

/// Provides translated administrator interface text for a locale.
class AppLocalizations {
  /// Creates AppLocalizations with the supplied values.
  const AppLocalizations(this.locale);

  /// The locale selected for the administrator interface.
  final Locale locale;

  /// The locales supported by the administrator interface.
  static const supportedLocales = [
    Locale('en'),
    Locale('ja'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale('ko'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('th'),
    Locale('tr'),
  ];

  /// Delegates for application, Material, Cupertino, and widget translations.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// Returns the application translations associated with the build context.
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  /// Resolves a message key and substitutes values, falling back to English and then the
  /// key itself.
  String text(String key, [Map<String, Object?> values = const {}]) {
    final localeKey = _localeKey(locale);
    var result =
        adminLocalizedValues[localeKey]?[key] ??
        adminLocalizedValues['en']?[key] ??
        key;
    for (final entry in values.entries) {
      result = result.replaceAll(
        '{${entry.key}}',
        entry.value?.toString() ?? '',
      );
    }
    return result;
  }

  /// Translates an error message while preserving details after a recognized prefix.
  String message(String value) {
    for (final prefix in _errorPrefixes) {
      if (value.startsWith(prefix)) {
        return text(prefix, {'error': value.substring(prefix.length)});
      }
    }
    return text(value);
  }

  /// Selects a supported locale with Chinese script handling and English fallback.
  static Locale? localeResolutionCallback(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    if (locale == null) return const Locale('en');
    if (locale.languageCode == 'zh') {
      final country = locale.countryCode?.toUpperCase();
      final script = locale.scriptCode;
      if (script == 'Hant' ||
          country == 'TW' ||
          country == 'HK' ||
          country == 'MO') {
        return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
      }
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    }
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) return supported;
    }
    return const Locale('en');
  }

  static String _localeKey(Locale locale) {
    if (locale.languageCode == 'zh') {
      return locale.scriptCode == 'Hant' ? 'zh-Hant' : 'zh-Hans';
    }
    return locale.languageCode;
  }
}

/// Loads the administrator translations used by Flutter localization.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  /// Creates AppLocalizationsDelegate with the supplied values.
  const AppLocalizationsDelegate();

  /// Returns whether translations are available for the locale's language.
  @override
  bool isSupported(Locale locale) {
    if (locale.languageCode == 'zh') return true;
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  /// Returns translations for the selected locale synchronously.
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  /// Returns false because the delegate has no mutable translation resources.
  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// Convenient access to translations through a build context.
extension AppLocalizationsBuildContext on BuildContext {
  /// The application translations associated with this context.
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Returns translated text with the supplied placeholder values.
  String tr(String key, [Map<String, Object?> values = const {}]) =>
      l10n.text(key, values);

  /// Translates a message while retaining its error details.
  String trMessage(String value) => l10n.message(value);
}

const _errorPrefixes = [
  'Registration failed: ',
  'Failed to load config: ',
  'Failed to load surveys: ',
  'Failed to load projects: ',
  'Failed to load project: ',
  'Failed to create project: ',
  'Failed to update project: ',
  'Failed to delete project: ',
  'Failed to delete survey: ',
  'Failed to publish survey: ',
  'Failed to close survey: ',
  'Failed to reopen survey: ',
  'Failed to update web publication: ',
  'Failed to load survey: ',
  'Failed to load questions: ',
  'Failed to create question: ',
  'Failed to update question: ',
  'Failed to delete question: ',
  'Failed to reorder questions: ',
  'Failed to create choice: ',
  'Failed to update choice: ',
  'Failed to delete choice: ',
  'Failed to save visibility rules: ',
  'Failed to create survey: ',
  'Failed to update survey: ',
  'Failed to generate questions: ',
  'Failed to load results: ',
  'Failed to load responses: ',
  'Failed to export responses: ',
  'Failed to delete response: ',
  'Failed to load answers: ',
  'Failed to send reply: ',
  'Failed to load replies: ',
  'Failed to load notification settings: ',
  'Failed to load settings: ',
  'Failed to save settings: ',
  'Failed to toggle notifications: ',
  'Failed to send test notification: ',
  'Failed to load users: ',
  'Failed to create user: ',
  'Failed to update role: ',
  'Failed to delete user: ',
  'Failed to update user: ',
  'Failed to translate: ',
];
