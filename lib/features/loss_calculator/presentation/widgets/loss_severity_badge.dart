import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Color-coded chip displaying loss severity level.
class LossSeverityBadge extends StatelessWidget {
  const LossSeverityBadge({
    super.key,
    required this.lossPercentage,
    required this.lang,
  });

  final double lossPercentage;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final severityKey = lossSeverityKey(lossPercentage);
    final (backgroundColor, foregroundColor) = _severityColors(context);

    return Chip(
      label: Text(
        t(severityKey, lang),
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

  (Color, Color) _severityColors(BuildContext context) {
    final key = lossSeverityKey(lossPercentage);
    return switch (key) {
      'loss_severity_low' => (
          BadgeColors.successBackground,
          BadgeColors.successForeground,
        ),
      'loss_severity_moderate' => (
          BadgeColors.warningBackground,
          BadgeColors.warningForeground,
        ),
      'loss_severity_high' => (
          BadgeColors.cautionBackground,
          BadgeColors.cautionForeground,
        ),
      _ => (
          Theme.of(context).colorScheme.errorContainer,
          Theme.of(context).colorScheme.onErrorContainer,
        ),
    };
  }
}
