# DECISIONS.md

# Home Vault Decision Log

This file records major project decisions and the reasoning behind them.

Claude must read this file before making architectural changes.

---

## 2026-06-18

### Decision: Build Home Vault Instead of Expiry Reminder App

Status: Accepted

Reason:

An expiry-only app has low retention.

A Home Vault platform can expand into:

* Expiry Tracking
* Warranty Tracking
* Invoice Storage
* Home Inventory

Impact:

Database schema must support future expansion.

---

## 2026-06-18

### Decision: Android MVP First

Status: Accepted

Reason:

Fastest route to market.

Lower development and testing effort.

Impact:

iOS deferred until product-market fit is validated.

---

## 2026-06-18

### Decision: Firebase Instead of Supabase

Status: Accepted

Reason:

Firebase provides:

* Authentication
* Firestore
* Storage
* Push Notifications

in a single ecosystem.

Impact:

Backend server not required for MVP.

---

## 2026-06-18

### Decision: Flutter Instead of Native Android

Status: Accepted

Reason:

Future iOS support possible without rewriting application.

Impact:

Single codebase.

---

## 2026-06-18

### Decision: Riverpod State Management

Status: Accepted

Reason:

Simple, scalable, widely adopted.

Impact:

All state management should use Riverpod.

---

## 2026-06-18

### Decision: Hive for Local Storage

Status: Accepted

Reason:

Offline-first capability for future versions.

Impact:

Firestore remains source of truth.

Hive used for caching and offline support.

---

## 2026-06-18

### Decision: Feature-First Architecture

Status: Accepted

Reason:

Scales better than layer-first structure.

Impact:

Each feature contains:

* data
* domain
* presentation

folders.

---

## 2026-06-18

### Decision: No Subscription System in MVP

Status: Accepted

Reason:

Focus on validating usage first.

Impact:

Premium features deferred.

---

## 2026-06-18

### Decision: OCR Using Google ML Kit

Status: Accepted

Reason:

Runs on-device.

No AI API costs.

Fast processing.

Impact:

OCR implementation should use ML Kit.

---

## 2026-06-18

### Decision: Firestore Item IDs Generated Server-Side

Status: Accepted

Reason:

Using `collection.add()` lets Firestore auto-generate document IDs.
No UUID package needed. Eliminates client-side ID collision risk.

Impact:

New `Item` entities use `id: ''` as a sentinel. The datasource calls
`collection.add()` and ignores the client-supplied id entirely.
The real id is only meaningful once the item is read back from Firestore.

---

## 2026-06-18

### Decision: `userId` for CRUD Always from Firebase Auth Token

Status: Accepted

Reason:

Using `item.userId` from the domain entity for delete/update creates a
path-traversal risk if Firestore rules are absent. Reading `currentUserProvider`
ensures the Firestore path always reflects the authenticated user's UID,
not a value that flowed through Firestore data.

Impact:

`createItem` reads userId from `currentUserProvider`.
`deleteItem` and `updateItem` must also derive userId from the auth token,
not from the passed entity. This is enforced at the provider layer.

---

## 2026-06-18

### Decision: `Failure` Hierarchy Removed

Status: Removed (Phase 2.1)

Reason:

`failure.dart` was dead code — no repository, use case, or provider referenced it.
It also contained `LimitReachedFailure` which implied a 50-item limit was enforced
when it was not, creating a false impression for future developers.

Impact:

`AppException` and its subclasses (`AuthException`, `StorageException`, etc.) are
the sole error contract at the repository boundary.
`Riverpod`'s `AsyncValue.guard` catches these into `AsyncError`.
UI layers extract the message via `e is AppException ? e.message : fallback`.

Alternatives considered:
- `Either<Failure, T>` (fpdart / dartz) — rejected; over-engineering for MVP.
- Keep as placeholder — rejected; dead code with misleading `LimitReachedFailure` is worse than no code.

---

## 2026-06-18

### Decision: Hand-Rolled Date Formatting Instead of `intl`

Status: Accepted (for Phase 2)

Reason:

`intl` was added to pubspec.yaml but never called. Both `item_card.dart` and
`add_edit_item_screen.dart` use inline month-abbreviation arrays for date display.
This is simpler for MVP but ignores device locale.

Impact:

Dates always display in English month abbreviations on all devices.
Phase 3 should replace hand-rolled arrays with `DateFormat.yMMMd().format(d)`
from the `intl` package to support non-English locales.

---

## 2026-06-18

### Decision: `Color.withOpacity()` Used Despite Deprecation

