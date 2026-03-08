import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown when the viewport is too narrow (mobile devices).
/// Prompts the user to open the installed Agricola mobile app instead.
class MobileRedirectScreen extends ConsumerWidget {
  const MobileRedirectScreen({super.key});

  static const _appStoreUrl = 'https://agricola-app.com/download';

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
    // Try the custom scheme first (deep link into the installed app)
    final appUri = Uri.parse('agricola://home');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to download page
      await _downloadApp();
    }
  }

  Future<void> _downloadApp() async {
    final uri = Uri.parse(_appStoreUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
