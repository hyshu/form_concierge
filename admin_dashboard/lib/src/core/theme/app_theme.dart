import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

/// Application theme configuration backed by Hux UI.
abstract final class AppTheme {
  /// Builds the administrator application's light theme.
  static ThemeData light() => HuxTheme.lightTheme.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: HuxTheme.lightTheme.appBarTheme.copyWith(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );

  /// Builds the administrator application's dark theme.
  static ThemeData dark() => HuxTheme.darkTheme.copyWith(
    appBarTheme: HuxTheme.darkTheme.appBarTheme.copyWith(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}
