# Home Vault — Release Candidate Test Plan

**Version:** 1.0  
**Date:** 2026-06-21  
**Phase coverage:** 1–5 (Foundation through Notifications)  
**Target:** Android physical device (API 23+) with Google Play Services  

> This document is the definitive pre-release test plan. The earlier
> `docs/REAL_DEVICE_TEST_PLAN.md` (Phase 3.6) remains for historical
> reference; this plan supersedes it for release gating.

---

## 1. New User Flow

Complete this flow on a **fresh install** (clear app data or new device).

### 1.1 First Launch — Splash → Login

| # | Action | Expected |
|---|--------|----------|
| 1 | Install APK and open app | Splash screen briefly visible |
| 2 | Observe redirect | Login screen appears (not Dashboard) |
| 3 | Check status bar | No notification icon yet |

### 1.2 Email Registration

| # | Action | Expected |
|---|--------|----------|
| 1 | Tap "Sign In with Email" | Email + Password fields appear |
| 2 | Tap Register link | Register screen opens |
| 3 | Enter name (≤100 chars), valid email, 6+ char password | No inline validation errors |
| 4 | Tap "Create Account" | Loading indicator appears |
| 5 | Observe | Redirects to Dashboard (not Login) |
| 6 | Firebase Console → Auth | New user record created |
| 7 | Firebase Console → Firestore → users/{uid} | User document created with email, displayName, plan: "free" |

### 1.3 First Dashboard State

| # | Action | Expected |
|---|--------|----------|
| 1 | View empty Dashboard | "Your vault is empty" message visible |
| 2 | "Add First Item" button present | Tapping opens bottom sheet |
| 3 | Summary cards visible | Total: 0, Expiring Soon: 0, Expired: 0 |

### 1.4 Add First Item

| # | Action | Expected |
|---|--------|----------|
| 1 | Tap FAB → "Add Manually" | Add Item screen opens |
| 2 | Leave name blank, tap Save | "Name is required" validation error |
| 3 | Enter product name | Field updates |
| 4 | Select category "Food" | Category chip highlights |
| 5 | Tap expiry date field | Date picker opens |
| 6 | Select date 30 days in future | Date shown in field |
| 7 | Tap Save | Returns to Dashboard; item appears in "Within 30 Days" section |
| 8 | Summary cards | "Total Items" = 1 |
| 9 | Firebase Console → Firestore → users/{uid}/items | Document created with correct fields |

### 1.5 Session Persistence

| # | Action | Expected |
|---|--------|----------|
| 1 | Force-close app while logged in | — |
| 2 | Reopen app | Splash → Dashboard (session preserved, not Login) |
| 3 | Item from 1.4 still visible | Persisted via Firestore |

---

## 2. Authentication Flows

### 2.1 Google Sign-In

| # | Action | Expected |
|---|--------|----------|
| 1 | Log out, tap "Continue with Google" | Google account picker appears |
| 2 | Select account | Redirects to Dashboard |
| 3 | Firebase Console → Auth | Google provider shown for user |
| 4 | Sign out; tap Google again (same account) | Signs in without picker (token cached) |

### 2.2 Guest Sign-In

| # | Action | Expected |
|---|--------|----------|
| 1 | Log out, tap "Continue as Guest" | Redirects to Dashboard |
| 2 | Add an item | Item saves successfully |
| 3 | Firebase Console → Auth | Anonymous user created |
| 4 | Firebase Console → Firestore → users/{uid}/items | Item stored under anonymous uid |

### 2.3 Error Cases

| # | Action | Expected |
|---|--------|----------|
| 1 | Register with already-registered email | Error snackbar — does NOT say "email already in use" (no enumeration) |
| 2 | Login with wrong password | Error: "Invalid email or password" |
| 3 | Login with non-existent email | Same error (same message — no enumeration) |
| 4 | Enter email without @ symbol | Inline validation: "Enter a valid email" |
| 5 | Enter password <6 chars | Inline validation: "Min 6 characters" |
| 6 | Enter name >100 chars | Input capped at 100 characters |

### 2.4 Logout

