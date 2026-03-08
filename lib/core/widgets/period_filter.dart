import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:agricola_dashboard/features/dashboard/providers/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Segmented button for selecting the analytics time period.
///
/// Bilingual labels via [t()]. Reads and writes [analyticsPeriodProvider].
class PeriodFilter extends ConsumerWidget {
  const PeriodFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final period = ref.watch(analyticsPeriodProvider);

    return SegmentedButton<AnalyticsPeriod>(
      segments: [
        ButtonSegment(
          value: AnalyticsPeriod.week,
          label: Text(t('week', lang)),
        ),
        ButtonSegment(
          value: AnalyticsPeriod.month,
          label: Text(t('month', lang)),
        ),
        ButtonSegment(
          value: AnalyticsPeriod.year,
          label: Text(t('year', lang)),
        ),
        ButtonSegment(
          value: AnalyticsPeriod.all,
          label: Text(t('all_time', lang)),
        ),
      ],
      selected: {period},
      onSelectionChanged: (selected) {
        ref.read(analyticsPeriodProvider.notifier).state = selected.first;
      },
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