Status: Accepted (for Phase 2), must fix before Play Store release

Reason:

`withOpacity()` is deprecated in Flutter 3.27+. The replacement is
`withValues(alpha: x)`. The deprecated calls are functional but will generate
analyzer warnings in future SDK upgrades.

Impact:

8+ call sites across dashboard, item_card, login, and category_chip screens.
Must be updated to `withValues(alpha: x)` before production release.

---

---

## 2026-06-18 (Phase 2.1 — Security Hardening)

### Decision: `AppException.toString()` Returns Only `message`

Status: Accepted

Reason:

The previous implementation appended the raw `cause` object (a `FirebaseException`)
to `toString()`. Because UI snack bars called `e.toString()`, internal Firebase error
details (project paths, SDK codes) were visible to end users.

Impact:

`toString()` now returns only `message`. The `cause` field is retained for crash
reporting tools that inspect the exception object directly.
All UI error displays use `e is AppException ? e.message : 'An error occurred.'`.

---

### Decision: `ref.listenManual` in `initState()` as Project-Wide Pattern

Status: Accepted

Reason:

`ref.listen` inside `build()` re-registers the callback on every widget rebuild.
While Riverpod 2.x deduplicates state-change firing, the captured `context` can
become stale, and a `context.pop()` call in the data branch can trigger on
incidental rebuilds in edge cases.

Impact:

All action-result listeners use `ref.listenManual` in `initState()` with a stored
`ProviderSubscription` that is closed in `dispose()`. An `_isSaving` flag gates
`context.pop()` so only saves initiated by the user trigger navigation.
New screens must follow this pattern.

---

### Decision: Account Enumeration Messages Merged

Status: Accepted

Reason:

Distinct messages for `user-not-found` vs `wrong-password` let an attacker confirm
whether an email address is registered (OWASP A07).
Firebase SDK ≥5 also returns `invalid-credential` instead of the two separate codes
on newer projects.

Impact:

All three codes (`user-not-found`, `wrong-password`, `invalid-credential`) map to
`'Email or password is incorrect.'` in `_authMessage()`.

---

### Decision: `userId` Derived Exclusively from Firebase Auth Token in All CRUD Paths

Status: Accepted (formalised in Phase 2.1)

Reason:

Phase 2 correctly applied this to `createItem` but the original `deleteItem`
implementation passed `item.userId` from the domain entity, which originated from
a Firestore document field. Without server-side rules this is a path-traversal
vector; even with rules it is poor defence-in-depth.

Impact:

`deleteItem` in `ItemActionsNotifier` now reads `userId` from
`ref.read(currentUserProvider)?.id` and sets `AsyncError(AuthException)` if null.
This closes the client-side gap; `firestore.rules` is the server-side enforcement.

---

---

## 2026-06-19 (Phase 3 — OCR Scanner)

### Decision: On-Device OCR via Google ML Kit (No AI API)

Status: Accepted

Reason:

Google ML Kit text recognition runs entirely on-device after the model is
downloaded at install time (via `com.google.mlkit.vision.DEPENDENCIES`). There
are no per-scan API costs, no network latency, and no external dependency at
runtime.

Impact:

OCR accuracy is limited to what the device camera and ML Kit's Latin-script
model can resolve. Blurry, low-contrast, or stylised text may not be read.
Supported formats are limited to what `ExpiryDateExtractor` parses (6 formats).

Alternatives considered:
- Google Vision API / OpenAI Vision — rejected; per-call cost and network
  dependency break the offline-first goal.

---

### Decision: `ExpiryDateExtractor` Uses Span-Tracking to Prevent Double-Match

Status: Accepted

Reason:

`MM/YYYY` and `DD/MM/YYYY` share a common suffix. Running both regexes naively
on `15/08/2027` would match both `15/08/2027` (correct) AND `08/2027` (false
duplicate), resulting in two DateTime values for the same text.

Impact:

`_datesFromText` processes DD/MM/YYYY first and records the character spans of
each match. When MM/YYYY is processed next, any match whose span overlaps a
recorded DD/MM/YYYY span is skipped.

---

### Decision: Product Name Extraction is Heuristic-Only

Status: Accepted (with known limitations)

Reason:

There is no reliable structural signal in OCR text to identify the product name.
A scoring function (letter ratio, word count, ALL-CAPS bonus, length band) picks
the highest-scoring line. It works well for simple single-product labels but will
fail on busy, multi-section labels.

Impact:

