import 'package:agricola_core/agricola_core.dart';

/// Bilingual form validator factory.
///
/// Each method accepts [AppLanguage] and returns a typed validator function
/// compatible with [TextFormField.validator] / [DropdownButtonFormField.validator].
/// Length limits are sourced from [ValidationRules] constants.
class FormValidators {
  FormValidators._();

  /// Non-empty string — trims before checking.
  static String? Function(String?) required(AppLanguage lang) =>
      (v) => (v == null || v.trim().isEmpty) ? t('field_required', lang) : null;

  /// Email format: non-empty + basic RFC-ish pattern.
  static String? Function(String?) email(AppLanguage lang) => (v) {
        if (v == null || v.trim().isEmpty) return t('email_required', lang);
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
          return t('email_invalid', lang);
        }
        return null;
      };

  /// Password: non-empty, min 6 chars (Firebase minimum).
  static String? Function(String?) password(AppLanguage lang) => (v) {
        if (v == null || v.trim().isEmpty) return t('password_required', lang);
        if (v.trim().length < 6) return t('password_too_short', lang);
        return null;
      };

  /// Required positive number (double > 0).
  static String? Function(String?) positiveNumber(AppLanguage lang) => (v) {
        if (v == null || v.trim().isEmpty) return t('field_required', lang);
        final n = double.tryParse(v.trim());
        if (n == null) return t('number_invalid', lang);
        if (n <= 0) return t('number_positive', lang);
        return null;
      };

  /// Optional positive number — empty is valid; validates format/sign if present.
  static String? Function(String?) optionalPositiveNumber(AppLanguage lang) =>
      (v) {
        if (v == null || v.trim().isEmpty) return null;
        final n = double.tryParse(v.trim());
        if (n == null) return t('number_invalid', lang);
        if (n < 0) return t('number_positive', lang);
        return null;
      };

  /// Business name length using [ValidationRules] constants.
  static String? Function(String?) businessName(AppLanguage lang) => (v) {
        if (v == null || v.trim().isEmpty) return t('field_required', lang);
        final s = v.trim();
        if (s.length < ValidationRules.minBusinessNameLength) {
          return t('name_too_short', lang);
        }
        if (s.length > ValidationRules.maxBusinessNameLength) {
          return t('name_too_long', lang);
        }
        return null;
      };

  /// Village/location name length using [ValidationRules] constants.
  static String? Function(String?) village(AppLanguage lang) => (v) {
        if (v == null || v.trim().isEmpty) return t('field_required', lang);
        final s = v.trim();
        if (s.length < ValidationRules.minVillageLength) {
          return t('village_too_short', lang);
        }
        if (s.length > ValidationRules.maxVillageLength) {
          return t('village_too_long', lang);
        }
        return null;
      };
}
