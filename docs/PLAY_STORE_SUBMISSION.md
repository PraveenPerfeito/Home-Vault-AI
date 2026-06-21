# Home Vault — Play Store Submission Guide

## App Metadata

| Field | Value |
|-------|-------|
| App name | Home Vault |
| Package name | `com.viyalabs.home_vault` |
| Version | 1.0.0 (version code 1) |
| App category | **Productivity** |
| Min SDK | 21 (Android 5.0 Lollipop) |
| Target SDK | Flutter current (35) |
| Content rating (expected) | Everyone |

---

## Short Description (80 chars max)

```
Track expiry dates & home inventory — scan product labels with OCR.
```
*(67 chars — within limit)*

---

## Full Description

```
Home Vault helps you take control of your household inventory. Never let 
products expire unnoticed again.

KEY FEATURES

📦 Smart Inventory
• Add household items with category, purchase date, and expiry date
• 7 categories: Food, Medicine, Cosmetics, Baby Products, Electronics,
  Household, Other
• Edit or delete items at any time

📷 OCR Scanner
• Photograph or select a product label from your gallery
• AI-powered expiry date extraction from label text
• Product name auto-detection
• Works offline — no internet required for scanning

📊 Expiry Dashboard
• Colour-coded urgency: Expired, Today, This Week, This Month, Recently Added
• Total Items / Expiring Soon / Expired at a glance
• Pull-to-refresh for latest data

🔔 Smart Reminders
• Automatic notifications 30 days, 7 days, 1 day before expiry
• Notification on the day an item expires
• All reminders at 9 AM local time
• Enable / disable from the Settings screen

🔐 Secure & Private
• Sign in with Email, Google, or continue as Guest
• Your data is private — only you can access your items
• OCR processing is 100% on-device — photos are never uploaded
```

*(Total: ~720 chars — well within 4000-char limit. Add more detail if desired.)*

---

## Content Rating Questionnaire (IARC)

Complete this in Play Console → Policy → App content → Content rating.

| Question | Answer |
|----------|--------|
| Violence | None |
| Sexual content | None |
| Profanity or crude humour | None |
| Controlled substances (drugs, alcohol) | None |
| Gambling | None |
| User-generated content shared with others | No — content is private to the user |
| Location sharing with other users | No |
| Digital purchases / in-app billing | No |
| Collecting personal data | Yes — email, inventory items |

**Expected rating: Everyone (3+)**

---

## Data Safety Section (Play Console)

Complete in Play Console → Policy → App content → Data safety.

### Top-level questions

| Question | Answer |
|----------|--------|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** |
| Do you provide a way for users to request that their data be deleted? | **Yes** |

### Data types collected

| Category | Data type | Collected? | Shared? | Optional? | Purpose |
|----------|-----------|-----------|--------|-----------|---------|
| Personal info → Name | Display name | Yes | No | Yes | In-app personalisation |
| Personal info → Email address | Email | Yes | No | No (email auth) | Sign-in and account ID |
| Identifiers → User IDs | Firebase UID | Yes | No | No | Data isolation per user |
| Photos and videos → Photos | Camera / gallery image | No (on-device OCR; not stored) | No | Yes | Label scanning |
| App activity | None | — | — | — | — |
| App info and performance | None | — | — | — | — |

### Data collection practices

| Practice | Answer |
|----------|--------|
| Is data collection required for basic app functionality? | Email UID: Yes. Display name, camera: No |
| Is data processed ephemerally (photos)? | Yes — OCR images processed in memory and discarded |
| Is data transferred to a third party? | Yes — Firebase (Google) for auth and storage only |

For more detail see `docs/PRIVACY_POLICY_REQUIREMENTS.md`.

---

## Screenshots Checklist

**Requirements:** At least 2 screenshots. Up to 8. Portrait preferred.
**Recommended size:** 1080×1920 px or native device resolution.

| # | Screen | Content | Status |
|---|--------|---------|--------|
| 1 | Login screen | Email / Google / Guest buttons visible | Pending |
| 2 | Dashboard — items | 5+ items across 2+ expiry sections | Pending |
| 3 | Add Item form | Form fields with a sample item | Pending |
| 4 | Scanner — scan result | ScanResultCard with extracted name + date | Pending |
| 5 | Notification Settings | Toggle on, schedule info visible | Pending |

**How to capture:**
1. Install a debug or release build on a physical Android device
2. Pre-load 5–10 items with near-expiry dates to populate all dashboard sections
3. Use the device's screenshot shortcut (Power + Vol Down on most Android devices)
4. Transfer to PC via USB or Google Photos sync
5. Crop to a consistent aspect ratio (16:9 or 9:16)

---

## Feature Graphic

