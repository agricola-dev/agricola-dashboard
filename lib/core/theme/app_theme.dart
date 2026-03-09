import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _seed = Color(0xFF2D6A4F);

  static final light = ThemeData(
    colorSchemeSeed: _seed,
    useMaterial3: true,
    brightness: Brightness.light,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
    ),
  );
}

/// The app's fixed badge color palette.
///
/// Every badge/chip in the app draws from these five semantic pairs.
/// Do NOT add new color constants — map new statuses to an existing pair.
/// For error/critical states, use `colorScheme.errorContainer` from theme.
class BadgeColors {
  BadgeColors._();

  // Success — green (e.g. excellent, delivered, produce, vegetative)
  static const successBackground = Color(0xFFE8F5E9);
  static const successForeground = Color(0xFF2E7D32);

  // Positive — teal (e.g. good, confirmed)
  static const positiveBackground = Color(0xFFE0F2F1);
  static const positiveForeground = Color(0xFF00695C);

  // Warning — amber (e.g. fair, pending, harvest ready)
  static const warningBackground = Color(0xFFFFF8E1);
  static const warningForeground = Color(0xFFE65100);

  // Caution — orange (e.g. poor, needs attention)
  static const cautionBackground = Color(0xFFFFF3E0);
  static const cautionForeground = Color(0xFFBF360C);

  // Info — purple (e.g. shipped, flowering)
  static const infoBackground = Color(0xFFF3E5F5);
  static const infoForeground = Color(0xFF6A1B9A);
}
