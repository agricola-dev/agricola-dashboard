import 'package:agricola_core/agricola_core.dart';
import 'package:flutter/material.dart';

/// Displays a formatted price with optional unit, or "Price on request".
class PriceDisplay extends StatelessWidget {
  const PriceDisplay({
    super.key,
    required this.price,
    required this.unit,
    required this.lang,
  });

  final double? price;
  final String? unit;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (price == null) {
      return Text(
        t('price_on_request', lang),
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final priceText = 'P ${price!.toStringAsFixed(2)}';
    final display = unit != null ? '$priceText / $unit' : priceText;

    return Text(
      display,
      style: TextStyle(
        color: colors.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
