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
        (failure) => throw _AuthException(failure.message),
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
        (failure) => throw _AuthException(failure.message),
        (_) {},
      );
    });
  }

  Future<bool> resetPassword(String email) async {
    final result =
        await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) => true,
    );
  }
}

class _AuthException implements Exception {
  _AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
