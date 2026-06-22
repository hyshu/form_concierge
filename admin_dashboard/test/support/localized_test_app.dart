import 'package:flutter/material.dart';
import 'package:form_concierge_flutter/src/core/localization/app_localizations.dart';

MaterialApp localizedTestApp({required Widget home, Locale? locale}) {
  return MaterialApp(
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: locale,
    localeResolutionCallback: AppLocalizations.localeResolutionCallback,
    home: home,
  );
}
