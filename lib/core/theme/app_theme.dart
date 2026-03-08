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

/// Centralized semantic colors for inventory condition levels.
///
/// Each condition has a background and foreground pair for consistent
/// badge/chip rendering. Defined here so all condition-related UI
/// draws from one source.
class ConditionColors {
  ConditionColors._();

  // Excellent — green
  static const excellentBackground = Color(0xFFE8F5E9);
  static const excellentForeground = Color(0xFF2E7D32);

  // Good — teal
  static const goodBackground = Color(0xFFE0F2F1);
  static const goodForeground = Color(0xFF00695C);

  // Fair — amber
  static const fairBackground = Color(0xFFFFF8E1);
  static const fairForeground = Color(0xFFE65100);

  // Poor — orange
  static const poorBackground = Color(0xFFFFF3E0);
  static const poorForeground = Color(0xFFBF360C);

  // Needs attention — deep orange
  static const needsAttentionBackground = Color(0xFFFBE9E7);
  static const needsAttentionForeground = Color(0xFFBF360C);

  // Critical — uses theme error tokens (passed in at call site)
}