- **Size:** 1024×500 px
- **Format:** JPG or 24-bit PNG (no alpha)
- **Suggested content:** App icon centred on `#3D52D5` background with
  "Home Vault" in white text and the tagline
  "Track expiry dates. Never waste again."
- **Tools:** Canva, Figma, or Android Studio's vector asset editor

---

## Play Store Icon (512×512)

The Play Store listing requires a 512×512 PNG icon with **no alpha channel**
(solid background, no transparency).

The source `assets/icon/icon.png` is 1024×1024 with a solid `#3D52D5` background
— scale it down to 512×512.

**PowerShell (Windows):**
```powershell
Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Image]::FromFile("D:\Home-vault\assets\icon\icon.png")
$dst = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($dst)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($src, 0, 0, 512, 512)
$dst.Save("D:\Home-vault\assets\icon\icon_512.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $dst.Dispose(); $src.Dispose()
Write-Host "Saved assets/icon/icon_512.png"
```

Upload `assets/icon/icon_512.png` to Play Console → Store listing → App icon.

---

## Internal Testing Track — Step-by-Step

### 1. Create the app in Play Console

1. Go to [play.google.com/console](https://play.google.com/console)
2. Create app → App name: "Home Vault"
3. Default language: English (United States)
4. App or game: App
5. Free or paid: Free

### 2. Complete Store listing

- App name: Home Vault
- Short description: (see above)
- Full description: (see above)
- Screenshots: minimum 2 from the checklist above
- Feature graphic: 1024×500 px
- App icon: 512×512 px, no alpha
- Category: **Productivity**
- Email: `praveen@blindmatrix.com`
- Privacy policy URL: (your hosted URL — required before submission)

### 3. Set up App Signing

- Release → Setup → App signing
- Accept Google Play App Signing terms
- Upload your upload key certificate (export from your keystore)
- Google will re-sign the AAB for distribution

### 4. Upload the AAB

- Release → Testing → Internal testing → Create new release
- Upload: `build/app/outputs/bundle/release/app-release.aab`
- Release name: 1.0.0 (1)
- Release notes: "Initial internal testing release"

### 5. Complete required policy sections

| Section | Where in Play Console | Status |
|---------|----------------------|--------|
| Content rating | Policy → App content → Content rating | Pending |
| Privacy policy | Policy → App content → Privacy policy | Pending — needs hosted URL |
| Data safety | Policy → App content → Data safety | Pending — use answers above |
| App access | Policy → App content → App access | Add test credentials if login is required |
| Ads | Policy → App content → Ads | Select "No ads" |
| Target audience | Policy → App content → Target audience | Age 18+ (safest for data apps) |

### 6. Add internal testers

- Testing → Internal testing → Testers tab
- Add email: `praveen@blindmatrix.com`
- Save → copy opt-in URL → test on your own device first

### 7. Submit for review

- Review → Submit for review
- Internal testing does not require Google review (goes live immediately for testers)
- Production track requires 2–7 day review

---

## Pre-Submission Gate Checklist

Work through this before uploading to Play Console:

### Signing
- [ ] Release keystore generated and backed up (see `docs/ANDROID_SIGNING.md`)
- [ ] `android/key.properties` created and gitignored
- [ ] `android/app/build.gradle` updated to `signingConfigs.release`
- [ ] SHA-1 added to Firebase Console
- [ ] `google-services.json` updated and in `android/app/`
- [ ] `flutterfire configure` re-run to update `firebase_options.dart`

### Build
- [ ] `flutter clean && flutter build appbundle --release` — succeeds with no errors
- [ ] AAB verified with `keytool -printcert` — shows release certificate

### Store assets
- [ ] Privacy policy hosted at a stable HTTPS URL
- [ ] Screenshots captured (min 2) from physical device
- [ ] Feature graphic created (1024×500 px)
- [ ] Play Store icon prepared (512×512 px, no alpha)

### Testing
- [ ] Real Device Test Plan passed (`docs/RELEASE_CANDIDATE_TEST_PLAN.md`)
  - Auth flows (email, Google, guest)
  - Item CRUD (add, edit, delete)
  - OCR scan on 2+ product types
  - Notifications received on schedule
  - No crashes on tested flows

### Play Console
- [ ] Content rating questionnaire completed
- [ ] Data safety form submitted
- [ ] App access info provided
- [ ] Internal testing track created and AAB uploaded
- [ ] At least one tester invited and opted in

---

## Known Remaining Work (Post-Internal Testing)

These are not blocking for Internal Testing but are required for Production track:

| Item | Notes |
|------|-------|
| Account self-deletion in-app | Currently requires email to developer; Play Console may flag this |
| Firebase Crashlytics | Optional for MVP; recommended before Production track |
| `READ_MEDIA_IMAGES` runtime permission rationale | Should show a rationale dialog if user denies gallery permission |
| Notification permission rationale | Shown by Android OS on API 33+; no app-level rationale needed |