The extracted name is shown as a pre-filled suggestion that the user can edit
before saving. OCR accuracy for names should not be over-represented; Phase 4
could add a "edit extracted name" step.

---

### Decision: Photo Upload (photoUrl) Deferred to Phase 4

Status: Deferred

Reason:

Firebase Storage upload adds error handling complexity (upload progress, retry,
quota) that is out of scope for the OCR Phase 3 goal of expiry date extraction.
The user can scan and add a product without attaching a photo.

Impact:

`Item.photoUrl` remains unused in Phase 3. Firebase Storage is configured but
not called during add/edit flows.

---

### Decision: `ScanResult` Passed via GoRouter `extra` to `AddEditItemScreen`

Status: Accepted

Reason:

GoRouter's `extra` parameter allows type-safe data passing between routes without
encoding data into the URL (which would require URI-safe serialisation of
DateTime). The router checks `state.extra is ScanResult` before casting to
prevent runtime type errors when navigating without scan data.

Impact:

`AddEditItemScreen` accepts an optional `ScanResult? scanResult` parameter. When
present (and `existingItem` is null), it pre-fills the name and expiry date.
An info banner is shown to remind the user to verify the scanned values.

---

---

## 2026-06-21 (OCR Validation Review)

### Decision: Accept 2-Digit Year Gap as Known Limitation for MVP

Status: Accepted (deferring fix to Phase 4)

Reason:

MM/YY (e.g. `06/25`) and DDMMYY (e.g. `250625`) formats appear on medicine
packaging and small sachets. Adding 2-digit year support requires careful
span-overlap checking and a century-expansion rule (yy < 50 → 20xx). The fix
is safe but not required to launch — the user's manual edit covers the gap.

Impact:

Users scanning medicine packaging with 2-digit expiry years will get no
auto-filled date. They must enter it manually. Known issue, not a blocker.

Alternatives considered:
- Implement MM/YY regex immediately — deferred; correctness requires span
  tracking and century expansion. Phase 4 is the right time alongside
  broader OCR improvements.

---

### Decision: `/` Separator Bug in Month-Name Pattern is a Known Defect

Status: Accepted fix in Phase 4

Reason:

Pattern 3 (`jan... [.\- ] YYYY`) uses `[.\- ]` as the separator character class,
which excludes `/`. Labels printing `JUN/2025` will not be parsed.
The fix is a one-character change (`[./\- ]`) but is grouped with other
regex improvements to avoid churn.

Impact:

`JUN/2025`, `AUG/2026` style dates on labels are silently missed.
Workaround: user enters date manually.

---

### Decision: False Positive Risk from Lot Numbers is Accepted for MVP

Status: Accepted (low frequency in practice)

Reason:

Lot numbers like `L/N: 12/2024` match the MM/YYYY pattern. In practice, lot
numbers are almost always past dates, so `_bestDate` discards them when a
future expiry date is also present (it prefers future dates). The risk only
materialises when no future date exists and only a lot-number date is detected.

Impact:

Low frequency false positive. User sees an incorrect pre-filled date and must
correct it. The field is editable so this is recoverable.
Phase 4 can add a negative-keyword filter: deprioritize dates from lines
containing `lot|batch|l/n|s/n|serial`.

---

---

## 2026-06-21 (Phase 3.6 Stabilization)

### Decision: Fix ExpiryDateExtractor Span-Tracking Bug Immediately

Status: Fixed (not deferred)

Reason:

The Phase 3.5 quality gate identified the span-tracking bug as "low real-world impact, defer to Phase 4."
Phase 3.6's explicit goal is stabilization before new features. The fix is a single-line move:
`ddmmSpans.add((m.start, m.end))` moved before the validity check. Zero risk of behavior regression
for valid dates; only invalid dates are now correctly suppressed. 3 regression tests added.

Impact:

`32/06/2027` → now returns `null` (previously returned `DateTime(2027, 6)`)
`31/02/2027` → now returns `null` (previously returned `DateTime(2027, 2)`)

No change for any valid date format.

---

### Decision: Keep Pre-declared Phase 4-5 Dependencies in pubspec.yaml

Status: Accepted

Reason:

`intl`, `firebase_messaging`, `firebase_storage`, `riverpod_annotation`, and `build_runner` are
declared in `pubspec.yaml` but not yet imported in any `lib/` file. Removing and re-adding them
in their respective phases adds unnecessary churn to the dependency lockfile. They are clearly
commented with their phase context.

Impact:

Slightly larger dependency tree, but all packages are already pinned to compatible versions.
No unused code is compiled into the APK — Dart tree-shakes code at the import level.

