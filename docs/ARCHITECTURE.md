# Home Vault — Architecture

## Overview

Home Vault is an Android-first Flutter application using feature-first Clean Architecture.
State management: Riverpod 2.x. Routing: GoRouter 14.x. Backend: Firebase (Auth, Firestore, Storage, FCM).

---

## Folder Structure

```
lib/
├── main.dart                      Entry point — Hive init, Firebase init, ProviderScope
├── core/
│   ├── config/
│   │   ├── app_config.dart        Environment constants (appName, env, isDevelopment)
│   │   └── firebase_options.dart  Firebase platform config (gitignored; placeholder committed)
│   ├── di/
│   │   └── providers.dart         App-level Riverpod providers (FirebaseAuth, Firestore, Storage)
│   ├── error/
│   │   └── app_exception.dart     Typed exceptions: AuthException, StorageException, NetworkException, PermissionException, NotFoundException
│   ├── logging/
│   │   └── app_logger.dart        Logger wrapper (logger package) — levels: debug/info/warn/error/fatal
│   ├── router/
│   │   └── app_router.dart        GoRouter config, AppRoutes constants, auth redirect guard
│   ├── storage/
│   │   └── hive_service.dart      Hive init scaffold — no boxes open in Phase 2
│   └── theme/
│       ├── app_colors.dart        Color palette (primary, semantic, neutrals, expiry urgency)
│       ├── app_text_styles.dart   Typography scale
│       └── app_theme.dart         ThemeData light/dark (Material Design 3)
├── shared/
│   └── models/
│       └── shared_models.dart     Barrel file — Phase 3 shared model placeholders
└── features/
    ├── auth/
    │   ├── domain/
    │   │   ├── entities/app_user.dart          AppUser (Equatable) — id, email, displayName, isAnonymous, plan
    │   │   └── repositories/auth_repository.dart  Abstract: authStateChanges, signIn*, signUp, signOut
    │   ├── data/
    │   │   ├── models/user_model.dart           Firestore ↔ AppUser mapping
    │   │   ├── datasources/auth_remote_datasource.dart  Firebase Auth + Firestore user-doc logic
    │   │   └── repositories/auth_repository_impl.dart  Implements AuthRepository
    │   └── presentation/
    │       ├── providers/auth_providers.dart    authStateProvider, currentUserProvider, authActionsProvider
    │       └── screens/                         login_screen.dart, register_screen.dart
    ├── items/
    │   ├── domain/
    │   │   ├── entities/item.dart               Item (Equatable) + ItemCategory enum (7 categories)
    │   │   └── repositories/items_repository.dart  Abstract: watchItems, createItem, updateItem, deleteItem
    │   ├── data/
    │   │   ├── models/item_model.dart           Firestore ↔ Item mapping (Timestamp ↔ DateTime)
    │   │   ├── datasources/items_remote_datasource.dart  Firestore CRUD — auto-ID via collection.add()
    │   │   └── repositories/items_repository_impl.dart  Implements ItemsRepository
    │   └── presentation/
    │       ├── providers/items_providers.dart   itemsStreamProvider, itemStatsProvider, itemActionsProvider
    │       ├── screens/add_edit_item_screen.dart  Create/Edit form — category chips, date pickers
    │       └── widgets/                         item_card.dart, category_chip.dart
    ├── scanner/
    │   ├── domain/
    │   │   ├── entities/scan_result.dart               ScanResult (rawText, extractedName?, extractedExpiry?)
    │   │   ├── repositories/scanner_repository.dart    Abstract: processImage(imagePath)
    │   │   ├── services/expiry_date_extractor.dart     Static: regex date extraction (6 formats)
    │   │   └── services/product_name_extractor.dart    Static: scoring heuristic for product names
    │   ├── data/
    │   │   ├── datasources/scanner_datasource.dart     ML Kit TextRecognizer wrapper
    │   │   └── repositories/scanner_repository_impl.dart  Combines datasource + extractors
    │   └── presentation/
    │       ├── providers/scanner_providers.dart        scannerRepositoryProvider, scanActionsProvider
    │       ├── screens/scanner_screen.dart             Picker → loading → ScanResultCard
    │       └── widgets/scan_result_card.dart           Detected name/expiry + raw text toggle + action buttons
    ├── notifications/
    │   ├── domain/
    │   │   └── services/notification_service.dart       Local notification scheduling (flutter_local_notifications + timezone)
    │   └── presentation/
    │       ├── providers/notification_providers.dart    notificationServiceProvider, notificationsEnabledProvider, notificationPermissionProvider, notificationSyncProvider
    │       └── screens/notification_settings_screen.dart  Enable toggle + permission status + schedule info
    ├── dashboard/
    │   └── presentation/screens/dashboard_screen.dart  Expiry intelligence dashboard — 5 sections, summary cards, pull-to-refresh
    └── splash/
        └── presentation/screens/splash_screen.dart     Auth-aware entry point
```

