# Home Vault — Real Device Test Plan

**Version:** 2.0  
**Target platform:** Android (physical device or emulator with Google Play Services)  
**Scope:** Phase 1–5 functionality including local notifications

---

## Prerequisites

- Debug APK installed on device
- Google account available for Google Sign-In test
- Device camera working and permissions not pre-denied
- Internet connection available (unless testing failure scenarios)
- Firebase project active (Auth, Firestore, FCM enabled)

---

## 1. Authentication Tests

### 1.1 Email Registration

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open app fresh install | Splash screen shows briefly, redirects to Login |
| 2 | Tap "Sign In with Email" | Email + Password fields appear |
| 3 | Tap Register link | Register screen opens |
| 4 | Enter name, valid email, 6+ char password | No validation errors |
| 5 | Tap "Create Account" | Loading indicator → redirects to Dashboard |
| 6 | Verify user appears in Firebase Console → Auth | User record created |

### 1.2 Email Login

| Step | Action | Expected |
|------|--------|----------|
| 1 | Log out (if logged in), open Login | Login screen |
| 2 | Tap "Sign In with Email", enter credentials | Fields appear |
| 3 | Enter correct email + password | Redirects to Dashboard |
| 4 | Enter wrong password | Error: "Invalid email or password" |
| 5 | Enter non-existent email | Error: "Invalid email or password" (same — no enumeration) |

### 1.3 Google Sign-In

| Step | Action | Expected |
|------|--------|----------|
| 1 | From Login, tap "Continue with Google" | Google account picker opens |
| 2 | Select Google account | Redirects to Dashboard |
| 3 | Verify user in Firebase Console → Auth | Google provider shown |
| 4 | Sign out, tap Google again (same account) | Logs in without picker (token cached) |

### 1.4 Guest Login

| Step | Action | Expected |
|------|--------|----------|
| 1 | From Login, tap "Continue as Guest" | Redirects to Dashboard |
| 2 | Add an item | Item saves successfully |
| 3 | Verify in Firebase Console → Auth | Anonymous user created |
| 4 | Verify in Firestore → users/{uid}/items | Item stored under anonymous uid |

### 1.5 Logout

| Step | Action | Expected |
|------|--------|----------|
| 1 | From Dashboard, tap Logout | Redirects to Login |
| 2 | Verify no items visible on Dashboard (after re-login with different account) | Items are user-scoped |

### 1.6 App Restart — Session Persistence

| Step | Action | Expected |
|------|--------|----------|
| 1 | Log in with email | Dashboard visible |
| 2 | Force-close app | — |
| 3 | Reopen app | Splash → Dashboard (not Login) — session persisted |
| 4 | Log out, force-close | — |
| 5 | Reopen app | Splash → Login (no session) |

---

## 2. Item CRUD Tests

### 2.1 Add Item — Manual

| Step | Action | Expected |
|------|--------|----------|
| 1 | On Dashboard, tap FAB → "Add Manually" | Add Item screen opens |
| 2 | Leave name blank, tap Save | Validation error: "Name is required" |
| 3 | Enter name, select category "Food" | Category chip highlights |
| 4 | Tap expiry date field | Date picker opens |
| 5 | Select a date 3 months in future | Date appears in field |
| 6 | Tap Save | Returns to Dashboard, item appears in list |
| 7 | Verify in Firestore → users/{uid}/items | Document created with correct fields |

### 2.2 Add Item — OCR Pre-fill

| Step | Action | Expected |
|------|--------|----------|
| 1 | On Dashboard, tap FAB → "Scan Product" | Scanner screen opens |
| 2 | Point camera at product with visible expiry date | OCR processes image |
| 3 | View ScanResultCard | Detected name/expiry shown (or empty if not extracted) |
| 4 | Tap "Add Item" | Add Item screen opens with pre-filled fields |
| 5 | Banner "Values pre-filled from label scan" visible | Confirm banner present |
| 6 | Review/correct fields, tap Save | Item saved |

### 2.3 Edit Item

| Step | Action | Expected |
|------|--------|----------|
| 1 | From Dashboard, tap any item card | Item detail or Edit screen opens |
| 2 | Change name field | Field updates |
| 3 | Change expiry date | Date updates |
| 4 | Tap Save | Returns to Dashboard, updated values shown |
| 5 | Verify in Firestore | Document `updatedAt` field updated |

### 2.4 Delete Item

| Step | Action | Expected |
|------|--------|----------|
| 1 | From Dashboard, access delete action on item | Confirmation shown |
| 2 | Confirm deletion | Item removed from list |
| 3 | Verify in Firestore | Document deleted from `items` subcollection |

### 2.5 Dashboard Stats

| Step | Action | Expected |
|------|--------|----------|
| 1 | Add item with expiry 3 days from today | — |
| 2 | Add item with expiry date in the past | — |
| 3 | View Dashboard stats row | "Expiring Soon" count ≥ 1, "Expired" count ≥ 1 |

