# Home Vault

Track expiry dates, warranties, and household items — all in one place.

Home Vault is an Android-first Flutter app that lets you scan products, extract expiry dates with on-device OCR, and get notified before things expire. Built with Firebase, Riverpod, and feature-first Clean Architecture.

---

## Features

| Feature | Status |
|---------|--------|
| Email / Google / Guest sign-in | ✅ Phase 2 |
| Add · Edit · Delete · List items | ✅ Phase 2 |
| Real-time Firestore sync | ✅ Phase 2 |
| Dashboard with expiry stats | ✅ Phase 2 |
| OCR scanner (ML Kit) | 🔄 Phase 3 |
| Expiry push notifications | 📋 Phase 5 |
| Play Store release | 📋 Phase 6 |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | Flutter 3.22+ · Material Design 3 |
| State | Riverpod 2.x |
| Routing | GoRouter 14.x |
| Auth | Firebase Auth (email · Google · anonymous) |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Notifications | Firebase Cloud Messaging |
| Local cache | Hive Flutter |
| OCR | Google ML Kit (Phase 3) |
| Platform | Android (iOS deferred) |

---

## Getting Started

### Prerequisites

- Flutter ≥ 3.22.0 / Dart ≥ 3.4.0
- Android Studio or VS Code with Flutter extension
- A Firebase project ([console.firebase.google.com](https://console.firebase.google.com))
- Firebase CLI: `npm install -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

### 1 — Clone

```bash
git clone https://github.com/PraveenPerfeito/Home-Vault-AI.git
cd Home-Vault-AI
```

### 2 — Configure Firebase

```bash
# Log in and connect your Firebase project
firebase login
flutterfire configure --project=<your-firebase-project-id>
```

This generates `lib/core/config/firebase_options.dart` (gitignored — never commit real credentials).

Enable these providers in the Firebase console → **Authentication → Sign-in method**:
- Email / Password
- Google
- Anonymous

For Google Sign-In, add your debug SHA-1 fingerprint under **Project Settings → Your apps**:

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android
```

### 3 — Deploy Firestore rules

```bash
firebase deploy --only firestore:rules
```

Rules are committed in [`firestore.rules`](firestore.rules). They lock each user to their own data — this step is required before the app can read or write.

### 4 — Run

```bash
flutter pub get
flutter run
```

> **First-time setup only:** if you cloned into an empty directory (no `android/` Gradle wrapper), run `flutter create . --org com.viyalabs --project-name home_vault` first, then restore the committed files.

---

## Project Structure

```
lib/
├── main.dart                          # Entry point
├── core/
│   ├── config/                        # AppConfig, firebase_options (gitignored)
│   ├── di/                            # Riverpod infrastructure providers
│   ├── error/                         # AppException hierarchy
│   ├── logging/                       # AppLogger (logger package)
│   ├── router/                        # GoRouter + auth guard
│   ├── storage/                       # Hive scaffold
│   └── theme/                         # AppColors, AppTextStyles, AppTheme
├── shared/models/                     # Cross-feature model placeholders
└── features/
    ├── auth/                          # Email · Google · anonymous auth
    │   ├── domain/                    # AppUser entity, AuthRepository
    │   ├── data/                      # Firebase datasource, UserModel
    │   └── presentation/              # authActionsProvider, Login, Register
    ├── items/                         # Item CRUD
    │   ├── domain/                    # Item entity, ItemCategory, ItemsRepository
    │   ├── data/                      # Firestore datasource, ItemModel
    │   └── presentation/              # itemsStreamProvider, Add/Edit, ItemCard
    ├── dashboard/                     # Stats row + item list
    └── splash/                        # Auth-aware entry screen
```

Each feature follows **data → domain → presentation** Clean Architecture layers.

---

## Firestore Schema

```
users/{uid}
  email: string?
  displayName: string?
  plan: "free" | "premium"
  isAnonymous: bool
  createdAt: Timestamp

users/{uid}/items/{itemId}
  userId: string
  name: string            # max 100 chars
  category: string        # food | medicine | cosmetics | babyProducts | electronics | household | other
  photoUrl: string?
  purchaseDate: Timestamp?
  expiryDate: Timestamp?
  notes: string?          # max 1000 chars
  createdAt: Timestamp
```

---

## Architecture Notes

- **Auth guard** — `_RouterNotifier extends ChangeNotifier` listens to `authStateProvider` and triggers GoRouter's `redirect` via `refreshListenable`.
- **Listener pattern** — `ref.listenManual` in `initState()` (never `ref.listen` inside `build()`). `ProviderSubscription` is closed in `dispose()`.
- **userId in CRUD** — always derived from `currentUserProvider` (Firebase Auth UID), never from a Firestore-sourced entity field.
- **Error boundary** — `AppException.toString()` returns only the user-facing `message`. Internal `cause` objects never reach the UI.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) and [`docs/DECISIONS.md`](docs/DECISIONS.md) for full detail.

---

## Roadmap

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Foundation — Flutter, Firebase, Riverpod, router, theme | ✅ |
| 2 | Authentication + Item CRUD | ✅ |
| 2.1 | Security hardening (Firestore rules, error sanitisation, null safety) | ✅ |
| 3 | OCR Scanner — ML Kit, camera, expiry extraction | 📋 |
| 4 | Dashboard enhancements — filter, search, sort | 📋 |
| 5 | Push notifications — expiry reminders via FCM | 📋 |
| 6 | Play Store release | 📋 |

Full detail in [`docs/ROADMAP.md`](docs/ROADMAP.md).

---

## Contributing

1. Read `CLAUDE.md` and `docs/ROADMAP.md` before starting any task.
2. Follow the commit format: `PHASE-N: Short description`
3. Update `docs/ROADMAP.md`, `docs/ARCHITECTURE.md`, and `docs/DECISIONS.md` after every phase.
4. Run `flutter analyze` before committing — zero warnings required.

---

## License

MIT
