import 'package:agricola_dashboard/features/auth/presentation/login_screen.dart';
import 'package:agricola_dashboard/features/auth/providers/auth_providers.dart';
import 'package:agricola_dashboard/features/crops/presentation/crops_screen.dart';
import 'package:agricola_dashboard/features/dashboard/presentation/dashboard_screen.dart';
import 'package:agricola_dashboard/features/harvests/presentation/harvests_screen.dart';
import 'package:agricola_dashboard/features/inventory/presentation/inventory_screen.dart';
import 'package:agricola_dashboard/features/loss_calculator/presentation/loss_calculator_screen.dart';
import 'package:agricola_dashboard/features/marketplace/presentation/marketplace_screen.dart';
import 'package:agricola_dashboard/features/orders/presentation/orders_screen.dart';
import 'package:agricola_dashboard/features/profile/presentation/profile_screen.dart';
import 'package:agricola_dashboard/features/reports/presentation/reports_screen.dart';
import 'package:agricola_dashboard/features/purchases/presentation/purchases_screen.dart';
import 'package:agricola_dashboard/features/shell/presentation/dashboard_shell.dart';
import 'package:agricola_dashboard/routing/route_names.dart';
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
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: RouteNames.marketplace,
            builder: (context, state) => const MarketplaceScreen(),
          ),
          GoRoute(
            path: RouteNames.orders,
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: RouteNames.purchases,
            builder: (context, state) => const PurchasesScreen(),
          ),
          GoRoute(
            path: RouteNames.crops,
            builder: (context, state) => const CropsScreen(),
          ),
          GoRoute(
            path: RouteNames.harvests,
            builder: (context, state) => HarvestsScreen(
              initialCropId: state.uri.queryParameters['cropId'],
            ),
          ),
          GoRoute(
            path: RouteNames.lossCalculator,
            builder: (context, state) => const LossCalculatorScreen(),
          ),
          GoRoute(
            path: RouteNames.reports,
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});