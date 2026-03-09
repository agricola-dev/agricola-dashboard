import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Color-coded chip displaying harvest quality level.
class QualityBadge extends StatelessWidget {
  const QualityBadge({
    super.key,
    required this.quality,
    required this.lang,
  });

  final String quality;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, foregroundColor) = _qualityColors(context);

    return Chip(
      label: Text(
        t(quality, lang),
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

  (Color, Color) _qualityColors(BuildContext context) {
    return switch (quality) {
      'excellent' => (
          BadgeColors.successBackground,
          BadgeColors.successForeground,
        ),
      'good' => (
          BadgeColors.positiveBackground,
          BadgeColors.positiveForeground,
        ),
      'fair' => (
          BadgeColors.warningBackground,
          BadgeColors.warningForeground,
        ),
      'poor' => (
          BadgeColors.cautionBackground,
          BadgeColors.cautionForeground,
        ),
      _ => (
          Theme.of(context).colorScheme.surfaceContainerHighest,
          Theme.of(context).colorScheme.onSurfaceVariant,
        ),
    };
  }
}
