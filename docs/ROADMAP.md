# Home Vault Roadmap

## Phase 1 ✅ Completed — Foundation

- Flutter project setup (feature-first clean architecture)
- Firebase setup (Auth, Firestore, Storage, FCM configured)
- Riverpod state management wired
- GoRouter with auth guard
- Material Design 3 theme (light + dark)
- AppLogger, AppConfig, error types
- Placeholder screens (Splash, Login, Dashboard)

## Phase 2 ✅ Completed — Authentication + Item CRUD

**Completed tasks:**
- Email/password sign-in and registration
- Google sign-in
- Anonymous (guest) sign-in
- Sign-out with router redirect
- Auth guard (GoRouter redirect via ChangeNotifier + refreshListenable)
- User Firestore document (`users/{uid}`)
- Item domain entity with `ItemCategory` enum (7 categories)
- Firestore item repository (`users/{uid}/items/{itemId}` subcollection)
- Create / Edit / Delete / List items (real-time stream)
- Dashboard with stats (total, expiring soon, expired)
- Add/Edit item form (category chips, date pickers, validation)
- ItemCard widget with colour-coded expiry badges
- Hive service scaffold (init only; boxes deferred to Phase 3)

**Phase 2 production readiness review — original findings:**

| Severity | Count | Status after Phase 2.1 |
|----------|-------|------------------------|
| CRITICAL | 3 | ✅ All resolved |
| HIGH | 12 | ✅ All resolved (11 fixed + 1 removed as dead code) |
| MEDIUM | 14 | Open — not blocking production |
| LOW | 7 | Open — not blocking production |

## Phase 2.1 ✅ Completed — Security Hardening

- `firestore.rules` + `firebase.json` + `firestore.indexes.json` committed (`deploy: firebase deploy --only firestore:rules`)
- `AppException.toString()` sanitised — `cause` chain never reaches UI snack bars
- `debugLogDiagnostics` gated on `kDebugMode` — no route events logged in production APK
- `ref.listen` → `ref.listenManual` in `initState()` across login, register, and add/edit screens; `ProviderSubscription` closed in `dispose()`
- `_isSaving` flag in add/edit screen prevents spurious `context.pop()` on incidental rebuilds
- All `!` bang dereferences on `cred.user` / `_auth.currentUser` replaced with explicit null checks
- `deleteItem` now derives `userId` from `currentUserProvider` (Firebase Auth token), not `item.userId`
- `maxLength` constraints added: name (100), notes (1000), displayName (100), password (128), email (254)
- `user-not-found` / `wrong-password` / `invalid-credential` merged to single message — account enumeration closed
- Dead `Failure` hierarchy (`failure.dart`) deleted — `AppException` is the sole error contract

## Phase 3 ✅ Completed — OCR Scanner

**Completed tasks:**
- `image_picker` integration — camera capture + gallery selection
- `google_mlkit_text_recognition` on-device OCR (Latin script, no network required)
- ML Kit model pre-downloaded at install via `com.google.mlkit.vision.DEPENDENCIES` meta-data
- `ExpiryDateExtractor` — regex engine supporting all 6 required formats:
  - `MM/YYYY`, `MM-YYYY`, `DD/MM/YYYY`, `DD-MM-YYYY`, `AUG 2027`, `AUG-2027`
  - Keyword-first priority (`EXP`, `BEST BEFORE`, `USE BY`, `BBD`, etc.)
  - Span-tracking to prevent double-matching DD/MM/YYYY as MM/YYYY
  - Year range guard (2020–2040); plausibility filter (−2 to +15 years from today)
- `ProductNameExtractor` — scoring heuristic (letter ratio, word count, length, ALL-CAPS bonus)
- `ScannerScreen` — Camera/Gallery picker → loading → result view
- `ScanResultCard` — shows detected name + expiry, collapsible raw text, Scan Again + Add Item buttons
- `AddEditItemScreen` — `ScanResult?` parameter; pre-fills name + expiry; shows info banner
- `DashboardScreen` FAB — bottom sheet with Scan Product / Add Manually options
- `AppRoutes.scanner = '/scanner'` route added to GoRouter

