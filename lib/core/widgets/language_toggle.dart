import 'package:agricola_core/agricola_core.dart';
import 'package:agricola_dashboard/core/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reusable language toggle between English and Setswana.
///
/// [compact] uses short labels (EN/SW) and smaller sizing — suited for headers.
/// Default uses full labels (English/Setswana) — suited for forms.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);

    return SegmentedButton<AppLanguage>(
      segments: [
        ButtonSegment(
          value: AppLanguage.english,
          label: Text(compact ? 'EN' : t('english', lang)),
        ),
        ButtonSegment(
          value: AppLanguage.setswana,
          label: Text(compact ? 'SW' : t('setswana', lang)),
        ),
      ],
      selected: {lang},
      onSelectionChanged: (selected) {
        ref.read(languageProvider.notifier).setLanguage(selected.first);
      },
      style: compact
          ? const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : null,
    );
  }
}