| # | Action | Expected |
|---|--------|----------|
| 1 | From Dashboard, tap Logout | Redirects to Login |
| 2 | Login as different user | Other user's items NOT visible |

---

## 3. Item CRUD

### 3.1 Add Item — Validation

| # | Action | Expected |
|---|--------|----------|
| 1 | Submit with empty name | "Name is required" |
| 2 | Name field — type 101 chars | Capped at 100 |
| 3 | Notes field — type 1001 chars | Capped at 1000 |
| 4 | Valid name + category + expiry → Save | Item appears on Dashboard |

### 3.2 Edit Item

| # | Action | Expected |
|---|--------|----------|
| 1 | Tap item card on Dashboard | Edit screen opens with pre-filled values |
| 2 | Change name + expiry | Fields update |
| 3 | Tap Save | Dashboard shows updated values |
| 4 | Firestore → item document | `updatedAt` timestamp refreshed |

### 3.3 Delete Item

| # | Action | Expected |
|---|--------|----------|
| 1 | Delete item from Dashboard | Item removed from list |
| 2 | Firestore → items subcollection | Document deleted |
| 3 | Notification settings | No stale notification for deleted item (cancel verified in section 6) |

### 3.4 Dashboard Sections

Create items for each section and verify placement:

| Item expiry | Expected section |
|-------------|-----------------|
| Yesterday | Expired |
| Today | Expiring Today |
| 3 days | Within 7 Days |
| 15 days | Within 30 Days |
| 45 days or no expiry | Recently Added |

Verify: each item appears in exactly ONE section.

---

## 4. OCR Scanner Flow

### 4.1 Camera Scan — Medicine Package

| # | Action | Expected |
|---|--------|----------|
| 1 | Dashboard FAB → "Scan Product" | Scanner screen opens |
| 2 | Point camera at `EXP: MM/YYYY` label | OCR processes image |
| 3 | ScanResultCard appears | Detected expiry pre-filled |
| 4 | Tap "Add Item" | AddEditItemScreen opens with values pre-filled |
| 5 | Banner "Values pre-filled from label scan" | Visible above form |
| 6 | Verify/correct fields → Save | Item saved |

**Expected formats to test:** `EXP: 06/2027`, `Expiry: JUN 2027`, `Best Before: 31/12/2026`

### 4.2 Gallery Upload

| # | Action | Expected |
|---|--------|----------|
| 1 | Scanner screen → Gallery option | Photo picker opens |
| 2 | Select a clear product label photo | OCR processes image |
| 3 | ScanResultCard shows detected fields | Consistent with camera behavior |

### 4.3 No Text Found

| # | Action | Expected |
|---|--------|----------|
| 1 | Scan plain wall or blank paper | ScanResultCard shows empty name/expiry |
| 2 | "Add Item" still available | Opens AddEditItemScreen with empty fields (user fills manually) |
| 3 | App does NOT crash | Continues normally |

### 4.4 Partial Extraction

| # | Action | Expected |
|---|--------|----------|
| 1 | Scan blurry or low-contrast image | Partial result shown |
| 2 | User edits incorrect pre-fill | Form fields are editable |
| 3 | Save with corrected data | Item saved correctly |

---

## 5. Notification Flow

### 5.1 Permission Request

| # | Action | Expected |
|---|--------|----------|
| 1 | Fresh install — open app | No notification permission yet |
| 2 | Dashboard → tap bell icon (top-right) | Notification Settings screen opens |
| 3 | Permission status row | Shows "Denied — tap to request" |
| 4 | Tap permission row | Android OS permission dialog |
| 5 | Grant permission | Status updates to "Granted" |
| 6 | Deny permission | Status remains "Denied"; no crash |

### 5.2 Notification Scheduling on Create

| # | Action | Expected |
|---|--------|----------|
| 1 | Add item with expiry exactly 30 days from today | Item saved |
| 2 | Android Settings → Apps → Home Vault → Notifications | Scheduled alarms visible (Android 13+) |
| 3 | Add item with expiry 7 days from today | 7d + 1d + today notifications scheduled |
| 4 | Add item with expiry in the past | No notifications scheduled |
| 5 | Add item with no expiry date | No notifications scheduled |

### 5.3 Rescheduling on Edit