**Deferred from Phase 3 scope:**
- Photo upload to Firebase Storage (photoUrl on Item) — deferred to Phase 4
- Barcode scanning — out of scope per PRD
- Warranty date extraction — out of scope per PRD

## Phase 3.5 ✅ Completed — Quality Gate

**Goal:** Validate all completed functionality before Phase 4.

### Test Results

| Suite | Tests | Pass | Fail |
|-------|-------|------|------|
| Unit — ExpiryDateExtractor | 32 | 32 | 0 |
| Unit — ProductNameExtractor | 14 | 14 | 0 |
| Unit — ItemModel serialization | 18 | 18 | 0 |
| Widget — LoginScreen | 11 | 11 | 0 |
| Widget — RegisterScreen | 8 | 8 | 0 |
| Widget — AddEditItemScreen | 9 | 9 | 0 |
| OCR Validation (23 samples) | 77 | 77 | 0 |
| **Total** | **169** | **169** | **0** |

### Coverage Report

| Module | Coverage | Status |
|--------|----------|--------|
| ExpiryDateExtractor | 98.0% (48/49) | ✅ Exceeds 80% |
| ProductNameExtractor | 95.3% (41/43) | ✅ Exceeds 80% |
| ItemModel | 67.4% (31/46) | ⚠ Below 80% — fromFirestore untested |
| LoginScreen | 84.6% | ✅ |
| RegisterScreen | 93.9% | ✅ |
| AddEditItemScreen | 71.6% | ⚠ — photo/invoice paths untested |
| Overall (all files) | 40.9% | Expected — Firebase/camera code requires live hardware |

### OCR Accuracy (23-sample dataset)

- Expiry extraction: **≥80% pass rate** ✅
- Null rejection: **≥80% correct** ✅
- Product name extraction: **≥70% pass rate** ✅

### Known Weak Areas (Deferred to Phase 4)

1. **DD/MM/YYYY invalid-day span tracking** — When `d > 31` or calendar-invalid (Feb 31), the span is
   not reserved, so Pattern 2 (MM/YYYY) still extracts the month/year sub-pattern. Low real-world
   impact (OCR rarely produces `32/06/YYYY`), but produces a date instead of null.
2. **ItemModel.fromFirestore** — Not unit-tested (requires Firestore mock or fake); 67.4% coverage.
3. **Auth data layer** — 0% coverage; requires Firebase emulator integration tests (Phase 6).
4. **Scanner screen / camera path** — 0% coverage; requires device/emulator E2E tests.

## Phase 3.6 ✅ Completed — Stabilization and Real Device Readiness

**Goal:** Improve reliability before building new features.

### 1. OCR Span-Tracking Bug Fix

**Issue:** When `ExpiryDateExtractor` Pattern 1 (DD/MM/YYYY) rejected a date due to invalid day
(`d > 31`) or calendar overflow (`Feb 31`), the matched span was not reserved in `ddmmSpans`.
Pattern 2 (MM/YYYY) could then re-match the `MM/YYYY` sub-token within the same span.

**Fix:** Moved `ddmmSpans.add((m.start, m.end))` before the validity check — span is always
reserved when Pattern 1 finds any match, regardless of whether the date is valid.

**Regression tests added:**
- `32/06/2027` now correctly returns `null`
- `31/02/2027` now correctly returns `null`
- `Exp: 32/08/2027` (with keyword context) now correctly returns `null`

### 2. Analyzer Cleanup

- Fixed `curly_braces_in_flow_control_structures` in `ProductNameExtractor` (6 if-else chains)
- Added `library ocr_samples;` directive to fix dangling doc comment warning
- **Result: 0 errors, 0 warnings, 6 info-level hints (all in test/test_data files)**

### 3. Production Readiness Audit