---

## 3. OCR Tests

### 3.1 Medicine Package

| Step | Action | Expected |
|------|--------|----------|
| 1 | Scan medicine strip or box with `EXP: MM/YYYY` | Expiry extracted |
| 2 | Name field pre-fills with tablet/capsule name | Name extracted or empty |
| 3 | If wrong expiry — manually correct | Form editable |

**Common formats on medicine:** `EXP: 06/2027`, `Expiry: JUN 2027`, `BB: 02/28` (2-digit — known limitation)

### 3.2 Food Package

| Step | Action | Expected |
|------|--------|----------|
| 1 | Scan food packet with `Best Before: DD/MM/YYYY` | Date extracted correctly |
| 2 | Multi-line label (ingredients + name + date) | Correct line chosen as product name |

**Common formats on food:** `Best Before: 31/12/2026`, `Best Before Dec 2026`

### 3.3 Cosmetics Package

| Step | Action | Expected |
|------|--------|----------|
| 1 | Scan cosmetic tube/bottle | Expiry extracted from `EXP` or month-name format |
| 2 | Brand name + product type identified | Name extraction picks brand line |

### 3.4 Gallery Upload

| Step | Action | Expected |
|------|--------|----------|
| 1 | Scanner screen → select "Gallery" | Photo picker opens |
| 2 | Choose photo of a product label | OCR processes the image |
| 3 | Result card shows detected text | Consistent with camera capture behavior |

---

## 4. Failure Scenarios

### 4.1 No Internet Connection

| Step | Action | Expected |
|------|--------|----------|
| 1 | Disable WiFi + mobile data | — |
| 2 | Try Email login | Error snackbar: "An error occurred." (not a crash) |
| 3 | Try Google Sign-In | Error shown (Google auth fails gracefully) |
| 4 | Try saving item (if already logged in offline) | Error snackbar shown |
| 5 | OCR scan (no internet needed — on-device) | OCR still works offline |

### 4.2 Camera Permission Denied

| Step | Action | Expected |
|------|--------|----------|
| 1 | Deny camera permission at OS prompt | — |
| 2 | Tap "Scan Product" | Error snackbar or graceful message |
| 3 | App should NOT crash | App remains usable |
| 4 | Go to OS Settings → re-grant camera | Scan works after re-grant |

### 4.3 OCR Fails — No Text Found

| Step | Action | Expected |
|------|--------|----------|
| 1 | Scan a blank wall or plain surface | — |
| 2 | View result | ScanResultCard shows empty name/expiry |
| 3 | "Add Item" still available | Opens Add Item screen with empty fields |

### 4.4 OCR Fails — Partial Extraction

| Step | Action | Expected |
|------|--------|----------|
| 1 | Scan blurry or low-light image | — |
| 2 | Name extracted incorrectly | User can correct in form |
| 3 | Expiry not extracted | Expiry field empty — user must fill manually |

### 4.5 Authentication Error Cases

| Step | Action | Expected |
|------|--------|----------|
| 1 | Register with already-used email | Error: "An error occurred." (not "email already in use" — no enumeration) |
| 2 | Enter email with no @ symbol | Inline validation: "Enter a valid email" |
| 3 | Enter 5-char password | Inline validation: "Min 6 characters" |

---

## 5. Performance Checks

| Check | Target | Pass Criteria |
|-------|--------|---------------|
| App cold start → Login screen | < 3 seconds | Login screen visible within 3s |
| App cold start → Dashboard (logged in) | < 3 seconds | Dashboard items visible within 3s |
| OCR processing (camera snap) | < 5 seconds | Result card shown within 5s |
| Firestore item save | < 2 seconds | Item appears in list within 2s |

---

## 6. Notification Tests (Phase 5)

### 6.1 Permission Request

| Step | Action | Expected |
|------|--------|----------|
| 1 | Fresh install — open app, navigate to Dashboard | — |
| 2 | Tap bell icon in AppBar | Notification Settings screen opens |
| 3 | Observe permission status | Shows "Denied — tap to request permission" (not yet granted) |
| 4 | Tap permission row | OS permission dialog appears |
| 5 | Grant permission | Status updates to "Granted" |
| 6 | Deny permission | Status remains "Denied"; SnackBar shows instructions |

### 6.2 Notification Scheduling — Create Item

| Step | Action | Expected |
|------|--------|----------|
| 1 | Add item with expiry date exactly 30 days from today | Item saved |
| 2 | Check device Settings → Apps → Home Vault → Notifications | Scheduled notifications visible (on Android 13+) |
| 3 | Add item with expiry date 7 days from today | Saved; 7-day + 1-day + today reminders scheduled |
| 4 | Add item with expiry in the past | Saved; no notifications scheduled (all in past) |
| 5 | Add item with no expiry date | Saved; no notifications scheduled |