---

## 2026-06-21 (Phase 3.5 Quality Gate)

### Decision: ExpiryDateExtractor Span-Tracking Gap is a Known Bug — Fix in Phase 4

Status: Accepted (deferred)

Reason:

Unit testing revealed that when `ExpiryDateExtractor` Pattern 1 (DD/MM/YYYY) rejects a date due to
invalid day (`d > 31`) or calendar invalidity (e.g. `31/02/YYYY` → Feb 31), the matched span is
**not** added to `ddmmSpans`. Consequently, Pattern 2 (MM/YYYY) can still match the `MM/YYYY`
sub-string within the same token. For example:

- `32/06/2027` → Pattern 1 rejects `d=32`, Pattern 2 extracts `06/2027` → returns `DateTime(2027,6)` instead of `null`
- `31/02/2027` → Pattern 1 rejects (Feb 31 normalises to March 3), Pattern 2 extracts `02/2027` → returns `DateTime(2027,2)` instead of `null`

Real-world OCR rarely produces `32/xx/YYYY` — scanners misread digits but seldom produce `32`.
The practical impact is very low for MVP. Fix: add `ddmmSpans.add((m.start, m.end))` unconditionally
(before the validity check) so even rejected spans prevent Pattern 2 double-match.

Impact:

Cosmetic: user may see a pre-filled month/year instead of an empty expiry field. The field is
editable, so this is recoverable. No data corruption risk.

Alternatives considered:
- Fix immediately — deferred: Phase 3.5 mandated "No production feature changes"; grouped with
  Phase 4 OCR improvements (P1-P3 regex fixes already queued).

---

### Decision: Widget Tests Use ensureVisible() for Tall Forms

Status: Accepted

Reason:

Flutter widget tests run in an 800×600 test canvas. Both the Login and Register screens have forms
that exceed this height when the email toggle is expanded or all fields are shown. Calling
`tester.tap()` on an off-screen widget logs a warning and the tap is not registered.
Fix: `await tester.ensureVisible(finder)` scrolls the widget into view before tapping.

Impact:
None on production. Test-only pattern documented here so future widget tests follow the same pattern.

---

---

## 2026-06-21 (Phase 5 — Expiry Notifications)

### Decision: Local Notifications Only — No Firebase Cloud Messaging

Status: Accepted

Reason:

FCM requires a Cloud Functions backend to trigger timed notifications, adding infrastructure cost and complexity outside the MVP scope. Local notifications (`flutter_local_notifications`) run entirely on-device, require no server, work offline, and fire deterministically at the scheduled time. The only limitation is that notifications are silently lost if the app is uninstalled or the user clears app data — acceptable for MVP.

Impact:

No Cloud Functions needed for Phase 5. FCM remains pre-declared in `pubspec.yaml` for a potential Phase 6 re-engagement campaign, but is not used for expiry reminders.

Alternatives considered:
- Firebase Scheduled Functions + FCM — rejected; adds backend server, cold-start latency, and per-message cost with no UX benefit for expiry reminders.

---

### Decision: Reactive Stream-Based Sync Instead of CRUD Hooking

Status: Accepted

Reason:

Hooking into `createItem` / `updateItem` / `deleteItem` in `ItemActionsNotifier` requires knowing the Firestore-generated document ID at create time, which is only available after the Firestore write completes and the stream fires. Watching `itemsStreamProvider` reactively in `notificationSyncProvider` handles all three operations uniformly: new item ID appears → schedule; expiryDate differs from last known → reschedule; ID disappears → cancel.

Impact:

There is a 1–3 second delay between a CRUD operation and the notification being scheduled/cancelled (the time for Firestore to propagate the change to the local stream). This is negligible since expiry reminders are always days or months in the future.

Alternatives considered:
- Modify repository layer to return created item ID — rejected; changes the domain interface for a presentation-layer concern.
- Hook into notifier methods — rejected; requires threading itemId through the void-returning repository layer.

---

### Decision: Non-AutoDispose notificationSyncProvider

Status: Accepted

Reason:

If `notificationSyncProvider` were autoDispose, it would be destroyed when no UI widget is watching it (e.g. when the user navigates away from the dashboard). This would stop the notification sync and allow `itemsStreamProvider` to also auto-dispose, severing the Firestore listener. Making it non-autoDispose keeps the sync and the stream alive for the app lifetime.

Impact:

