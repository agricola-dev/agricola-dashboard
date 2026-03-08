import 'package:agricola_dashboard/features/auth/presentation/login_screen.dart';
import 'package:agricola_dashboard/features/auth/providers/auth_providers.dart';
import 'package:agricola_dashboard/features/dashboard/presentation/dashboard_screen.dart';
import 'package:agricola_dashboard/features/shell/presentation/dashboard_shell.dart';
import 'package:agricola_dashboard/routing/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RouteNames.dashboard,
    debugLogDiagnostics: true,

    // Auth redirect guard
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnLogin = state.matchedLocation == RouteNames.login;

      if (!isLoggedIn && !isOnLogin) return RouteNames.login;
      if (isLoggedIn && isOnLogin) return RouteNames.dashboard;
      return null;
    },

    routes: [
      // Login (no shell)
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // All authenticated routes wrapped in the dashboard shell
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: RouteNames.inventory,
            builder: (context, state) => const _PlaceholderPage(title: 'Inventory'),
          ),
          GoRoute(
            path: RouteNames.marketplace,
            builder: (context, state) => const _PlaceholderPage(title: 'Marketplace'),
          ),
          GoRoute(
            path: RouteNames.orders,
            builder: (context, state) => const _PlaceholderPage(title: 'Orders'),
          ),
          GoRoute(
            path: RouteNames.purchases,
            builder: (context, state) => const _PlaceholderPage(title: 'Purchases'),
          ),
          GoRoute(
            path: RouteNames.crops,
            builder: (context, state) => const _PlaceholderPage(title: 'Crops'),
          ),
          GoRoute(
            path: RouteNames.harvests,
            builder: (context, state) => const _PlaceholderPage(title: 'Harvests'),
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const _PlaceholderPage(title: 'Profile'),
          ),
        ],
      ),
    ],
  );
});

/// Placeholder for pages not yet implemented. Will be replaced in later phases.
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
