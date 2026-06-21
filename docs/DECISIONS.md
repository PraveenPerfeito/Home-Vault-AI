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