`notificationSyncProvider` keeps `itemsStreamProvider` alive regardless of which screen is visible. This costs one Firestore listener + one in-memory map (`_knownExpiry`) for the entire session — negligible overhead.

---

### Decision: Notification ID Scheme — hashCode Modulo

Status: Accepted

Reason:

Android notification IDs are `int32`. Firestore document IDs are alphanumeric strings. The scheme `(itemId.hashCode.abs() % 9_999_999) * 10 + slot` maps each item to a unique 10-slot block (slots 0–3 used). Dart's `String.hashCode` is deterministic within a Dart VM build. Collision probability for 100 items: ~0.05%, acceptable for MVP.

Impact:

If two items hash to the same base ID (collision), one item's notifications silently overwrite the other's. For MVP item counts (<200), this is negligible. Phase 6 can replace with a UUID-to-int mapping stored in Firestore or SharedPreferences if needed.

---

### Decision: All Reminders Fire at 09:00 AM Local Time

Status: Accepted

Reason:

A fixed 9 AM delivery time is predictable and less disruptive than a randomly-timed notification. Using the `timezone` package's `tz.local` ensures the time is correct in the user's local timezone, including DST transitions.

Impact:

Reminders past the 09:00 AM mark on their target day are silently skipped (the `_scheduleIfFuture` check compares `remindAt(date)` against `DateTime.now()`). In practice this affects only same-day item additions where the 30-day or 7-day reminder has already passed.

---

## 2026-06-21 (Phase 4 — Expiry Intelligence Dashboard)

### Decision: Client-Side Bucketing for Dashboard Sections

Status: Accepted

Reason:

Five separate Firestore queries (one per urgency bucket) would require composite indexes, generate 5× the read costs, and still require a merge pass for the summary cards. For MVP item counts (<500 items per user), a single `Provider.autoDispose` that watches `itemsStreamProvider` and runs a single O(n) classification loop is simpler, cheaper, and reactive — rebuilds instantly on any item change without additional round trips.

Impact:

`expiryDashboardProvider` derives `ExpiryDashboardData` from `itemsStreamProvider.valueOrNull`. If Firestore is unavailable, the dashboard degrades gracefully (shows the last cached stream value or the error state).

Alternatives considered:
- Multiple Firestore queries with range filters — rejected; requires composite indexes and 5× read cost with no benefit at MVP scale.
- Single Firestore query with all items + client-side split — this is what we implemented.

---

### Decision: Single Section Membership per Item (No Duplicates)

Status: Accepted

Reason:

If an item appeared in multiple sections (e.g. both "Expiring Today" and "Expiring Within 7 Days"), the dashboard total would exceed the actual item count, and delete/edit operations could appear to affect multiple rows. Strict mutual exclusion — each item in exactly one bucket — keeps counts coherent and the UI predictable.

Impact:

Priority order: `expired → expiringToday → expiringWeek → expiringMonth → recentlyAdded`. An item on its exact expiry date (daysDiff == 0) appears in "Expiring Today", not "Expired".

---

### Decision: "Recently Added" as Catch-All Section for No-Expiry and Far-Future Items

Status: Accepted

Reason:

Items without an expiry date (e.g. electronics, furniture) and items with expiry >30 days still need to appear somewhere in the dashboard. "Recently Added" sorted by `createdAt` desc provides a useful secondary view — it shows what was added most recently regardless of expiry state.

Impact:

The label "Recently Added" may be slightly misleading for old items with far-future expiry dates, but is accurate for the common case of no-expiry household items that were added recently. An alternative label ("Safe / No Expiry") would be less intuitive for items that do have an expiry but it is >30 days away.

---

## 2026-06-21 (Phase 5.6 — Release Hardening)

### Decision: Remove firebase_messaging and firebase_storage — Deferred to Post-MVP

Status: Accepted

Reason:

Phase 5 uses on-device local notifications exclusively (`flutter_local_notifications`). The `firebase_messaging` package was pre-declared in Phase 1 for a potential future FCM push campaign. With local notifications fully functional for MVP expiry reminders, FCM adds dead weight — the native `FirebaseMessagingService` was active in the manifest without any Dart initialization, creating an uninitialized service at runtime.

`firebase_storage` was pre-declared for photo upload (PRD feature) but photo upload remains deferred. Keeping unused packages in `pubspec.yaml` increases build artifact size and the attack surface of the dependency tree.

Impact:

Both packages removed from `pubspec.yaml`. Their native SDKs are no longer bundled. Re-add when implementing: FCM (post-MVP re-engagement), Firebase Storage (photo upload in Phase 6+).