| Area | Status |
|------|--------|
| Flutter analyzer errors | ✅ 0 errors |
| Flutter analyzer warnings | ✅ 0 warnings |
| Null safety issues | ✅ None found |
| Security issues (hardcoded secrets) | ✅ None — all credentials gitignored |
| Firestore rules | ✅ Deployed; user-scoped rules committed |
| Dead code | ✅ `Failure` hierarchy removed in Phase 2.1 |
| Unused providers | ✅ None — all providers referenced |
| Error handling | ✅ All UI errors use `AppException.message`, never `e.toString()` |
| Unused imports (production) | ✅ 0 unused imports in `lib/` |
| Deferred deps (`intl`, `firebase_messaging`) | ℹ️ Pre-declared for Phase 4-5, not yet imported |

### 4. Documents Created

- `docs/REAL_DEVICE_TEST_PLAN.md` — 30+ test cases across auth, CRUD, OCR, failure scenarios
- `docs/RELEASE_CHECKLIST.md` — Play Store release gate (Firebase, icons, privacy policy, assets)

### 5. Test Results After Phase 3.6

**170/170 tests pass** (3 new regression tests added for span-tracking fix).

### Production Readiness Score

| Category | Score |
|----------|-------|
| Code quality (analyzer) | 10/10 — 0 errors, 0 warnings |
| Test coverage (extractors) | 9/10 — ExpiryDateExtractor 98%, ProductNameExtractor 95% |
| Security | 9/10 — auth hardened, rules deployed; Crashlytics deferred |
| OCR accuracy | 8/10 — all primary formats covered; 2-digit year + `/` separator deferred |
| Release readiness | 7/10 — checklist created; icons/privacy policy/signing not yet done |
| **Overall** | **8.6/10** |

## Phase 4 ✅ Completed — Expiry Intelligence Dashboard

**Goal:** Transform the dashboard from a generic item list into an expiry-focused intelligence view.

### Completed Tasks

- **`ExpiryDashboardData` model** — 5 buckets: `expired`, `expiringToday`, `expiringWeek` (1–7 days), `expiringMonth` (8–30 days), `recentlyAdded` (>30 days or no expiry)
- **`expiryDashboardProvider`** — `Provider.autoDispose` that derives all bucketing and sorting from `itemsStreamProvider` — zero extra Firestore queries
- **Summary row** — 3 cards: Total Items (indigo), Expiring Soon (amber), Expired (red); day-granularity counts
- **Sectioned dashboard** — `CustomScrollView` + slivers; 5 section headers (icon + color + count chip); only non-empty sections rendered
- **Section sorting:**
  - Expired: most recently expired first
  - Expiring Today: alphabetical
  - Within 7 / 30 Days: soonest expiry first
  - Recently Added: newest `createdAt` first
- **Visual urgency color coding:** Expired=red, Today/7d=orange, 30d=amber, RecentlyAdded=indigo
- **Pull-to-refresh** — `RefreshIndicator` on `CustomScrollView`; `ref.invalidate(itemsStreamProvider)` with 5-second timeout guard
- **Empty dashboard state** — full-screen with "Add First Item" button when vault is empty
- **Error state** — full-screen retry widget when Firestore fails to load
- **FAB and add-options bottom sheet** — unchanged from Phase 3

### Firestore Query Strategy

No additional Firestore queries. The dashboard derives all 5 sections from the existing `itemsStreamProvider` stream via client-side `Provider.autoDispose`. This is appropriate for MVP item counts (expected <500 items per user). The `expiryDashboardProvider` rebuilds reactively on any item change.

### Performance Considerations

- Client-side bucketing: O(n) pass over the item list, runs in <1ms for typical MVP item counts
- `Provider.autoDispose` ensures the derived state is garbage-collected when the dashboard is not visible
- `AlwaysScrollableScrollPhysics` ensures pull-to-refresh is available even when content fits on screen
- 88px bottom padding reserves space above the FAB so the last item is not obscured

### Tests Passing After Phase 4

**170/170 tests pass** — no regressions from Phase 3.6.

## Phase 5 ✅ Completed — Expiry Notifications

