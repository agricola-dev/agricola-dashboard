import 'package:flutter/material.dart';

/// Displays a labeled section card with key-value profile information.
class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.fields,
  });

  final String title;
  final IconData icon;

  /// List of (label, value) pairs to display.
  final List<(String label, String value)> fields;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...fields.map(
              (field) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 160,
                      child: Text(
                        field.$1,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        field.$2,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays a list of items as chips (e.g., primary crops, products offered).
class ProfileChipsCard extends StatelessWidget {
  const ProfileChipsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                '—',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items
                    .map(
                      (item) => Chip(
                        label: Text(item),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
