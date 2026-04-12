import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Intercepts 401 responses to attempt a silent token refresh and retry.
///
/// Firebase ID tokens expire after 1 hour. If the server returns 401 and
/// a current Firebase user exists, this interceptor:
///   1. Force-refreshes the ID token (updates Firebase SDK cache).
///   2. Retries the original request once (AuthInterceptor re-injects the
///      fresh token on retry).
///   3. If the retry still returns 401 (session truly invalid), signs the
///      user out — triggering idTokenChanges() → GoRouter redirects to /login.
class TokenRefreshInterceptor extends Interceptor {
  final Dio _dio;

  TokenRefreshInterceptor(this._dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Guard: prevent infinite retry loop.
    if (err.requestOptions.extra['_tokenRefreshed'] == true) {
      await FirebaseAuth.instance.signOut();
      return handler.next(err);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return handler.next(err);
    }

    try {
      // Force-refresh updates Firebase SDK's internal token cache.
      // AuthInterceptor.onRequest will call getIdToken() again on retry,
      // which reads the fresh cached token.
      await user.getIdToken(true);

      final options = err.requestOptions;
      options.extra['_tokenRefreshed'] = true;

      final response = await _dio.fetch(options);
      return handler.resolve(response);
    } catch (_) {
      // Refresh failed (revoked session, network error, etc.).
      // Sign out so idTokenChanges() emits null → router → /login.
      await FirebaseAuth.instance.signOut();
      return handler.next(err);
    }
  }
}