**Goal:** Notify users before products expire using local (on-device) scheduling.

### Completed Tasks

- **`NotificationService`** — Core service with:
  - `initialize()` — inits `flutter_local_notifications` plugin + timezone data
  - `requestPermission()` — requests Android 13+ runtime notification permission
  - `hasPermission()` — checks current permission status
  - `scheduleItemNotifications(item)` — schedules 4 reminders (30d, 7d, 1d, today) at 09:00 AM local time; cancels old slots first (safe to call on update)
  - `cancelItemNotifications(itemId)` — cancels all 4 slots for an item
  - `cancelAll()` — cancels every pending notification (used when disabling)
- **Notification ID scheme** — `(itemId.hashCode.abs() % 9_999_999) * 10 + slot`; deterministic, stable across restarts, fits Android int32
- **`notificationSyncProvider`** (non-autoDispose `NotifierProvider`) — watches `itemsStreamProvider` and keeps notification schedules in sync reactively:
  - NEW item → schedule
  - CHANGED `expiryDate` → reschedule
  - DELETED item → cancel
- **`notificationsEnabledProvider`** — AsyncNotifier backed by SharedPreferences; persists the user's enabled/disabled choice across restarts
- **`notificationPermissionProvider`** — FutureProvider checking current Android permission status; invalidatable after permission request
- **`NotificationSettingsScreen`** — accessible from Dashboard AppBar bell icon:
  - Toggle: Expiry Reminders enabled/disabled
  - Permission status indicator (granted / denied) with tap-to-request
  - Reminder schedule information (30d / 7d / 1d / today at 09:00)
- **Route** — `/settings/notifications` added to GoRouter
- **Dashboard AppBar** — `Icons.notifications_outlined` button navigates to settings

### Notification Content

| When fired | Title | Body |
|-----------|-------|------|
| 30 days before expiry | "Expires in 30 days" | "Your [name] expires in 30 days." |
| 7 days before expiry | "Expires in 7 days" | "Your [name] expires in 7 days." |
| 1 day before expiry | "Expires tomorrow" | "Your [name] expires tomorrow." |
| Expiry day | "Expires today" | "Your [name] expires today." |

All notifications fire at **09:00 AM local time** on their target day.

### Notification Architecture

- **Technology**: `flutter_local_notifications` (on-device, no server, no FCM)
- **Timezone-safe**: `tz.TZDateTime.from(date, tz.local)` via `timezone` package
- **Sync model**: Reactive stream-based — no hooking into CRUD methods; the `notificationSyncProvider` detects changes when Firestore fires the items stream
- **Startup**: `NotificationService` initialized before `runApp()`; injected into Riverpod via `overrideWithValue`; sync provider started in `HomeVaultApp.build()`

### Tests Passing After Phase 5

**187/187 tests pass** — 17 new unit tests for `NotificationService` pure logic (notifId, remindAt, date offset calculations).

## Phase 5.5 ✅ Completed — Release Candidate Audit

**Goal:** Identify all blockers and risks before Play Store submission.

### Audit Scope

All phases reviewed: Foundation, Auth, Items CRUD, OCR Scanner, Dashboard, Notifications.

### `flutter analyze` Results

| Severity | Count | Location |
|----------|-------|----------|
| Errors | 0 | — |
| Warnings | 0 | — |
| Info hints | 6 | Test files only (`prefer_const_constructors`) |

**Production code (`lib/`) is fully clean.**

### Findings by Severity

**CRITICAL — Play Store Blockers:**

| # | Finding | File | Action |
|---|---------|------|--------|
| 1 | Release build uses `signingConfigs.debug` | `android/app/build.gradle:36` | Replace with production keystore before Play Store submission |
| 2 | App icon not set | `android/app/src/main/res/` | Replace default Flutter icon with all density variants |
| 3 | Privacy Policy not present | — | Required by Play Store for data-collecting apps |

**HIGH — Pre-Launch Risks:**