---

## Dependencies (pubspec.yaml)

| Package | Version | Purpose |
|---------|---------|---------|
| firebase_core | ^3.6.0 | Firebase initialisation |
| firebase_auth | ^5.3.1 | Authentication |
| cloud_firestore | ^5.4.4 | Database |
| firebase_storage | — | Removed Phase 5.6 (photo upload deferred; re-add when implementing) |
| firebase_messaging | — | Removed Phase 5.6 (local notifications used; FCM deferred to post-MVP) |
| google_sign_in | ^6.2.1 | Google OAuth |
| flutter_riverpod | ^2.5.1 | State management |
| riverpod_annotation | — | Removed Phase 5.6 (code-gen never used; no `.g.dart` files) |
| flutter_launcher_icons | ^0.14.2 | Dev — generates all Android launcher icon density variants (Phase 6.1) |
| go_router | ^14.3.0 | Navigation |
| hive_flutter | ^1.1.0 | Local storage (init only; Phase 3) |
| logger | ^2.4.0 | Structured logging |
| equatable | ^2.0.5 | Value equality on domain entities |
| intl | ^0.19.0 | Date formatting (declared; hand-rolled arrays used instead — see Decisions) |
| flutter_local_notifications | ^17.2.2 | On-device notification scheduling (Phase 5) |
| timezone | ^0.9.4 | Timezone-aware scheduling via TZDateTime (Phase 5) |
| shared_preferences | ^2.3.3 | Persist notifications-enabled toggle (Phase 5) |
| image_picker | ^1.1.2 | Camera capture + gallery selection (Phase 3) |
| google_mlkit_text_recognition | ^0.13.1 | On-device OCR — no network required (Phase 3) |

---

## Firebase Configuration

**Authentication providers enabled:**
- Email / Password
- Google Sign-In (requires SHA-1 fingerprint in Firebase console)
- Anonymous

**Firestore collections:**

```
users/{uid}
  email: string?
  displayName: string?
  photoUrl: string?
  isAnonymous: bool
  plan: "free" | "premium"
  createdAt: Timestamp

users/{uid}/items/{itemId}
  userId: string
  name: string
  category: string   ("food" | "medicine" | "cosmetics" | "babyProducts" | "electronics" | "household" | "other")
  photoUrl: string?
  purchaseDate: Timestamp?
  expiryDate: Timestamp?
  notes: string?
  createdAt: Timestamp
```

