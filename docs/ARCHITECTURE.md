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
    ├── dashboard/
    │   └── presentation/screens/dashboard_screen.dart  Stats row + items list + FAB (scan/manual) + logout
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
| firebase_storage | ^12.3.2 | Photo storage (Phase 3) |
| firebase_messaging | ^15.1.3 | Push notifications (Phase 5) |
| google_sign_in | ^6.2.1 | Google OAuth |
| flutter_riverpod | ^2.5.1 | State management |
| riverpod_annotation | ^2.3.5 | Code-gen support (not yet used) |
| go_router | ^14.3.0 | Navigation |
| hive_flutter | ^1.1.0 | Local storage (init only; Phase 3) |
| logger | ^2.4.0 | Structured logging |
| equatable | ^2.0.5 | Value equality on domain entities |
| intl | ^0.19.0 | Date formatting (declared; hand-rolled arrays used instead — see Decisions) |
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
| `Provider.autoDispose` | `itemStatsProvider` — derived stats (total/expiring/expired) |
| `AutoDisposeAsyncNotifierProvider` | `authActionsProvider`, `itemActionsProvider` — CRUD actions |

**Auth guard pattern:**
`_RouterNotifier extends ChangeNotifier` listens to `authStateProvider` and calls `notifyListeners()` on any change. GoRouter uses `refreshListenable: notifier` to re-run its `redirect` callback on every auth state change.

---

## Design Decisions

See [DECISIONS.md](DECISIONS.md) for the full decision log.

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