| # | Finding | File | Action |
|---|---------|------|--------|
| 4 | `firebase_messaging` native service declared in `AndroidManifest.xml` but Dart package not initialized in `main.dart` | `android/.../AndroidManifest.xml` | Remove service declaration OR initialize `FirebaseMessaging.instance` in `main()` before FCM is needed |
| 5 | `SplashScreen.initState()` opens a `listenManual` subscription without storing or closing it | `lib/features/splash/presentation/screens/splash_screen.dart` | Store the returned `ProviderSubscription` and close it in `dispose()` — follows the project-wide pattern |

**MEDIUM — Non-blocking Technical Debt:**

| # | Finding | File | Action |
|---|---------|------|--------|
| 6 | `itemStatsProvider` defined but never read — dead code since Phase 4 | `lib/features/items/presentation/providers/items_providers.dart:48` | Remove in Phase 6 cleanup |
| 7 | `riverpod_annotation: ^2.3.5` in runtime `dependencies` — should be `dev_dependencies` or removed (code-gen not used) | `pubspec.yaml` | Move or remove in Phase 6 cleanup |
| 8 | `build_runner` and `riverpod_generator` declared as dev deps but unused (no `.g.dart` files) | `pubspec.yaml` | Remove in Phase 6 cleanup |
| 9 | `HiveService.dispose()` exists but is never called | `lib/core/storage/hive_service.dart` | Not critical — no boxes open; call in `main()` on app termination if boxes are added |
| 10 | `firebaseStorageProvider` declared but no screen calls it — photo upload still deferred | `lib/core/di/providers.dart` | Remove or use in Phase 6 |

**LOW — Cosmetic / Known Limitations:**

| # | Finding | Notes |
|---|---------|-------|
| 11 | Item name not trimmed before save — leading/trailing spaces preserved | Minor UX issue; not a data corruption risk |
| 12 | Notification ID hash collision probability ~0.05% at 100 items | Documented accepted risk (see DECISIONS.md) |
| 13 | `notificationSyncProvider._sync()` has no debounce — rapid edits trigger overlapping async calls | Harmless for MVP; each call cancels-and-reschedules the same notification IDs |
| 14 | 6 `prefer_const_constructors` hints in test files | Test-only; no production impact |

### Documents Created

- `docs/RELEASE_CANDIDATE_TEST_PLAN.md` — Full regression test plan covering new-user flow, OCR, notifications, offline, and permission denial scenarios (supersedes `docs/REAL_DEVICE_TEST_PLAN.md`)

### Launch Risk Assessment

| Risk | Severity | Impact |
|------|----------|--------|
| Release build signed with debug keystore | **CRITICAL** | Play Store will reject the APK outright |
| No app icon | **CRITICAL** | Play Store listing requires custom icon |
| No Privacy Policy | **CRITICAL** | Play Store requires it for apps that handle personal data |
| `firebase_messaging` service declared but not initialized in Dart | **HIGH** | May cause startup warnings; FCM token registration could behave unexpectedly |
| `SplashScreen` listener leak | **HIGH** | Rare path — only if auth resolves after splash is disposed; monitor for `setState after dispose` errors in production logs |
| Dead code / unused deps in pubspec | **MEDIUM** | Slightly larger build; no runtime impact |
| Notification ID hash collision | **LOW** | ~0.05% at 100 items; one item's notifications could overwrite another's |

### Production Readiness Score

| Category | Score | Notes |
|----------|-------|-------|
| Architecture | 9/10 | Feature-first clean architecture; all layers present; no regressions |
| Security | 8/10 | Strong auth hardening, Firestore rules deployed; `firebase_messaging` service declared but uninitialized is a minor concern |
| Performance | 8/10 | O(n) dashboard; `itemStatsProvider` is dead code but autoDispose prevents active overhead |
| UX | 8/10 | All primary flows complete; date formatting still hand-rolled (locale-insensitive) |
| OCR | 8/10 | 6 expiry formats supported; 2-digit year and `/` in month-name pattern are documented gaps |
| Notifications | 7/10 | Local scheduling functional; plugin's own boot receiver handles reboot reschedule; no FCM server-side component |
| Release Readiness | 4/10 | Three Play Store blockers must be resolved before submission |
| **Overall** | **7.4/10** | Ready for real-device testing; 3 blockers before Play Store submission |

