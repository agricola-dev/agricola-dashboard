# Changelog

## 0.6.0 — 2026-03-08

### Phase 4: Marketplace Listings (Merchant)
- Two-tab marketplace screen: "My Listings" DataTable + "Browse Marketplace" responsive card grid
- Full CRUD via MarketplaceFormDialog: title, description, type (produce/supplies), category, price, unit, quantity, location, crop status, harvest date
- MyListingsController (AsyncNotifier) with create, update, delete operations filtered by current user
- BrowseListingsController with MarketplaceFilter support (search, type, category, price range)
- Search filtering and sortable columns (title, price, created date) on My Listings
- Browse filter bar with type dropdown and clear filters action
- ListingTypeBadge widget with centralized ListingTypeColors in app_theme.dart
- PriceDisplay widget showing formatted price with unit or "Price on request"
- "List on Marketplace" action button on inventory rows — pre-fills listing form from inventory item
- Browse grid adapts columns based on viewport width (1/2/3 columns)
- ListingCard widget with title, type badge, description, price, location, and seller info
- Empty state, loading state, and error state with retry on both tabs
- Wired marketplace route replacing placeholder in app_router.dart
- Added 14 bilingual translation keys to agricola_core (marketplace labels, filters, form fields)

## 0.5.0 — 2026-03-08

### Phase 3: Inventory Management (Merchant)
- Full CRUD inventory screen with DataTable (crop type, quantity, unit, condition, storage location, days in storage)
- Add/edit inventory dialog using shared AppTextField, AppDropdownField, and date picker widgets
- InventoryController (AsyncNotifier) with create, update, delete operations and error handling
- Real-time search filtering by crop type, storage location, and condition
- Sortable table columns (crop type, quantity, storage date)
- ConditionBadge widget with centralized ConditionColors in app_theme.dart
- Delete confirmation dialog with bilingual support
- Empty state, loading state, and error state with retry
- Wired inventory route replacing placeholder in app_router.dart

## 0.4.0 — 2026-03-08

### Features
- Restrict dashboard to tablet/desktop viewports (768px minimum width)
- Mobile visitors see a redirect screen prompting them to open or download the Agricola app
- Bilingual support (English/Setswana) on the mobile redirect screen
- Added url_launcher dependency for deep-linking into the native app

## 0.3.1 — 2026-03-08

### Bug Fixes
- Replace generic leaf icon with real Agricola logo on login screen
- Fix Google Sign-In by adding web OAuth client ID meta tag to index.html

## 0.3.0 — 2026-03-08

### Phase 2: Dashboard Stats
- Dashboard screen with role-based stat cards (merchant: inventory, listings, orders, revenue, purchases, suppliers; farmer: crops, harvests, yield, loss, inventory, field size)
- Analytics provider layer using core's AnalyticsApiService (GET /api/v1/analytics)
- Period filter widget (week/month/year/all time) with automatic data refetch
- Reusable StatCard widget for dashboard grids
- Charts via fl_chart: revenue vs purchases bar chart, inventory donut chart (merchant); crop status donut, yield vs loss bar chart (farmer)
- Responsive grid layout adapting to screen width
- Loading, error (with retry), and empty states
- Added fl_chart dependency
- Added 18 bilingual translation keys to agricola_core (dashboard stats, periods, chart labels)

## 0.2.0 — 2026-03-08

### Phase 1: Auth & Layout Shell
- Login screen with email/password and Google Sign-In (Firebase Web SDK)
- Auth state management via Riverpod StreamProvider wrapping Firebase authStateChanges
- WebAuthRepository implementing core's AuthRepository interface
- LoginController (AsyncNotifier) for sign-in, Google auth, and password reset
- GoRouter with auth redirect guard (unauthenticated -> /login)
- Dashboard shell layout: sidebar + header + content area
- Role-based sidebar navigation (merchant vs farmer nav items)
- Language toggle (EN/Setswana) on login screen and header, reusing core's t()
- User profile tile in sidebar footer with email, role, and logout
- Breadcrumb navigation in header from current route
- Reusable widget library: AppTextField, AppDropdownField<T>, AppPrimaryButton, AppSecondaryButton, AppTertiaryButton, LanguageToggle, LabeledDivider
- Added go_router, google_sign_in, fpdart dependencies
- Added missing translation keys to agricola_core (harvests, forgot_password, sign_in_with_google, etc.)

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
