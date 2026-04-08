import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin wrapper around [FirebaseAnalytics] for the four event types tracked
/// by the dashboard: page views, CTA clicks, scroll depth, and referral
/// sources (auto-captured by the GA4 JS SDK — no extra work needed).
class AnalyticsService {
  const AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  Future<void> logPageView(String screenName) =>
      _analytics.logScreenView(screenName: screenName);

  Future<void> logCtaClick({
    required String ctaName,
    required String screen,
  }) =>
      _analytics.logEvent(
        name: 'cta_click',
        parameters: <String, Object>{'cta_name': ctaName, 'screen': screen},
      );

  Future<void> logScrollDepth({
    required int depthPercent,
    required String screen,
  }) =>
      _analytics.logEvent(
        name: 'scroll_depth',
        parameters: <String, Object>{
          'depth_percent': depthPercent,
          'screen': screen,
        },
      );
}
