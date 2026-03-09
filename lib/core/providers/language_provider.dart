import 'package:agricola_core/agricola_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

const _storageKey = 'agricola_language';

/// Reads the persisted language from localStorage.
AppLanguage _readPersistedLanguage() {
  final stored = web.window.localStorage.getItem(_storageKey);
  if (stored == 'setswana') return AppLanguage.setswana;
  return AppLanguage.english;
}

/// Current app language. Persisted to localStorage.
final languageProvider =
    StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier(_readPersistedLanguage());
});

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier(super.initial);

  void setLanguage(AppLanguage language) {
    state = language;
    web.window.localStorage.setItem(_storageKey, language.name);
  }
}
