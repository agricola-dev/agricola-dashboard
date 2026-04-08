import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

const _storageKey = 'agricola_language';

bool _isSetswana() {
  try {
    return web.window.localStorage.getItem(_storageKey) == 'setswana';
  } catch (_) {
    return false;
  }
}

/// Full-page branded error screen shown when an unhandled widget error occurs.
///
/// Used as the [ErrorWidget.builder] override in main(). Reads the user's
/// language preference directly from localStorage (cannot use Riverpod here
/// since this widget may render outside the ProviderScope).
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, this.details});

  final FlutterErrorDetails? details;

  @override
  Widget build(BuildContext context) {
    final setswana = _isSetswana();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: colors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  setswana ? 'Go ne le mathata' : 'Something went wrong',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  setswana
                      ? 'Bothata jo bo sa lebelelwang bo diragetswe. Tswelela go leka gape.'
                      : 'An unexpected error occurred. Please reload to continue.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (kDebugMode && details != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 600),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      details!.exceptionAsString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onErrorContainer,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => web.window.location.reload(),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(setswana ? 'Leka Gape' : 'Reload Page'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
