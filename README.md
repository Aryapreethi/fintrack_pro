# FinTrack Pro — Offline Edition

A premium, fully offline expense tracker for Flutter. Zero network dependency, custom-painted charts, biometric auth, camera receipts, recurring transactions, exports, QR sharing, home widgets, background tasks, and bilingual (English / हिन्दी) UI.

## Quickstart

```bash
flutter pub get
flutter run -d <android-device>
flutter test
flutter build apk --release --no-tree-shake-icons
```

> Minimum Android SDK is **23** (`local_auth` requirement). The app targets Android primarily; iOS is scaffolded but home widgets and background scheduling are Android-only at this stage.
>
> **Icon tree-shaking:** We construct `IconData` from category-stored codepoints at runtime, so release builds must pass `--no-tree-shake-icons` to keep all Material Icons available.

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Presentation                          │
│   features/dashboard, transactions, budget, categories,  │
│   receipts, export, settings, auth, shell                │
│                       (Riverpod)                         │
└──────────────────────────────────────────────────────────┘
                          ↓ ref.watch
┌──────────────────────────────────────────────────────────┐
│                       Providers                          │
│   db, transactions, categories, budget, recurring,       │
│   settings, biometric                                    │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│                     Repositories                         │
│   transaction, category, recurring, budget, settings     │
│         (referential integrity in code, not DB)          │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│                Data sources & services                   │
│   HiveDatabase, RepairService, RecurringEngine,          │
│   BiometricService, WorkManagerService,                  │
│   HomeWidgetService, ThumbnailService                    │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│                Hive (local key-value)                    │
│   boxes: transactions, categories, recurring_rules,      │
│          budgets, settings                               │
└──────────────────────────────────────────────────────────┘
```

The presentation layer never touches Hive directly — all reads and writes pass through repositories, which validate referential integrity (Hive lacks foreign keys). On every cold start `RepairService` walks the boxes and patches up any dangling references that slipped through.

## Folder Layout

```
lib/
├── main.dart                          # Boot: Hive init + repair + recurring + WorkManager
├── app/
│   ├── app.dart                       # MaterialApp.router + DynamicColorBuilder
│   ├── router.dart                    # GoRouter shell + tab routes
│   └── theme/                         # Light/Dark M3 + brand seed
├── core/
│   ├── utils/                         # currency_formatter, date_helpers, haptics, hero_tags
│   └── error/app_exceptions.dart
├── data/
│   ├── models/                        # Hive TypeAdapters (manual — no codegen needed)
│   ├── datasources/hive_database.dart
│   └── repositories/
├── providers/                         # Riverpod glue
├── features/
│   ├── auth/                          # Biometric gate
│   ├── dashboard/                     # Custom-painted charts + summary cards
│   ├── transactions/                  # Multi-step add flow + list + detail
│   ├── categories/                    # CRUD + icon/color picker
│   ├── budget/                        # Monthly limit + progress ring
│   ├── receipts/                      # Camera + crop overlay + thumbnail
│   ├── recurring/                     # Recurring engine
│   ├── export/                        # JSON, CSV, QR
│   ├── settings/
│   └── shell/                         # Bottom-nav with FAB Hero
├── services/                          # repair, biometric, workmanager, home_widget
└── l10n/
    ├── app_en.arb / app_hi.arb        # Canonical translation source
    └── generated/app_localizations.dart
