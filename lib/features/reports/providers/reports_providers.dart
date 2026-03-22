import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Custom date range — only meaningful when [analyticsPeriodProvider] == [AnalyticsPeriod.custom].
final reportsDateRangeProvider = StateProvider<DateTimeRange?>((_) => null);

/// Which dataset tab is active on the reports screen.
/// Values: 'crops', 'harvests', 'inventory', 'purchases', 'orders'
final reportsDatasetProvider = StateProvider<String>((_) => 'crops');

/// Loading gate for export buttons to prevent double-taps.
final reportsExportLoadingProvider = StateProvider<bool>((_) => false);