Alternatives considered:
- Keep as pre-declared stubs — rejected; the uninitialized FCM service caused a HIGH audit finding; "pre-declared" deps should be added only when needed.

---

### Decision: Remove Dead Providers and Code-Gen Dependencies

Status: Accepted

Reason:

`itemStatsProvider` + `ItemStats` were replaced by `expiryDashboardProvider` in Phase 4 and never cleaned up. Keeping them adds confusion for future developers who might wonder which provider is canonical. Since `itemStatsProvider` is `autoDispose`, it was never computed — zero runtime overhead — but it was still dead code.

`riverpod_annotation`, `build_runner`, and `riverpod_generator` were added anticipating code-gen usage. No `.g.dart` files were ever created, and the project's providers are all hand-written. Code-gen adds a `pub run build_runner build` step that is never run, which confuses new contributors.

`intl` was added anticipating locale-aware date formatting. Hand-rolled month arrays are still used. Removing it reduces the dep tree; re-add when implementing `DateFormat.yMMMd()` locale support.

Impact:

6 packages removed from `pubspec.yaml`. `ItemStats`, `itemStatsProvider`, and `firebaseStorageProvider` deleted from Dart source. `firebase_storage` import removed from `core/di/providers.dart`.

---

### Decision: Increase Notification ID Modulus to a Larger Prime

Status: Accepted

Reason:

The original modulus `9_999_999` gave a worst-case ID of `99_999_993` — well within Android's int32 limit, but the collision probability for 100 items was ~0.05% (pairwise). Using `199_999_997` (a prime, ~20× larger) reduces collision probability to ~0.0025% while the new worst-case ID (`1_999_999_973`) remains safely below Android int32 max (`2_147_483_647`).

Choosing a prime as the modulus gives better hash distribution because Dart's `String.hashCode` itself has a multiplicative component — a prime modulus reduces clustering.

Impact:

Any notifications scheduled under the old scheme (items with IDs that hash differently under the new modulus) would not be cancelled by the new `cancelItemNotifications()` call — they would be orphaned in the OS scheduler. For a pre-production app with no users, this is a non-issue. For any device that had already installed the app, a one-time `cancelAll()` at startup would clean up stale notifications; this is not required for MVP.

Test updated: `notification_service_test.dart` bounds assertion updated from `maxExpected = 9999999 * 10 + 3` to `199999997 * 10 + 3`.

---

### Decision: Add `.trim()` at Notifier Level for Belt-and-Suspenders Safety

Status: Accepted

Reason:

`AddEditItemScreen._save()` already calls `_nameController.text.trim()` before passing `name` to `ItemActionsNotifier.createItem()`. However, `createItem` is a public method — any future caller could pass an un-trimmed string. Adding `.trim()` inside `createItem` at the notifier level means the invariant "item names have no leading/trailing whitespace" is enforced at the data boundary, not just the UI layer.

Impact:

Single character addition: `name: name.trim()` in `createItem`. No behavior change for the current call site (UI already trims). Guards against future callers.

---

## 2026-06-21 (Phase 5.5 — Release Candidate Audit)

### Decision: Flag itemStatsProvider as Dead Code — Defer Removal to Phase 6

Status: Accepted (removal deferred)

Reason:

`itemStatsProvider` was introduced in Phase 2 to provide total/expiring/expired counts to the Dashboard. In Phase 4, `expiryDashboardProvider` replaced it with a richer model (`ExpiryDashboardData`) that includes computed properties (`totalCount`, `expiredCount`, `expiringSoonCount`). No screen or test currently reads `itemStatsProvider`. It is `Provider.autoDispose` so it is never computed unless watched — zero runtime overhead.

The audit mandate was "do not refactor architecture." Removal is deferred to Phase 6 to keep the audit focused on documentation and risk assessment.

Impact:

Dead code in `items_providers.dart`. No performance or correctness impact. Remove in Phase 6 cleanup pass.

---

### Decision: SplashScreen listenManual Leak — Fix Required Before Production

Status: Flagged; fix deferred to Phase 6

Reason:

`SplashScreen.initState()` calls `ref.listenManual(authStateProvider, ...)` but discards the returned `ProviderSubscription`. The subscription is never closed in `dispose()`. The project-wide pattern (established in Phase 2.1) requires storing the subscription and closing it in `dispose()`. The risk is narrow — the leak only occurs if the auth stream resolves after the Splash widget is disposed (e.g., if the router pops Splash before Firebase Auth fires). In practice this is rare but is classified HIGH because the listener captures a `BuildContext` reference.

