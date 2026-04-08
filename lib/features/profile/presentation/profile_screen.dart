import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:agricola_dashboard/features/auth/providers/auth_providers.dart';
import 'package:agricola_dashboard/features/profile/presentation/profile_form_dialog.dart';
import 'package:agricola_dashboard/features/profile/presentation/widgets/profile_info_card.dart';
import 'package:agricola_dashboard/features/profile/providers/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final profileAsync = ref.watch(profileControllerProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: t('error_try_again', lang),
        onRetry: () => ref.invalidate(profileControllerProvider),
        lang: lang,
      ),
      data: (profile) => _ProfileContent(profile: profile, lang: lang),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile content
// ---------------------------------------------------------------------------

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile, required this.lang});

  final DisplayableProfile profile;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, ref, textTheme, colors),
          const SizedBox(height: 32),

          // Profile avatar + basic info
          _buildProfileHeader(context, textTheme, colors),
          const SizedBox(height: 24),

          // Role-specific details
          if (profile is MinimalProfile)
            _buildIncompleteProfileCard(context, ref, colors)
          else ...[
            _buildRoleDetails(context),
            const SizedBox(height: 24),
            _buildChipsSection(context),
          ],

          const SizedBox(height: 32),

          // Account section
          _buildAccountSection(context, ref, textTheme, colors),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    TextTheme textTheme,
    ColorScheme colors,
  ) {
    return Row(
      children: [
        Text(
          t('your_profile', lang),
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const Spacer(),
        if (profile is! MinimalProfile)
          FilledButton.icon(
            onPressed: () => _editProfile(context, ref),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(t('edit_profile', lang)),
          ),
      ],
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colors,
  ) {
    final roleLabel = profile.userType == UserType.merchant
        ? t('merchant', lang)
        : t('farmer', lang);

    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage:
              profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
          child: profile.photoUrl == null
              ? Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName[0].toUpperCase()
                      : '?',
                  style: textTheme.headlineMedium,
                )
              : null,
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile.displayName,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.email,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(roleLabel),
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
              backgroundColor: colors.primary.withValues(alpha: 0.08),
              labelStyle: textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIncompleteProfileCard(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colors,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
      ),
      color: colors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.person_add_outlined, size: 48, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              t('complete_profile', lang),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              t('complete_profile_hint', lang),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _createProfile(context, ref),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(t('complete_profile', lang)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDetails(BuildContext context) {
    return switch (profile) {
      CompleteFarmerProfile(:final farmerData) => ProfileInfoCard(
          title: t('farm_details', lang),
          icon: Icons.agriculture_outlined,
          fields: [
            (t('village', lang), farmerData.displayLocation),
            (t('farm_size', lang), farmerData.farmSize),
          ],
        ),
      CompleteMerchantProfile(:final merchantData) => ProfileInfoCard(
          title: t('business_details', lang),
          icon: Icons.storefront_outlined,
          fields: [
            (t('business_name', lang), merchantData.businessName),
            (t('merchant_type', lang), merchantData.merchantType.displayName),
            (t('location', lang), merchantData.displayLocation),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildChipsSection(BuildContext context) {
    return switch (profile) {
      CompleteFarmerProfile(:final farmerData) => ProfileChipsCard(
          title: t('primary_crops', lang),
          icon: Icons.eco_outlined,
          items: farmerData.primaryCrops,
        ),
      CompleteMerchantProfile(:final merchantData) => ProfileChipsCard(
          title: t('products_offered', lang),
          icon: Icons.inventory_2_outlined,
          items: merchantData.productsOffered,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildAccountSection(
    BuildContext context,
    WidgetRef ref,
    TextTheme textTheme,
    ColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('account', lang),
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        // Change password
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: ListTile(
            leading: Icon(Icons.lock_outline, color: colors.onSurfaceVariant),
            title: Text(t('change_password', lang)),
            subtitle: Text(
              t('password_reset_message', lang),
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _sendPasswordReset(context, ref),
          ),
        ),
        const SizedBox(height: 12),

        // Language preference
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: ListTile(
            leading: Icon(Icons.language, color: colors.onSurfaceVariant),
            title: Text(t('language', lang)),
            subtitle: Text(
              lang == AppLanguage.english ? 'English' : 'Setswana',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            trailing: SegmentedButton<AppLanguage>(
              segments: const [
                ButtonSegment(value: AppLanguage.english, label: Text('EN')),
                ButtonSegment(value: AppLanguage.setswana, label: Text('SW')),
              ],
              selected: {lang},
              onSelectionChanged: (selected) {
                ref.read(languageProvider.notifier).setLanguage(selected.first);
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Danger zone — delete account
        Text(
          t('danger_zone', lang),
          style: textTheme.titleSmall?.copyWith(
            color: colors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.error.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: colors.error),
            title: Text(
              t('delete_account', lang),
              style: TextStyle(color: colors.error),
            ),
            subtitle: Text(
              t('delete_permanent_warning', lang),
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: colors.error),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    switch (profile) {
      case CompleteFarmerProfile(:final farmerData):
        final result = await showFarmerProfileFormDialog(
          context,
          lang: lang,
          userId: user.uid,
          profile: farmerData,
        );
        if (result == null || !context.mounted) return;
        final error = await ref
            .read(profileControllerProvider.notifier)
            .updateFarmerProfile(farmerData.id, result);
        if (!context.mounted) return;
        _showResult(context, error, 'profile_updated');

      case CompleteMerchantProfile(:final merchantData):
        final result = await showMerchantProfileFormDialog(
          context,
          lang: lang,
          userId: user.uid,
          profile: merchantData,
        );
        if (result == null || !context.mounted) return;
        final error = await ref
            .read(profileControllerProvider.notifier)
            .updateMerchantProfile(merchantData.id, result);
        if (!context.mounted) return;
        _showResult(context, error, 'profile_updated');

      default:
        break;
    }
  }

  Future<void> _createProfile(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    if (user.userType == UserType.farmer) {
      final result = await showFarmerProfileFormDialog(
        context,
        lang: lang,
        userId: user.uid,
      );
      if (result == null || !context.mounted) return;
      final error = await ref
          .read(profileControllerProvider.notifier)
          .createFarmerProfile(result);
      if (!context.mounted) return;
      _showResult(context, error, 'profile_complete');
    } else {
      final result = await showMerchantProfileFormDialog(
        context,
        lang: lang,
        userId: user.uid,
        merchantType: user.merchantType,
      );
      if (result == null || !context.mounted) return;
      final error = await ref
          .read(profileControllerProvider.notifier)
          .createMerchantProfile(result);
      if (!context.mounted) return;
      _showResult(context, error, 'profile_complete');
    }
  }

  Future<void> _sendPasswordReset(BuildContext context, WidgetRef ref) async {
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.sendPasswordResetEmail(profile.email);

    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('error_auth_unknown', lang)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('password_reset_sent', lang))),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteAccountDialog(
        email: profile.email,
        lang: lang,
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Delete backend profile first (if exists)
    final profileId = switch (profile) {
      CompleteFarmerProfile(:final farmerData) => farmerData.id,
      CompleteMerchantProfile(:final merchantData) => merchantData.id,
      _ => null,
    };

    if (profileId != null) {
      final error = await ref
          .read(profileControllerProvider.notifier)
          .deleteProfile(profileId);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(error, lang)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

    // Delete Firebase account — auth stream will redirect to login
    if (!context.mounted) return;
    final authRepo = ref.read(authRepositoryProvider);
    final result = await authRepo.deleteAccount();
    if (!context.mounted) return;
    result.fold(
      (failure) {
        // requires-recent-login: tell user to sign out and sign in again
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('error_auth_unknown', lang)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      (_) {
        // Auth stream handles redirect to login
      },
    );
  }

  void _showResult(BuildContext context, String? error, String successKey) {
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(t(error, lang)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(t(successKey, lang))),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Delete account confirmation dialog
// ---------------------------------------------------------------------------

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.email, required this.lang});

  final String email;
  final AppLanguage lang;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _matches = _controller.text == widget.email);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(t('delete_account', widget.lang)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('delete_account_warning', widget.lang),
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              t('type_email_to_confirm', widget.lang),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.email,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t('cancel', widget.lang)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.error),
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(t('delete_account_confirm', widget.lang)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error view
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.lang,
  });

  final String message;
  final VoidCallback onRetry;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.error),
          const SizedBox(height: 16),
          Text(
            t('error', lang),
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(t('retry', lang)),
          ),
        ],
      ),
    );
  }
}
