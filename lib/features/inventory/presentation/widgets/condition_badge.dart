import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Color-coded chip displaying inventory condition status.
class ConditionBadge extends StatelessWidget {
  const ConditionBadge({
    super.key,
    required this.condition,
    required this.lang,
  });

  final String condition;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, foregroundColor) = _conditionColors(context);

    return Chip(
      label: Text(
        t(condition, lang),
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: backgroundColor,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  (Color, Color) _conditionColors(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return switch (condition) {
      'excellent' => (
          ConditionColors.excellentBackground,
          ConditionColors.excellentForeground,
        ),
      'good' => (
          ConditionColors.goodBackground,
          ConditionColors.goodForeground,
        ),
      'fair' => (
          ConditionColors.fairBackground,
          ConditionColors.fairForeground,
        ),
      'poor' => (
          ConditionColors.poorBackground,
          ConditionColors.poorForeground,
        ),
      'needs_attention' => (
          ConditionColors.needsAttentionBackground,
          ConditionColors.needsAttentionForeground,
        ),
      'critical' => (
          colors.errorContainer,
          colors.onErrorContainer,
        ),
      _ => (colors.surfaceContainerHighest, colors.onSurfaceVariant),
    };
  }
}