The audit mandate was "do not add features / refactor architecture." The fix is a one-line change (store result + close in dispose). Deferred to Phase 6 pre-launch pass to keep the audit commit clean.

Impact:

Low frequency in practice. Fix in Phase 6: store `_authSub = ref.listenManual(...)` in a field; call `_authSub.close()` in `dispose()`.

---

### Decision: firebase_messaging Native Service — Clarify Intent Before Launch

Status: Flagged; resolution required before Play Store submission

Reason:

`android/app/src/main/AndroidManifest.xml` declares `com.google.firebase.messaging.FirebaseMessagingService`. The `firebase_messaging: ^15.1.3` package is in `pubspec.yaml`. However, `FirebaseMessaging.instance` is never initialized in `main.dart` and no Dart code imports `firebase_messaging`. Phase 5 uses local notifications exclusively.

The native FCM service is active at Android level, meaning the device will register a FCM token and receive silent pushes without Dart awareness. This could cause unexpected behavior (e.g., wake-up intents delivered with no handler).

Resolution options (choose one for Phase 6):
1. Remove the `FirebaseMessagingService` manifest entry and remove `firebase_messaging` from `pubspec.yaml` — cleanest; FCM deferred to Phase 6 proper.
2. Initialize `FirebaseMessaging.instance` in `main.dart` and add a `onBackgroundMessage` handler — correct if FCM is planned soon.

---

### Decision: Debug Signing in Release Build — MUST Fix Before Play Store

Status: Flagged; action required

Reason:

`android/app/build.gradle` line 36: `signingConfig signingConfigs.debug`. This was intentional during development (noted in a comment: "Phase 2: replace with release keystore"). The debug keystore is machine-specific, expires after 30 years, and is NOT accepted by the Google Play Store (which requires a production upload key or Play App Signing key).

Impact:

`flutter build apk --release` with the current config produces an APK signed with the debug key. The Play Store will reject this APK during the upload step. A production keystore must be created, secured (backed up outside the repo), and referenced in `build.gradle` before any Play Store submission.

Steps for Phase 6:
1. `keytool -genkey -v -keystore home_vault.jks -keyalg RSA -keysize 2048 -validity 10000 -alias home_vault`
2. Store keystore outside the repo; reference via environment variables or `key.properties` (gitignored)
3. Update `build.gradle` `signingConfigs.release` block
4. Change `signingConfig` in `buildTypes.release` to `signingConfigs.release`

---

## 2026-06-21 (Phase 6.2 — Release Compliance)

### Decision: Document Signing with `key.properties` Pattern — Do Not Automate Keystore Creation

Status: Accepted

Reason:

The release keystore (`home_vault_release.jks`) contains the cryptographic identity of the app. Generating it programmatically risks creating it in an insecure location, logging the password in shell history, or committing it to the repo. The developer must run `keytool` interactively, back up the file, and store the password in a password manager. These steps cannot and should not be automated.

The `key.properties` pattern (read the file at Gradle build time if it exists; fall back silently if it does not) is the Flutter community standard — it keeps secrets out of `build.gradle` while keeping `build.gradle` committable.

Impact:

`android/key.properties` is gitignored. `build.gradle` reads it at build time. CI environments that need to build release APKs must inject the file via a secret manager. The documented template in `docs/ANDROID_SIGNING.md` is the single source of truth for the signing procedure.

Alternatives considered:
- Environment variables directly in `build.gradle` — rejected; less portable, harder to document.
- Gradle `local.properties` — rejected; already used for SDK path; mixing concerns.
- Committing an encrypted keystore — rejected; adds complexity and key rotation risk.

---

### Decision: Add `READ_MEDIA_IMAGES` Permission for Android 13+ Gallery Access

Status: Accepted

Reason:

Android 13 (API 33) replaced the broad `READ_EXTERNAL_STORAGE` permission with
granular media permissions. `READ_MEDIA_IMAGES` is required to allow `image_picker`
to open the gallery picker on API 33+ devices. Without it, gallery selection on
Android 13+ (Pixel 7, Samsung S23, etc.) fails silently — the picker opens but
returns no image.

The permission was listed in the RELEASE_CHECKLIST since Phase 3.6 but was never
added to the manifest. Phase 6.2 adds it as a pre-release fix.

Impact:

`READ_MEDIA_IMAGES` added to `AndroidManifest.xml`. Runtime permission request is
handled by the `image_picker` plugin automatically. No Dart code changes required.

---

