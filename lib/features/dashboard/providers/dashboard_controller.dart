import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/features/dashboard/providers/analytics_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available analytics periods.
enum AnalyticsPeriod {
  week('week'),
  month('month'),
  year('year'),
  all('all'),
  custom('all'); // custom range — falls back to 'all' for API (client-side filter only)

  const AnalyticsPeriod(this.value);
  final String value;
}

/// Holds the currently selected analytics period.
final analyticsPeriodProvider =
    StateProvider<AnalyticsPeriod>((_) => AnalyticsPeriod.month);

/// Fetches analytics data for the selected period.
/// Automatically refetches when the period changes.
final analyticsProvider = FutureProvider<AnalyticsModel>((ref) {
  final period = ref.watch(analyticsPeriodProvider);
  final service = ref.watch(analyticsApiServiceProvider);
  return service.getAnalytics(period: period.value);
});
