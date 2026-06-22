import 'package:flutter/material.dart';
import 'package:form_concierge_flutter/src/core/localization/app_localizations.dart';

MaterialApp localizedTestApp({required Widget home}) {
  return MaterialApp(
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    localeResolutionCallback: AppLocalizations.localeResolutionCallback,
    home: home,
  );
}
