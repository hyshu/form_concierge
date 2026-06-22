import 'package:flutter/material.dart';
import 'package:hux/hux.dart';

/// Application theme configuration backed by Hux UI.
abstract final class AppTheme {
  static ThemeData light() {
    return HuxTheme.lightTheme.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: HuxTheme.lightTheme.appBarTheme.copyWith(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    return HuxTheme.darkTheme.copyWith(
      appBarTheme: HuxTheme.darkTheme.appBarTheme.copyWith(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
