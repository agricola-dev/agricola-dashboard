import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Color-coded chip displaying crop growth stage.
class CropStageBadge extends StatelessWidget {
  const CropStageBadge({
    super.key,
    required this.stage,
    required this.lang,
  });

  final String stage;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, foregroundColor) = _stageColors(context);

    return Chip(
      label: Text(
        t(stage.toLowerCase().replaceAll(' ', '_'), lang),
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

  (Color, Color) _stageColors(BuildContext context) {
    return switch (stage) {
      'Vegetative' => (
          BadgeColors.successBackground,
          BadgeColors.successForeground,
        ),
      'Flowering' => (
          BadgeColors.infoBackground,
          BadgeColors.infoForeground,
        ),
      'Harvest Ready' => (
          BadgeColors.warningBackground,
          BadgeColors.warningForeground,
        ),
      _ => (
          Theme.of(context).colorScheme.surfaceContainerHighest,
          Theme.of(context).colorScheme.onSurfaceVariant,
        ),
    };
  }
}
