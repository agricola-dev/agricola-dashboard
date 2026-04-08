import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginControllerProvider =
    AutoDisposeAsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);

class LoginController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authRepositoryProvider).signInWithEmailPassword(
            email: email,
            password: password,
          );
      result.fold(
        (failure) => throw _AuthException(_authFailureToKey(failure.type)),
        (_) {},
      );
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(authRepositoryProvider)
          .signInWithGoogle(userType: UserType.merchant);
      result.fold(
        (failure) => throw _AuthException(_authFailureToKey(failure.type)),
        (_) {},
      );
    });
  }

  Future<bool> resetPassword(String email) async {
    final result =
        await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
    return result.fold(
      (failure) {
        state = AsyncError(
          _AuthException(_authFailureToKey(failure.type)),
          StackTrace.current,
        );
        return false;
      },
      (_) => true,
    );
  }
}

String _authFailureToKey(AuthFailureType type) => switch (type) {
      AuthFailureType.userNotFound => 'error_user_not_found',
      AuthFailureType.wrongPassword => 'error_wrong_password',
      AuthFailureType.emailAlreadyInUse => 'error_email_in_use',
      AuthFailureType.invalidEmail => 'error_invalid_email',
      AuthFailureType.weakPassword => 'error_weak_password',
      AuthFailureType.tooManyRequests => 'error_too_many_requests',
      AuthFailureType.userDisabled => 'error_account_disabled',
      AuthFailureType.invalidCredential => 'error_invalid_credential',
      AuthFailureType.networkError => 'error_auth_network',
      AuthFailureType.accountExistsWithDifferentCredential => 'error_email_in_use',
      AuthFailureType.operationNotAllowed ||
      AuthFailureType.unknown =>
        'error_auth_unknown',
    };

class _AuthException implements Exception {
  _AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