### 6.3 Notification Rescheduling — Edit Expiry Date

| Step | Action | Expected |
|------|--------|----------|
| 1 | Add item with expiry 30 days away | Notifications scheduled |
| 2 | Edit item — change expiry to 60 days away | Old notifications cancelled; new 30d/7d/1d/today rescheduled |
| 3 | Edit item — remove expiry date | All notifications for that item cancelled |
| 4 | Edit item — set expiry to yesterday | No future notifications scheduled |

### 6.4 Notification Cancellation — Delete Item

| Step | Action | Expected |
|------|--------|----------|
| 1 | Add item with expiry 30 days away | Notifications scheduled |
| 2 | Delete the item | All 4 notification slots cancelled |
| 3 | Verify no stale notifications fire (wait until scheduled time if testing fast) | No notification appears |

### 6.5 Notification Content Verification

To test notification content without waiting weeks, temporarily set expiry to today + 1 minute and verify the exact notification text:

| Slot | Expected Title | Expected Body |
|------|---------------|---------------|
| Expiry day | "Expires today" | "Your [item name] expires today." |
| 1 day before | "Expires tomorrow" | "Your [item name] expires tomorrow." |
| 7 days before | "Expires in 7 days" | "Your [item name] expires in 7 days." |
| 30 days before | "Expires in 30 days" | "Your [item name] expires in 30 days." |

### 6.6 Enable / Disable Toggle

| Step | Action | Expected |
|------|--------|----------|
| 1 | Open Notification Settings | Toggle shows "ON" |
| 2 | Toggle OFF | All pending notifications cancelled |
| 3 | Toggle ON | All current items re-scheduled |
| 4 | Force-close and reopen app | Toggle state persists (SharedPreferences) |
| 5 | With toggle OFF, add new item | No notifications scheduled for new item |

### 6.7 App Restart — Notification Persistence

| Step | Action | Expected |
|------|--------|----------|
| 1 | Add item with expiry 30 days away | Notifications scheduled at OS level |
| 2 | Force-close and reopen app | Notifications remain in OS scheduler |
| 3 | Wait for notification time (or set temp date) | Notification fires correctly |

> **Note:** Local notifications persist in the Android `AlarmManager` across app restarts. They do NOT persist across device reboots — this is a known limitation for Phase 5 MVP. A boot receiver is declared in AndroidManifest to allow future re-scheduling on boot.

---

## 7. Test Results Template

Copy this section and fill in for each device tested.

```
Device: [Model] — Android [Version]
Date: [YYYY-MM-DD]
APK version: 1.0.0+1

Auth Tests:
  Email login:       [ ] Pass  [ ] Fail  Notes:
  Google login:      [ ] Pass  [ ] Fail  Notes:
  Guest login:       [ ] Pass  [ ] Fail  Notes:
  Logout:            [ ] Pass  [ ] Fail  Notes:
  App restart:       [ ] Pass  [ ] Fail  Notes:

CRUD Tests:
  Add manual:        [ ] Pass  [ ] Fail  Notes:
  Add via OCR:       [ ] Pass  [ ] Fail  Notes:
  Edit item:         [ ] Pass  [ ] Fail  Notes:
  Delete item:       [ ] Pass  [ ] Fail  Notes:
  Dashboard stats:   [ ] Pass  [ ] Fail  Notes:

OCR Tests:
  Medicine package:  [ ] Pass  [ ] Fail  Notes:
  Food package:      [ ] Pass  [ ] Fail  Notes:
  Cosmetics:         [ ] Pass  [ ] Fail  Notes:
  Gallery upload:    [ ] Pass  [ ] Fail  Notes:

Failure Scenarios:
  No internet:       [ ] Pass  [ ] Fail  Notes:
  Camera denied:     [ ] Pass  [ ] Fail  Notes:
  Blank scan:        [ ] Pass  [ ] Fail  Notes:
  Partial scan:      [ ] Pass  [ ] Fail  Notes:
  Auth errors:       [ ] Pass  [ ] Fail  Notes:

Performance:
  Cold start:        [ ] < 3s  [ ] > 3s
  OCR processing:    [ ] < 5s  [ ] > 5s

Notification Tests:
  Permission request:      [ ] Pass  [ ] Fail  Notes:
  Schedule on create:      [ ] Pass  [ ] Fail  Notes:
  Reschedule on edit:      [ ] Pass  [ ] Fail  Notes:
  Cancel on delete:        [ ] Pass  [ ] Fail  Notes:
  Notification content:    [ ] Pass  [ ] Fail  Notes:
  Enable/disable toggle:   [ ] Pass  [ ] Fail  Notes:
  Persist across restart:  [ ] Pass  [ ] Fail  Notes:

Overall: [ ] PASS  [ ] FAIL
Blocker issues found:
```

