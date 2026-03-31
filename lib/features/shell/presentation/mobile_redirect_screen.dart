import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown when the viewport is too narrow (mobile devices).
/// Prompts the user to open the installed Agricola mobile app instead.
class MobileRedirectScreen extends ConsumerWidget {
  const MobileRedirectScreen({super.key});

  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.agricola.prod';

  // Android intent URL: opens app if installed, falls back to Play Store.
  // canLaunchUrl is unreliable for custom schemes in mobile browsers.
  static const _openAppUrl =
      'intent://home#Intent;scheme=agricola;package=com.agricola.prod;'
      'S.browser_fallback_url=https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dcom.agricola.prod;end';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icons/icon_square.jpg',
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                lang == AppLanguage.english
                    ? 'Dashboard is designed for\ntablet and desktop'
                    : 'Dashboard e diretswi go\ntablet le desktop',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                lang == AppLanguage.english
                    ? 'For the best experience on mobile, use the Agricola app.'
                    : 'Go itemogela sentle mo mogaleng, dirisa Agricola app.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openApp(),
                  icon: const Icon(Icons.phone_android, size: 20),
                  label: Text(
                    lang == AppLanguage.english
                        ? 'Open Agricola App'
                        : 'Bula Agricola App',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _downloadApp(),
                  icon: const Icon(Icons.download, size: 20),
                  label: Text(
                    lang == AppLanguage.english
                        ? 'Download the App'
                        : 'Tsenya App',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openApp() async {
    final uri = Uri.parse(_openAppUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _downloadApp() async {
    final uri = Uri.parse(_playStoreUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