| # | Action | Expected |
|---|--------|----------|
| 1 | Add item with expiry 30 days away | 4 notifications scheduled |
| 2 | Edit item — change expiry to 60 days away | Old 4 slots cancelled; new 4 rescheduled |
| 3 | Edit item — remove expiry date | All 4 slots cancelled |
| 4 | Edit item — set expiry to yesterday | All past reminders skipped (no future notifications) |

### 5.4 Cancellation on Delete

| # | Action | Expected |
|---|--------|----------|
| 1 | Add item with expiry 30 days away | 4 notifications scheduled |
| 2 | Delete the item | All 4 notification slots cancelled |
| 3 | Verify (wait for scheduled time if testing near-term) | No notification fires for deleted item |

### 5.5 Notification Content

Set a test item expiry to today + 1 day and verify exact notification text:

| Slot | Expected Title | Expected Body |
|------|---------------|---------------|
| 30-day | "Expires in 30 days" | "Your [item name] expires in 30 days." |
| 7-day | "Expires in 7 days" | "Your [item name] expires in 7 days." |
| 1-day | "Expires tomorrow" | "Your [item name] expires tomorrow." |
| Today | "Expires today" | "Your [item name] expires today." |

All notifications fire at **09:00 AM local time**.

### 5.6 Enable / Disable Toggle

| # | Action | Expected |
|---|--------|----------|
| 1 | Open Notification Settings | Toggle shows ON |
| 2 | Toggle OFF | All pending notifications cancelled |
| 3 | Toggle ON | All current items rescheduled |
| 4 | Force-close and reopen | Toggle state persists (SharedPreferences) |
| 5 | With toggle OFF, add new item | No notifications scheduled |

### 5.7 App Restart — Notification Persistence

| # | Action | Expected |
|---|--------|----------|
| 1 | Add item with expiry 30 days away | Notifications scheduled in OS AlarmManager |
| 2 | Force-close and reopen app | Notifications remain in OS scheduler |
| 3 | Notification fires at 09:00 on scheduled day | Correct title/body displayed |

> **Known limitation:** Notifications may require app to open at least once after device reboot
> before the plugin's boot receiver reschedules them. See DECISIONS.md for details.

---

## 6. Offline Scenarios

| # | Scenario | Expected |
|---|---------|----------|
| 1 | Disable WiFi + mobile data → try Email login | Error snackbar; no crash |
| 2 | Disable WiFi + mobile data → try Google Sign-In | Error shown (Google auth fails gracefully) |
| 3 | Logged in → disable network → try add item | Error snackbar; item NOT added to Firestore |
| 4 | OCR scan (camera) with no internet | OCR still works (on-device model; no network needed) |
| 5 | Dashboard visible → disable network | Last Firestore snapshot still shown; no crash |
| 6 | Pull-to-refresh with no internet | Refresh indicator dismisses; error state or last data shown |

---

## 7. Permission Denial Scenarios

### 7.1 Notification Permission Denied

| # | Action | Expected |
|---|--------|----------|
| 1 | On first install, deny notification permission when prompted | App continues; no crash |
| 2 | Navigate to Notification Settings | Status shows "Denied" |
| 3 | Tap permission row | System dialog (if not permanently denied) or opens App Settings |
| 4 | Items added without notification permission | Items saved; notifications silently skipped |

### 7.2 Camera Permission Denied

| # | Action | Expected |
|---|--------|----------|
| 1 | Deny camera permission at OS prompt | — |
| 2 | Dashboard FAB → Scan Product | Error snackbar or graceful message; no crash |
| 3 | App remains usable | Manual add still works |
| 4 | OS Settings → re-grant camera | Scan works after re-grant |

### 7.3 Exact Alarm Permission (Android 12+)

| # | Action | Expected |
|---|--------|----------|
| 1 | Android 12+ device → check Settings → Apps → Special App Access → Alarms & Reminders | Home Vault listed |
| 2 | If denied — toggle notifications in app | App does not crash; may silently skip scheduling |
| 3 | Grant access | Notifications schedule normally |

---

## 8. Performance Checks

