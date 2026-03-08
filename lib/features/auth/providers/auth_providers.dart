import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/features/auth/data/web_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Singleton [AuthRepository] for the web dashboard.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => WebAuthRepository(),
);

/// Reactive auth state stream. Emits `null` when signed out.
final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Current signed-in user (synchronous read). May be null.
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
