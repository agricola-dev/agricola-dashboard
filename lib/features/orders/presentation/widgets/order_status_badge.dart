import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Color-coded chip displaying order status.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({
    super.key,
    required this.status,
    required this.lang,
  });

  final String status;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, foregroundColor) = _statusColors(context);

    return Chip(
      label: Text(
        t(status, lang),
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

  (Color, Color) _statusColors(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return switch (status) {
      'pending' => (
          BadgeColors.warningBackground,
          BadgeColors.warningForeground,
        ),
      'confirmed' => (
          BadgeColors.positiveBackground,
          BadgeColors.positiveForeground,
        ),
      'shipped' => (
          BadgeColors.infoBackground,
          BadgeColors.infoForeground,
        ),
      'delivered' => (
          BadgeColors.successBackground,
          BadgeColors.successForeground,
        ),
      'cancelled' => (
          colors.errorContainer,
          colors.onErrorContainer,
        ),
      _ => (colors.surfaceContainerHighest, colors.onSurfaceVariant),
    };
  }
}
