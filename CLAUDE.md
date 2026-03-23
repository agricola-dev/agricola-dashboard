# Agricola Dashboard — project context for Claude

## What it is
Flutter Web admin dashboard for farmers and merchants. Deployed to dashboard.agricola-app.com. Shares models and services with the mobile app via the `agricola-core` package.

- SDK: Flutter ^3.9.0, Dart ^3.9.0
- Key deps: `flutter_riverpod`, `dio`, `go_router`, `firebase_auth`, `google_sign_in`, `fl_chart`, `agricola_core`

---

## Directory layout

```
lib/
  core/
    providers/             — language, pagination, http client providers
    network/               — web auth token provider (implements AuthTokenProvider)
    theme/                 — AppTheme (matches mobile: primary green 0xFF2D6A4F)
    widgets/               — shared UI: AppButtons, AppTextField, StatCard,
                             TablePaginationBar, PeriodFilter, ChartCard
  features/
    auth/                  — Google Sign-In login, web auth repository
    shell/                 — dashboard layout: sidebar nav, header, user profile tile
    dashboard/             — analytics screen, dashboard stats provider
    crops/                 — CRUD data table, form dialog, stage badge
    harvests/              — CRUD data table, form dialog, quality badge
    inventory/             — list + detail (farmer & merchant)
    marketplace/           — listings CRUD, form dialog, price/type badges
    orders/                — merchant order management
    purchases/             — farmer purchase records
    loss_calculator/       — form dialog, detail view, severity badge
    profile/               — role-specific edit forms
    reports/               — analytics grid, date range, CSV & PDF export
  routing/                 — GoRouter config
  app.dart                 — Material app shell (responsive check: min 768px)
  main.dart                — Firebase init + ProviderScope
```

---

## Shell layout

`features/shell/` defines the dashboard chrome:
- **Sidebar**: navigation links per user role
- **Header**: title + user profile tile
- **Content area**: renders the active feature screen
- **Minimum width**: 768px — below that, shows a "use mobile app" redirect screen

---

## State management — Riverpod

Same pattern as the mobile app:
- `StateNotifierProvider<Notifier, AsyncValue<List<Model>>>` for async CRUD
- Notifier methods return `Future<String?>` (null = success)
- Screens use `AsyncValue.when(data/loading/error)`

---

## Auth

1. User clicks "Sign in with Google" → `GoogleSignIn` → Firebase Auth
2. `WebAuthTokenProvider` implements `AuthTokenProvider` from agricola-core
3. JWT injected into every Dio request via `AuthInterceptor`

---

## Pagination

Client-side pagination via `paginationProvider` in `core/providers/`:
- Page sizes: 10, 25, 50 rows
- `TablePaginationBar` widget handles page navigation
- Applied to all 7 data tables (crops, harvests, inventory, marketplace, orders, purchases, loss calculations)

---

## i18n

Uses `t(key, language)` from agricola-core. Language preference stored in `localStorage`.

---

## Data export

`features/reports/` supports:
- **CSV**: crops, harvests, inventory, purchases, orders — bilingual headers
- **PDF**: farm summary (farmer), business summary (merchant) — single-page A4
- Accessed via export button on the reports screen

---

## Key conventions

- Feature-first architecture: `features/<name>/providers/`, `features/<name>/presentation/`
- All models, services, and enums come from `agricola_core` — don't duplicate
- Shared widgets in `core/widgets/` — reuse `StatCard`, `AppButtons`, etc.
- Changes to agricola-core affect this dashboard — test both after modifying shared code
