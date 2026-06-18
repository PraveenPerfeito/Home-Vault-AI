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

## Phase 3 — OCR Scanner

- Camera integration (image_picker)
- Gallery upload
- ML Kit on-device OCR
- Expiry date extraction
- Product name extraction
- Manual correction UI
- Photo upload to Firebase Storage
- photoUrl persisted on Item

## Phase 4 — Dashboard Enhancements

- Filtering by category and expiry status
- Search
- Sort options (expiry date, name, recently added)
- Pull-to-refresh

## Phase 5 — Notifications

- 30 days before expiry
- 7 days before expiry
- 1 day before expiry
- Expired today
- Firebase Cloud Messaging (FCM) integration
- Notification permission handling

## Phase 6 — Play Store Release

- Privacy Policy (in-app + web link)
- App icon (all densities)
- Feature graphic + screenshots
- Release build (ProGuard, signing)
- Internal Testing track
- Production release