### Decision: Enhance ProGuard Rules Before First Release Build

Status: Accepted

Reason:

The original ProGuard rules kept only Flutter and Firebase classes. ML Kit,
Google Play Services (required by Firebase Auth + Google Sign-In), `image_picker`'s
FileProvider, and Kotlin coroutines were unprotected. Aggressive R8 optimisation
could strip internal classes that are referenced via reflection or JNI.

Adding keep rules for these libraries before the first release build prevents
runtime crashes from shrunk classes that are difficult to diagnose from minified
stack traces.

Impact:

`android/app/proguard-rules.pro` updated with keep rules for `com.google.mlkit.**`,
`com.google.android.gms.**`, `androidx.core.content.FileProvider`, and
`kotlinx.coroutines.**`. A `dontwarn` suppression is added for classes that are
declared in the dependency tree but not loaded at runtime (common in large SDKs).

---

### Decision: Harden `.gitignore` for Signing Artifacts Before Keystore Creation

Status: Accepted

Reason:

The `.gitignore` did not include `*.jks`, `*.keystore`, or `android/key.properties`
before Phase 6.2. If the developer created the keystore inside the repo before
gitignoring it, a `git add .` could have committed the signing secret.

Adding these entries before the keystore is created ensures the secret is
gitignored from day one. Principle: gitignore secrets before they exist.

Impact:

Three entries added to `.gitignore`: `android/key.properties`, `*.jks`,
`*.keystore`. No existing committed files are affected.

---

## 2026-06-21 (Phase 6.1 — Branding Assets)

### Decision: Use `flutter_launcher_icons` for Icon Generation

Status: Accepted

Reason:

Manual PNG generation for all 5 Android densities (mdpi through xxxhdpi) plus the adaptive icon XML is error-prone and tedious. `flutter_launcher_icons` is the Flutter community standard tool: it reads a single source PNG and emits all density variants plus the `mipmap-anydpi-v26/ic_launcher.xml` adaptive icon descriptor. It also auto-generates `colors.xml` for the adaptive icon background color.

Impact:

Icon regeneration is a single command: `dart run flutter_launcher_icons`. The source PNG at `assets/icon/icon.png` (1024×1024) is the single source of truth. Changing the icon requires only updating the source PNG and rerunning the command.

Alternatives considered:
- Manual PNG generation at each density — rejected; 10 files to maintain manually, no automation.
- Android Studio Image Asset Studio — rejected; requires Android Studio GUI; not reproducible from CLI.

---

### Decision: Adaptive Icon Foreground on Transparent Background

Status: Accepted

Reason:

Android adaptive icons use a two-layer system: a background layer (solid color, declared in `colors.xml`) and a foreground layer (the app-specific artwork). The foreground PNG must have a transparent background so the background layer shows through. The generator applies a 16% inset to the foreground to keep the artwork within the adaptive icon safe zone (the inner ~66% of the canvas that is always visible regardless of mask shape — circle, squircle, rounded square, etc.).

Impact:

`assets/icon/icon_foreground.png` is a 1024×1024 ARGB PNG: white house silhouette on a fully transparent background. The door is punched out (transparent) so the brand-blue background shows through the opening.

---

### Decision: Reuse `ic_launcher_background` Color for Splash Screen

Status: Accepted

Reason:

`flutter_launcher_icons` auto-generates `values/colors.xml` with `ic_launcher_background = #3D52D5` (AppColors.primary). Rather than adding a second `splash_background` color entry, the splash `launch_background.xml` files reference the same `@color/ic_launcher_background`. This keeps a single source of truth for the brand color in Android resources and ensures the splash screen and launcher icon background are always identical.

Impact:

`drawable/launch_background.xml` and `drawable-v21/launch_background.xml` both reference `@color/ic_launcher_background`. Changing the brand color in the future requires updating only `colors.xml` (or the `adaptive_icon_background` in `pubspec.yaml` + rerunning the generator) and both the icon and splash update together.

Alternatives considered:
- Add separate `splash_background` color — rejected; two entries for the same hex value create a maintenance discrepancy risk.
- Use a hardcoded `android:color="#3D52D5"` in the XML — rejected; not a resource reference; harder to update centrally.

---

## Deferred Decisions

These decisions are intentionally postponed.

### Family Sharing

Deferred until 100+ active users.

### AI Assistant

Deferred until Version 2.

### RevenueCat

Deferred until monetization begins.

### iOS Application

Deferred until Android gains traction.

### Analytics Dashboard

Deferred until meaningful user volume exists.
