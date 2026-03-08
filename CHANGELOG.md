# Changelog

## 0.1.0 — 2026-03-08

### Phase 0: Project Setup & Foundation
- Create Flutter Web project (`agricola-dashboard`, web-only)
- Add `agricola_core` as path dependency for shared models, services, i18n
- Firebase Web SDK setup (same Firebase project as mobile app)
- Web-specific `AuthTokenProvider` implementing core's abstract interface
- Dio `httpClientProvider` with retry, auth, and logging interceptors
- Environment config via core's `EnvironmentConfig` (auto dev/prod switching)
- Riverpod `ProviderScope` in `main.dart`
- GitHub Actions CI/CD workflow with FTP deploy to Namecheap hosting
