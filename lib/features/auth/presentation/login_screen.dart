import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:agricola_dashboard/core/utils/form_validators.dart';
import 'package:agricola_dashboard/core/widgets/app_buttons.dart';
import 'package:agricola_dashboard/core/widgets/app_text_field.dart';
import 'package:agricola_dashboard/core/widgets/labeled_divider.dart';
import 'package:agricola_dashboard/core/widgets/language_toggle.dart';
import 'package:agricola_dashboard/features/auth/providers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final loginState = ref.watch(loginControllerProvider);
    final colors = Theme.of(context).colorScheme;
    final isLoading = loginState.isLoading;

    ref.listen(loginControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BrandHeader(lang: lang),
                const SizedBox(height: 32),
                const LanguageToggle(),
                const SizedBox(height: 24),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        label: t('email', lang),
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        prefixIcon: Icons.email_outlined,
                        validator: FormValidators.email(lang),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: t('password', lang),
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        prefixIcon: Icons.lock_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: FormValidators.password(lang),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: AppTertiaryButton(
                    label: t('forgot_password', lang),
                    onPressed: isLoading ? null : () => _handleResetPassword(lang),
                  ),
                ),
                const SizedBox(height: 8),

                if (loginState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      loginState.error.toString(),
                      style: TextStyle(color: colors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),

                AppPrimaryButton(
                  label: t('sign_in', lang),
                  onPressed: isLoading ? null : _handleSignIn,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),
                LabeledDivider(label: t('or', lang)),
                const SizedBox(height: 16),
                AppSecondaryButton(
                  label: t('sign_in_with_google', lang),
                  icon: Icons.g_mobiledata,
                  onPressed: isLoading
                      ? null
                      : ref.read(loginControllerProvider.notifier).signInWithGoogle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSignIn() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(loginControllerProvider.notifier).signInWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  void _handleResetPassword(AppLanguage lang) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('enter_email_for_reset', lang))),
      );
      return;
    }
    final sent =
        await ref.read(loginControllerProvider.notifier).resetPassword(email);
    if (sent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('password_reset_sent', lang))),
      );
    }
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.lang});
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/icons/icon_square.jpg',
            width: 80,
            height: 80,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          t('app_title', lang),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          t('tagline', lang),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