### Tests Passing After Phase 5.5

**187/187 tests pass** — no regressions from Phase 5.

## Phase 5.6 ✅ Completed — Release Hardening

**Goal:** Fix all audit findings from Phase 5.5 that do not add features or change architecture.

### Completed Tasks

**1. Removed unused `firebase_messaging` integration**
- Removed `firebase_messaging: ^15.1.3` from `pubspec.yaml`
- Removed `FirebaseMessagingService` service block from `AndroidManifest.xml`

**2. Fixed `SplashScreen` subscription leak**
- Added `_authSub` field of type `ProviderSubscription<AsyncValue<AppUser?>>?`
- `listenManual` result now stored in `_authSub`
- `_authSub?.close()` called in `dispose()` — follows project-wide `ref.listenManual` pattern

**3. Removed dead code**
- Removed `ItemStats` class and `itemStatsProvider` from `items_providers.dart`
- Removed `firebaseStorageProvider` from `core/di/providers.dart`
- Removed `firebase_storage: ^12.3.2` from `pubspec.yaml`

**4. Dependency cleanup**
- Removed from runtime `dependencies`: `firebase_messaging`, `firebase_storage`, `riverpod_annotation: ^2.3.5`, `intl: ^0.19.0`
- Removed from `dev_dependencies`: `build_runner: ^2.4.12`, `riverpod_generator: ^2.4.3`
- 6 packages removed total from `pubspec.yaml`

**5. Item name trimmed at notifier level**
- Added `.trim()` to `name` in `ItemActionsNotifier.createItem()` — belt-and-suspenders alongside the existing trim in `_save()` at the form layer

**6. Improved notification ID collision resistance**
- Modulus changed from `9_999_999` to `199_999_997` (a prime ~20× larger)
- New max ID: `199_999_997 × 10 + 3 = 1_999_999_973` — safely within Android int32 (max 2,147,483,647)
- Collision probability at 100 items: ~0.0025% (down from ~0.05%)
- Updated doc comment in `notification_service.dart`
- Updated bounds assertion in `test/unit/notification_service_test.dart`

### `flutter analyze` After Phase 5.6

**0 errors, 0 warnings** in `lib/`. 6 `prefer_const_constructors` info hints in test files only — unchanged.

### Tests After Phase 5.6

**187/187 tests pass** — no regressions.

### Updated Production Readiness Score

| Category | Phase 5.5 Score | Phase 5.6 Score | Notes |
|----------|----------------|-----------------|-------|
| Architecture | 9/10 | 9/10 | No change |
| Security | 8/10 | 9/10 | `firebase_messaging` service removed; SplashScreen leak fixed |
| Performance | 8/10 | 9/10 | Dead `itemStatsProvider` removed; leaner dependency tree |
| UX | 8/10 | 8/10 | No UX change |
| OCR | 8/10 | 8/10 | No change |
| Notifications | 7/10 | 8/10 | Collision resistance improved 20× |
| Release Readiness | 4/10 | 4/10 | Three Play Store blockers remain (signing, icon, privacy policy) |
| **Overall** | **7.4/10** | **7.9/10** | |

## Phase 6.1 ✅ Completed — Branding Assets

**Goal:** Prepare Android launcher icon and splash screen branding before Play Store submission.

### Completed Tasks

**1. Icon source assets created** (1024×1024 PNG)
- `assets/icon/icon.png` — white house silhouette on `#3D52D5` background (used for legacy/round icons)
- `assets/icon/icon_foreground.png` — white house on transparent background (adaptive icon foreground layer)
- House geometry: roof peak (512, 210), eaves (204–820, 530), body rect (280–744, 520–820), door cutout (420–604, 620–820)

