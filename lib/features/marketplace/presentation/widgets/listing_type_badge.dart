import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Color-coded chip displaying listing type (produce / supplies).
class ListingTypeBadge extends StatelessWidget {
  const ListingTypeBadge({
    super.key,
    required this.type,
    required this.lang,
  });

  final ListingType type;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, foregroundColor) = switch (type) {
      ListingType.produce => (
          ListingTypeColors.produceBackground,
          ListingTypeColors.produceForeground,
        ),
      ListingType.supplies => (
          ListingTypeColors.suppliesBackground,
          ListingTypeColors.suppliesForeground,
        ),
    };

    return Chip(
      label: Text(
        t(type.name, lang),
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
}