**Security rules** — committed as `firestore.rules`, deployed via `firebase deploy --only firestore:rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /items/{itemId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

**Firebase project files committed:**
- `firestore.rules` — access control rules
- `firebase.json` — deploy config pointing at `firestore.rules`
- `firestore.indexes.json` — index config (empty; composite indexes added as needed in Phase 4)

---

## State Management Patterns

**Providers in use:**

| Provider type | Used for |
|---------------|----------|
| `StreamProvider` | `authStateProvider` — Firebase auth state stream |
| `Provider` | `currentUserProvider` — derives `AppUser?` from auth stream |
| `Provider` | Infrastructure providers (FirebaseAuth, Firestore, repositories) |
| `StreamProvider.autoDispose` | `itemsStreamProvider` — Firestore items stream |
| `Provider.autoDispose` | ~~`itemStatsProvider`~~ — removed Phase 5.6 (replaced by `expiryDashboardProvider`) |
| `Provider.autoDispose` | `expiryDashboardProvider` — bucketed expiry sections (Phase 4) |
| `FutureProvider` | `notificationPermissionProvider` — Android permission status (Phase 5) |
| `AsyncNotifierProvider` | `notificationsEnabledProvider` — SharedPreferences-backed toggle (Phase 5) |
| `NotifierProvider` | `notificationSyncProvider` — reactive items→notifications sync (Phase 5) |
| `AutoDisposeAsyncNotifierProvider` | `authActionsProvider`, `itemActionsProvider` — CRUD actions |

**Auth guard pattern:**
`_RouterNotifier extends ChangeNotifier` listens to `authStateProvider` and calls `notifyListeners()` on any change. GoRouter uses `refreshListenable: notifier` to re-run its `redirect` callback on every auth state change.

---

## Design Decisions

See [DECISIONS.md](DECISIONS.md) for the full decision log.

Key Phase 5 decisions:
- Local notifications only (no FCM, no server) — on-device `flutter_local_notifications` with `timezone` for dst-safe scheduling
- Reactive sync via `notificationSyncProvider` watches `itemsStreamProvider` — no CRUD hooking required; handles create/update/delete automatically
- `NotificationService` pre-initialized in `main()` before `runApp()` and injected via `overrideWithValue` to avoid async race at first use
- `notificationSyncProvider` is non-autoDispose so it lives for the app lifetime and keeps the items stream alive
- Notification IDs: `(itemId.hashCode.abs() % 199_999_997) * 10 + slot` — deterministic, stable, fits Android int32; max ID 1,999,999,973
- All reminders fire at 09:00 AM local time — `remindAt(date)` sets H:M:S = 9:0:0
- `SCHEDULE_EXACT_ALARM` permission declared in manifest for Android 12+ exact scheduling

Key Phase 4 decisions:
- `expiryDashboardProvider` is client-side only — no extra Firestore queries; derives all 5 sections from `itemsStreamProvider` in a single O(n) pass
- Each item belongs to exactly ONE section; "Recently Added" is the catch-all for no-expiry or >30-day items
- Only non-empty sections render a `_SectionHeader` — empty sections produce zero slivers
- Pull-to-refresh: `ref.invalidate(itemsStreamProvider)` then `await ref.read(itemsStreamProvider.future).timeout(5s)` in a try/catch so the indicator always dismisses
- `AlwaysScrollableScrollPhysics` enables pull-to-refresh even when content fits on one screen

Key Phase 3.6 decisions:
- `ddmmSpans.add()` moved before validity check in `ExpiryDateExtractor` — span always reserved when DD/MM/YYYY matched, even if date invalid (prevents Pattern 2 re-match)
- `ProductNameExtractor` if-else chains wrapped in `{}` blocks — code style only, no behavior change
- `docs/REAL_DEVICE_TEST_PLAN.md` and `docs/RELEASE_CHECKLIST.md` created as living documents
- `intl`, `firebase_messaging`, `firebase_storage`, `riverpod_annotation` were pre-declared for Phase 4-5 (removed in Phase 5.6 cleanup)

Key Phase 3.5 decisions:
- Widget tests use `ensureVisible()` before tapping form submit buttons — login/register forms exceed 800×600 test viewport
- `FakeAuthActionsNotifier extends AuthActionsNotifier` (not `AutoDisposeAsyncNotifier<void>`) — required for Riverpod overrideWith type compatibility
- `ExpiryDateExtractor._()` / `ProductNameExtractor._()` use private constructors + static methods — test via `ClassName.extract()`
- Known span-tracking gap in `ExpiryDateExtractor`: invalid DD/MM/YYYY does not reserve span → Pattern 2 may match MM/YYYY sub-pattern (deferred fix, Phase 4)
- `test_data/ocr_samples/` directory lives outside `lib/` and `test/` so it's not counted in `flutter test` file discovery — imported by path

Key Phase 3 decisions:
- On-device ML Kit OCR (no AI API costs, works offline after model download)
- `ExpiryDateExtractor` uses span-tracking to avoid DD/MM/YYYY → MM/YYYY double-match
- Photo upload (photoUrl) deferred to Phase 4 — out of Phase 3 scope
- `ScanResult` passed via GoRouter `extra` to `AddEditItemScreen` for form pre-fill
- `ScanActionsNotifier` is AutoDispose — scanner state is reset when screen is popped

Key Phase 2 / 2.1 decisions:
- Firestore IDs generated server-side via `collection.add()` (no UUID package)
- `Item.id = ''` for new items; datasource discards the client-supplied id
- `userId` for all CRUD operations always comes from `currentUserProvider` (Firebase Auth UID), never from a domain entity field
- `Failure` hierarchy removed in Phase 2.1 — `AppException` is the sole error contract (see DECISIONS.md)
- `ref.listenManual` in `initState()` is the project-wide pattern for action-result listeners; `ref.listen` inside `build()` is not used

---

## Branding Assets — Phase 6.1 (2026-06-21)

```
assets/
└── icon/
    ├── icon.png             1024×1024 — full icon (blue #3D52D5 bg + white house)
    └── icon_foreground.png  1024×1024 ARGB — foreground only (transparent bg)

android/app/src/main/res/
├── drawable/launch_background.xml      #3D52D5 (brand blue splash)
├── drawable-v21/launch_background.xml  #3D52D5 (API 21+ variant)
├── drawable-{density}/ic_launcher_foreground.png  (generated)
├── mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png  (generated)
├── mipmap-anydpi-v26/ic_launcher.xml   Adaptive icon (foreground + @color/ic_launcher_background)
└── values/colors.xml                   ic_launcher_background = #3D52D5
```

Regenerate with: `dart run flutter_launcher_icons`

---

## Audit Findings — Phase 5.5 / 5.6 (2026-06-21)

### Analyzer Status

`flutter analyze`: **0 errors, 0 warnings** in `lib/`. 6 `prefer_const_constructors` info hints in test files only.

### Resolved in Phase 5.6

| Symbol / Issue | Resolution |
|----------------|------------|
| `itemStatsProvider` + `ItemStats` class | Removed from `items_providers.dart` |
| `firebaseStorageProvider` | Removed from `core/di/providers.dart` |
| `firebase_messaging` native service in manifest | Removed from `AndroidManifest.xml` |
| `firebase_messaging`, `firebase_storage`, `riverpod_annotation`, `intl` deps | Removed from `pubspec.yaml` |
| `build_runner`, `riverpod_generator` dev deps | Removed from `pubspec.yaml` |
| `SplashScreen` `listenManual` subscription leak | Fixed — stored in `_authSub`, closed in `dispose()` |
| Notification ID modulus too small | Increased from `9_999_999` to `199_999_997` (prime) |
| Item name not trimmed at notifier level | `.trim()` added to `ItemActionsNotifier.createItem()` |

### Remaining Known Issues

| Severity | Issue | File |
|----------|-------|------|
| MEDIUM | `HiveService.dispose()` exists but is never called — no Hive boxes open yet | `lib/core/storage/hive_service.dart` |

### Pre-Play Store Blockers

1. **Debug signing** — `android/app/build.gradle`: `signingConfig signingConfigs.debug`. Follow `docs/ANDROID_SIGNING.md` to create keystore + `android/key.properties` + update Gradle signing config. **Developer action required.**
2. ~~**App icon**~~ ✅ **Resolved (Phase 6.1)** — All density variants and adaptive icon generated.
3. **Privacy Policy** — Write policy using `docs/PRIVACY_POLICY_REQUIREMENTS.md` and host at a stable HTTPS URL. **Developer action required.**

### Permissions Declared (Phase 6.2 — complete)

| Permission | API Level | Purpose |
|-----------|-----------|---------|
| `INTERNET` | All | Firebase network requests |
| `CAMERA` | All | OCR: photograph product labels |
| `READ_MEDIA_IMAGES` | 33+ | OCR: gallery image selection (image_picker) — added Phase 6.2 |
| `POST_NOTIFICATIONS` | 33+ | Expiry reminder notifications |
| `SCHEDULE_EXACT_ALARM` | 31+ | Exact-time notification scheduling |
| `RECEIVE_BOOT_COMPLETED` | All | Reschedule notifications after reboot |

### ProGuard / R8 Keep Rules (Phase 6.2 — enhanced)

`android/app/proguard-rules.pro` keeps:
- `io.flutter.**` — Flutter embedding
- `com.google.firebase.**` — all Firebase SDK classes
- `com.google.mlkit.**` — ML Kit text recognition
- `com.google.android.gms.**` — Play Services (required by Firebase Auth + Google Sign-In)
- `androidx.core.content.FileProvider` — image_picker camera capture
- `kotlinx.coroutines.**` — Kotlin coroutines internals

### Release Compliance Docs (Phase 6.2)

| Document | Purpose |
|----------|---------|
| `docs/ANDROID_SIGNING.md` | Keystore generation, key.properties, build.gradle template, Firebase SHA-1, AAB build/verify |
| `docs/PRIVACY_POLICY_REQUIREMENTS.md` | All data collected, third-party sharing, user rights, Play Console Data Safety answers |
| `docs/PLAY_STORE_SUBMISSION.md` | App metadata copy, content rating, screenshots checklist, Play Store icon generation, Internal Testing track steps |
