import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/network/http_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides an [AnalyticsApiService] backed by the authenticated Dio client.
final analyticsApiServiceProvider = Provider<AnalyticsApiService>((ref) {
  return AnalyticsApiService(ref.watch(httpClientProvider));
});
