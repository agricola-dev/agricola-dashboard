import 'package:agricola_core/agricola_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current app language. Defaults to English.
final languageProvider = StateProvider<AppLanguage>(
  (ref) => AppLanguage.english,
);
