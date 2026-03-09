import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:agricola_dashboard/features/auth/providers/auth_providers.dart';
import 'package:agricola_dashboard/routing/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UserProfileTile extends ConsumerWidget {
  const UserProfileTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final lang = ref.watch(languageProvider);

    if (user == null) return const SizedBox.shrink();

    final roleLabel = user.userType == UserType.merchant
        ? t('merchant', lang)
        : t('farmer', lang);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        onTap: () => context.go(RouteNames.profile),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: CircleAvatar(
          child: Text(
            user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
          ),
        ),
        title: Text(
          user.email,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        subtitle: Text(roleLabel, style: Theme.of(context).textTheme.labelSmall),
        trailing: IconButton(
          tooltip: t('logout', lang),
          icon: const Icon(Icons.logout, size: 20),
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ),
    );
  }
}
