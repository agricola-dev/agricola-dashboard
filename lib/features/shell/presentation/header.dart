import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:agricola_dashboard/core/widgets/language_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final colors = Theme.of(context).colorScheme;
    final state = GoRouterState.of(context);

    // Build breadcrumbs from the current path
    final segments = state.uri.pathSegments;
    final breadcrumbs = <Widget>[];
    for (var i = 0; i < segments.length; i++) {
      if (i > 0) {
        breadcrumbs.add(
          Icon(Icons.chevron_right, size: 18, color: colors.onSurfaceVariant),
        );
      }
      final label = t(segments[i], lang);
      final isLast = i == segments.length - 1;
      breadcrumbs.add(
        Text(
          label,
          style: TextStyle(
            fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
            color: isLast ? colors.onSurface : colors.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(child: Row(children: breadcrumbs)),
          const LanguageToggle(compact: true),
        ],
      ),
    );
  }
}
