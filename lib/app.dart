import 'package:agricola_dashboard/core/theme/app_theme.dart';
import 'package:agricola_dashboard/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    );
  }
}