| Check | Target | Pass criteria |
|-------|--------|---------------|
| Cold start → Login screen | < 3 seconds | Login visible within 3s |
| Cold start → Dashboard (logged in) | < 3 seconds | Dashboard items visible within 3s |
| OCR processing (camera snap) | < 5 seconds | ScanResultCard shown within 5s |
| Firestore item save | < 2 seconds | Item appears in list within 2s |
| Dashboard pull-to-refresh | < 3 seconds | Indicator dismisses; data refreshed |
| Dashboard with 50+ items | Smooth scroll | No visible jank at 60fps |

---

## 9. Release Build Checks (Pre-Play Store)

These must be resolved before a release build is submitted.

| # | Check | Status | Notes |
|---|-------|--------|-------|
| 1 | Release signing keystore configured | ❌ BLOCKER | `build.gradle` uses `signingConfigs.debug` — must replace with production keystore before Play Store submission |
| 2 | `proguard-rules.pro` exists | ✅ | `android/app/proguard-rules.pro` present with Flutter + Firebase keep rules |
| 3 | `minifyEnabled true` for release | ✅ | R8 enabled in release build |
| 4 | App icon — all densities | ❌ Required | Default Flutter icon in use |
| 5 | Privacy Policy URL | ❌ Required | Play Store requires privacy policy |
| 6 | App version (`versionCode` / `versionName`) | ✅ | Managed via `flutter.versionCode` / `flutter.versionName` |
| 7 | Firebase `google-services.json` present | Verify | Gitignored — must be in place for build |
| 8 | `firebase_options.dart` configured | Verify | Gitignored — must match real Firebase project |
| 9 | Firestore security rules deployed | ✅ | `firestore.rules` committed; deploy: `firebase deploy --only firestore:rules` |
| 10 | `flutter analyze` clean | ✅ | 0 errors, 0 warnings in `lib/`; 6 info hints in test files only |

---

## 10. Test Results Template

Copy and fill in for each device tested:

```
Device: [Model] — Android [Version]
Date: [YYYY-MM-DD]
Build: debug / release

New User Flow:
  Registration:                [ ] Pass  [ ] Fail  Notes:
  First item add:              [ ] Pass  [ ] Fail  Notes:
  Session persistence:         [ ] Pass  [ ] Fail  Notes:

Auth:
  Email login/logout:          [ ] Pass  [ ] Fail  Notes:
  Google sign-in:              [ ] Pass  [ ] Fail  Notes:
  Guest sign-in:               [ ] Pass  [ ] Fail  Notes:
  Error cases (enumeration):   [ ] Pass  [ ] Fail  Notes:

Item CRUD:
  Add (manual):                [ ] Pass  [ ] Fail  Notes:
  Edit:                        [ ] Pass  [ ] Fail  Notes:
  Delete:                      [ ] Pass  [ ] Fail  Notes:
  Dashboard section placement: [ ] Pass  [ ] Fail  Notes:

OCR:
  Camera — medicine label:     [ ] Pass  [ ] Fail  Notes:
  Gallery upload:              [ ] Pass  [ ] Fail  Notes:
  No text / partial text:      [ ] Pass  [ ] Fail  Notes:

Notifications:
  Permission request:          [ ] Pass  [ ] Fail  Notes:
  Schedule on create:          [ ] Pass  [ ] Fail  Notes:
  Reschedule on edit:          [ ] Pass  [ ] Fail  Notes:
  Cancel on delete:            [ ] Pass  [ ] Fail  Notes:
  Notification content:        [ ] Pass  [ ] Fail  Notes:
  Enable/disable toggle:       [ ] Pass  [ ] Fail  Notes:

Offline:
  Login offline:               [ ] Pass  [ ] Fail  Notes:
  OCR offline:                 [ ] Pass  [ ] Fail  Notes:
  Dashboard offline:           [ ] Pass  [ ] Fail  Notes:

Permission Denial:
  Notification denied:         [ ] Pass  [ ] Fail  Notes:
  Camera denied:               [ ] Pass  [ ] Fail  Notes:

Performance:
  Cold start:                  [ ] <3s   [ ] >3s
  OCR processing:              [ ] <5s   [ ] >5s

Blocker issues found:
```
