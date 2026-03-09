import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:agricola_dashboard/features/auth/providers/auth_providers.dart';
import 'package:agricola_dashboard/features/shell/presentation/user_profile_tile.dart';
import 'package:agricola_dashboard/routing/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Navigation items shown in the sidebar, filtered by user role.
class _NavItem {
  const _NavItem({
    required this.route,
    required this.icon,
    required this.labelKey,
    this.roles = const {UserType.merchant, UserType.farmer},
  });

  final String route;
  final IconData icon;
  final String labelKey;
  final Set<UserType> roles;
}

final _navItems = [
  const _NavItem(
    route: RouteNames.dashboard,
    icon: Icons.dashboard_outlined,
    labelKey: 'dashboard',
  ),
  const _NavItem(
    route: RouteNames.inventory,
    icon: Icons.inventory_2_outlined,
    labelKey: 'inventory',
  ),
  const _NavItem(
    route: RouteNames.marketplace,
    icon: Icons.storefront_outlined,
    labelKey: 'marketplace',
  ),
  const _NavItem(
    route: RouteNames.orders,
    icon: Icons.receipt_long_outlined,
    labelKey: 'orders',
    roles: {UserType.merchant, UserType.farmer},
  ),
  const _NavItem(
    route: RouteNames.purchases,
    icon: Icons.shopping_cart_outlined,
    labelKey: 'purchases',
    roles: {UserType.merchant},
  ),
  const _NavItem(
    route: RouteNames.crops,
    icon: Icons.grass_outlined,
    labelKey: 'crops',
    roles: {UserType.farmer},
  ),
  const _NavItem(
    route: RouteNames.harvests,
    icon: Icons.agriculture_outlined,
    labelKey: 'harvests',
    roles: {UserType.farmer},
  ),
  const _NavItem(
    route: RouteNames.lossCalculator,
    icon: Icons.calculate_outlined,
    labelKey: 'loss_calculator',
    roles: {UserType.farmer},
  ),
];

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final user = ref.watch(currentUserProvider);
    final colors = Theme.of(context).colorScheme;
    final currentPath = GoRouterState.of(context).uri.path;

    final visibleItems = _navItems
        .where((item) => user == null || item.roles.contains(user.userType))
        .toList();

    return Container(
      width: 260,
      color: colors.surfaceContainerLow,
      child: Column(
        children: [
          // Brand header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              children: [
                Icon(Icons.eco, color: colors.primary, size: 32),
                const SizedBox(width: 10),
                Text(
                  t('app_title', lang),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                ),
              ],
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          const SizedBox(height: 8),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: visibleItems.length,
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                final isActive = currentPath == item.route;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selected: isActive,
                    selectedTileColor: colors.primaryContainer,
                    leading: Icon(
                      item.icon,
                      color: isActive ? colors.onPrimaryContainer : null,
                    ),
                    title: Text(
                      t(item.labelKey, lang),
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.w600 : null,
                        color: isActive ? colors.onPrimaryContainer : null,
                      ),
                    ),
                    onTap: isActive ? null : () => context.go(item.route),
                  ),
                );
              },
            ),
          ),

          // User profile tile at bottom
          const Divider(indent: 16, endIndent: 16),
          const UserProfileTile(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
