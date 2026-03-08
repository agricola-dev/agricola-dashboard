import 'package:agricola_dashboard/core/theme/app_theme.dart';
import 'package:agricola_dashboard/features/shell/presentation/mobile_redirect_screen.dart';
import 'package:agricola_dashboard/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minimum viewport width for the dashboard. Below this, show mobile redirect.
const _kMinDashboardWidth = 768.0;

class AgricolaDashboard extends ConsumerWidget {
  const AgricolaDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Agricola Dashboard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        final width = MediaQuery.sizeOf(context).width;
        if (width < _kMinDashboardWidth) {
          return const MobileRedirectScreen();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