```

## Decision log

| Decision | Choice | Rationale |
|---|---|---|
| Database | **Hive** | Spec permits Drift / Isar / Hive. Chose Hive for the offline-first, no-codegen-needed DX. Trade-off: no FK constraints — mitigated with repository validation + `RepairService` startup pass. |
| State management | **Riverpod** | Compile-time safety, granular `Provider.family` for month-scoped aggregations. |
| Charts | **CustomPainter only** | Spec forbids `fl_chart`. `DonutChartPainter` does manual `Path.contains()` hit-testing for tap-to-explode. |
| Localization | **Hand-rolled `AppLocalizations` + .arb files** | Avoids requiring `flutter gen-l10n` to run mid-build. The .arb files remain canonical and can be regenerated to a synthetic package later. |
| Hive adapters | **Manual `TypeAdapter` subclasses** | No `build_runner` required, smaller dev loop. |
| Tab transitions | **Hero shared elements** | User requirement: every tab switch and tab→detail transition has at least one Hero pair. Tags centralized in `core/utils/hero_tags.dart`. |
| Native widgets | **Android Java `AppWidgetProvider`** | iOS WidgetKit deferred; Android primary. Home widget surfaces this-month spend + budget remaining. |
| Background recurring | **WorkManager** (Android) | Daily periodic task fires `RecurringEngine.materializeDue()`. iOS falls back to app-resume only. |
| Receipts | **camera + image** | Captured image is downsampled to a JPEG thumbnail (≤1200px long edge, q78) and saved to app docs. |
| Biometric | **local_auth** | Optional setting; gates app launch and "Wipe data" / "Restore" actions. |
| QR export | **gzip + base64 + qr_flutter** | Falls back to JSON share if payload exceeds ≈2.9 KB QR capacity. |

## Custom-painted UI

- **`DonutChartPainter`** — paints arcs from category breakdown; caches per-slice `Path` so taps can `path.contains(localPos)` and explode the matching slice via an `AnimationController`.
- **`AnimatedSummaryCard`** — count-up `Tween<double>` + `Hero` shared element; flips on tap with `Matrix4.rotationY`.
- **`BudgetRing`** — sweep-gradient ring driven by `AnimationController`, painted into a `CustomPainter`. Color shifts from primary → orange → error as fraction crosses 80% / 100%.
- **`CustomRefresh`** — pull-to-refresh wrapper; on completion invalidates `transactionsStreamProvider`.

## Hero animations on navigation

Every tab switch and tab→detail transition has at least one `Hero` shared element. Tag namespace lives in [`lib/core/utils/hero_tags.dart`](lib/core/utils/hero_tags.dart):

| Source → Destination | Tag | Visual element |
|---|---|---|
| Dashboard → Transactions | `summary-total` | Monthly total amount |
| Dashboard → Add sheet | `fab-add` | Floating action button |
| Donut slice → Category page | `category-{id}` | Color swatch / icon |
| Transactions row → Detail | `category-{id}` | Category badge |
| Transaction detail → Receipt view | `receipt-{txnId}` | Thumbnail |
| Budget tab → Edit | `budget-ring` | Progress ring |

Reduced-motion preference (in Settings or system) shortens animation durations to zero across `AnimatedSummaryCard`, `DonutChart`, `BudgetRing`, and `FlippableCard`.

## Testing

```bash
flutter test
```

| File | What it covers |
|---|---|
| `test/data/transaction_repository_test.dart` | Validation, FK integrity, monthly aggregations, income exclusion. |
| `test/data/category_repository_test.dart` | Empty-name rejection, system-category protection, transaction reassignment on delete. |
| `test/features/recurring_engine_test.dart` | Daily/weekly/monthly materialization, idempotency, end-date respect. |
| `test/features/json_round_trip_test.dart` | Full export → wipe → import round trip, schema-version rejection. |
| `test/features/csv_exporter_test.dart` | Header, comma escaping, quote escaping. |
| `test/features/repair_service_test.dart` | Orphan reassignment, missing-receipt clearing, dedupe. |
| `test/core/currency_formatter_test.dart` | Locale-aware grouping, INR/Hindi rendering, parsing. |
| `test/core/date_helpers_test.dart` | Month boundaries, leap year, same-day comparison. |

## Privacy & offline guarantees

- No `dio`, `http`, Firebase, Supabase, or other network packages declared.
- All persistent state lives in Hive boxes inside the app's documents directory.
- Backup files (JSON, CSV) and receipt thumbnails are written under `<app docs>/exports` and `<app docs>/receipts`.
- Biometric authentication is opt-in and gates app open + sensitive actions only.

## Known limitations

- **iOS feature parity** — Home widget and WorkManager are Android-only at this stage. iOS recurring transactions materialize on app resume rather than via BGTaskScheduler.
- **QR payload limit** — single-QR sharing is capped at ~2.9 KB; the page falls back gracefully and points users at JSON export.
- **Hindi locale** — currency parsing uses `intl`'s decimal pattern; non-ASCII grouping marks are handled but very locale-specific edge cases (e.g. lakh grouping) are not specially formatted yet.

## License

Source available for evaluation. No license has been declared.