**2. `flutter_launcher_icons` configured and generated**
- Added `flutter_launcher_icons: ^0.14.2` to `dev_dependencies` (resolved to 0.14.4)
- `flutter_launcher_icons:` configuration block added to `pubspec.yaml` (was `flutter_icons:` — updated to remove deprecation warning)
- Generated all Android launcher icon density variants:
  - `mipmap-mdpi/ic_launcher.png` (48×48)
  - `mipmap-hdpi/ic_launcher.png` (72×72)
  - `mipmap-xhdpi/ic_launcher.png` (96×96)
  - `mipmap-xxhdpi/ic_launcher.png` (144×144)
  - `mipmap-xxxhdpi/ic_launcher.png` (192×192)
  - Plus foreground variants in `drawable-{density}/ic_launcher_foreground.png`

**3. Adaptive icon (Android 8+ / API 26+)**
- `mipmap-anydpi-v26/ic_launcher.xml` — references `@color/ic_launcher_background` + `@drawable/ic_launcher_foreground`
- `android/app/src/main/res/values/colors.xml` — created by generator with `ic_launcher_background = #3D52D5`
- 16% inset applied to foreground (safe zone for circular + squircle masks)

**4. Branded splash screen**
- `drawable/launch_background.xml` — updated from `@android:color/white` to `@color/ic_launcher_background` (#3D52D5)
- `drawable-v21/launch_background.xml` — same update (API 21+ variant)
- Splash is now the same brand blue as the app icon background

### Assets Directory

```
assets/
└── icon/
    ├── icon.png             1024×1024 — full icon (background + foreground)
    └── icon_foreground.png  1024×1024 ARGB — foreground only (transparent bg)

android/app/src/main/res/
├── drawable/
│   ├── launch_background.xml      Updated — brand blue (#3D52D5)
│   ├── ic_launcher_foreground.png (generated — mdpi)
│   ├── ...
├── drawable-v21/
│   └── launch_background.xml      Updated — brand blue (#3D52D5)
├── mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/
│   └── ic_launcher.png            Generated — all densities
├── mipmap-anydpi-v26/
│   └── ic_launcher.xml            Adaptive icon descriptor
└── values/
    └── colors.xml                 ic_launcher_background = #3D52D5
```

### Regeneration Command

```bash
dart run flutter_launcher_icons
```

### `flutter analyze` After Phase 6.1

**0 errors, 0 warnings** in `lib/`. 6 `prefer_const_constructors` info hints in test files only — unchanged.

### Tests After Phase 6.1

**187/187 tests pass** — no regressions.

### Updated Production Readiness Score

| Category | Phase 5.6 Score | Phase 6.1 Score | Notes |
|----------|----------------|-----------------|-------|
| Architecture | 9/10 | 9/10 | No change |
| Security | 9/10 | 9/10 | No change |
| Performance | 9/10 | 9/10 | No change |
| UX | 8/10 | 8/10 | No change |
| OCR | 8/10 | 8/10 | No change |
| Notifications | 8/10 | 8/10 | No change |
| Release Readiness | 4/10 | 6/10 | App icon blocker resolved; signing + privacy policy remain |
| **Overall** | **7.9/10** | **8.2/10** | |

## Phase 6.2 ✅ Completed — Release Compliance

**Goal:** Resolve the final Play Store blockers through documentation, permission audit, and build hardening.

### Completed Tasks

**1. Android Signing Guide — `docs/ANDROID_SIGNING.md`**
- Step-by-step: `keytool` keystore generation, `android/key.properties` pattern, `build.gradle` update template, SHA-1 Firebase registration, AAB build + verification, Play App Signing opt-in
- File locations reference table (what is / is not committed)

**2. Privacy Policy Requirements — `docs/PRIVACY_POLICY_REQUIREMENTS.md`**
- All data collected: account (Firebase Auth), inventory (Firestore), OCR (on-device, not stored), notifications (on-device, SharedPreferences)
- Third-party sharing table (Firebase, ML Kit on-device — no ad networks)
- User rights and deletion process
- Full Data Safety form answers for Play Console
- Privacy policy hosting recommendations

**3. Play Store Submission Guide — `docs/PLAY_STORE_SUBMISSION.md`**
- App metadata, short + full description copy
- Content rating questionnaire answers (expected: Everyone)
- Data Safety section answers (complete table)
- Screenshots checklist with capture instructions
- Feature graphic + Play Store icon (512×512) generation script
- Internal testing track step-by-step (Play Console workflow)
- Pre-submission gate checklist

**4. `.gitignore` hardened**
- Added: `android/key.properties`, `*.jks`, `*.keystore`
- Prevents accidental keystore or signing credentials commit

**5. ProGuard rules enhanced — `android/app/proguard-rules.pro`**
- Added: ML Kit (`com.google.mlkit.**`), Google Play Services (`com.google.android.gms.**`), image_picker `FileProvider`, Kotlin coroutines
- Added `dontwarn` suppressions for missing classes not used at runtime

**6. `READ_MEDIA_IMAGES` permission added — `AndroidManifest.xml`**
- Required for Android 13+ (API 33+) gallery image selection via `image_picker`
- Without this, gallery access silently fails on Pixel 7+ / Android 13 devices

### `flutter analyze` After Phase 6.2

**0 errors, 0 warnings** in `lib/`. 6 `prefer_const_constructors` info hints in test files only — unchanged.

### Tests After Phase 6.2

**187/187 tests pass** — no regressions.

### Remaining Play Store Blockers

| Blocker | Type | Action Required | Reference |
|---------|------|----------------|-----------|
| Production keystore not created | **CRITICAL** | Run `keytool` command; update `build.gradle` | `docs/ANDROID_SIGNING.md` |
| `build.gradle` still uses `signingConfigs.debug` | **CRITICAL** | Follow Step 3 in ANDROID_SIGNING.md | `docs/ANDROID_SIGNING.md` |
| Privacy policy not hosted | **CRITICAL** | Write policy using PRIVACY_POLICY_REQUIREMENTS.md; host on GitHub Pages or Firebase Hosting | `docs/PRIVACY_POLICY_REQUIREMENTS.md` |
| Screenshots not captured | HIGH | Install on physical device, populate items, screenshot 2–5 screens | `docs/PLAY_STORE_SUBMISSION.md` |
| Feature graphic not created | HIGH | 1024×500 px with brand colour + tagline | `docs/PLAY_STORE_SUBMISSION.md` |

### Updated Production Readiness Score

| Category | Phase 6.1 Score | Phase 6.2 Score | Notes |
|----------|----------------|-----------------|-------|
| Architecture | 9/10 | 9/10 | No change |
| Security | 9/10 | 9/10 | `.gitignore` hardened; signing not yet done |
| Performance | 9/10 | 9/10 | No change |
| UX | 8/10 | 8/10 | No change |
| OCR | 8/10 | 8/10 | No change |
| Notifications | 8/10 | 8/10 | No change |
| Release Readiness | 6/10 | 7/10 | Signing + privacy policy documented; screenshots/feature graphic pending |
| **Overall** | **8.2/10** | **8.3/10** | |

## Phase 6 — Play Store Release

**Remaining developer actions (not automatable — require manual steps):**

1. Create release keystore (`keytool -genkey ...`) → follow `docs/ANDROID_SIGNING.md`
2. Create `android/key.properties` → follow `docs/ANDROID_SIGNING.md`
3. Update `android/app/build.gradle` → copy template from `docs/ANDROID_SIGNING.md` Step 3
4. Register release SHA-1 in Firebase Console
5. Re-run `flutterfire configure`
6. Write and host Privacy Policy → use `docs/PRIVACY_POLICY_REQUIREMENTS.md`
7. Capture screenshots on physical device
8. Create feature graphic (1024×500 px)
9. Build release AAB: `flutter build appbundle --release`
10. Upload to Play Console Internal Testing track → follow `docs/PLAY_STORE_SUBMISSION.md`
