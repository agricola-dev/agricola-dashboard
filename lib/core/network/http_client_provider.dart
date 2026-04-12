import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/network/token_refresh_interceptor.dart';
import 'package:agricola_dashboard/core/network/web_auth_token_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configured Dio instance for web dashboard API calls.
final httpClientProvider = Provider<Dio>((ref) {
  final dio = Dio();

  dio.options.baseUrl = EnvironmentConfig.apiBaseUrl;
  dio.options.connectTimeout = EnvironmentConfig.apiTimeout;
  dio.options.receiveTimeout = EnvironmentConfig.apiTimeout;
  dio.options.headers['Content-Type'] = 'application/json';

  // 1. Retry interceptor (handles cold starts)
  dio.interceptors.add(RetryInterceptor(dio: dio));

  // 2. Auth interceptor (injects Firebase JWT)
  dio.interceptors.add(AuthInterceptor(WebAuthTokenProvider()));

  // 3. Token refresh interceptor (retries 401s with a fresh token)
  dio.interceptors.add(TokenRefreshInterceptor(dio));

  // 4. Log interceptor (debug only)
  if (EnvironmentConfig.enableLogging) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ),
    );
  }

  return dio;
});
