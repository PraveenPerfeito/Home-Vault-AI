# Home Vault — Privacy Policy Requirements

## Purpose

This document specifies all data collected and processed by Home Vault.
Use it to draft the public-facing Privacy Policy hosted at a stable HTTPS URL.

Google Play requires a privacy policy for apps that:
- Request dangerous permissions (`CAMERA`, `READ_MEDIA_IMAGES`, `POST_NOTIFICATIONS`)
- Collect personal data (email address, user-generated content)
- Use third-party services (Firebase) that may process personal data

---

## Data Collected

### 1. Account Data (Firebase Authentication)

| Data | Source | Purpose | Retention |
|------|--------|---------|-----------|
| Email address | User input at registration | Account identification and sign-in | Until account deleted |
| Display name | User input at registration | In-app personalisation | Until account deleted |
| Google account email + profile | Google Sign-In OAuth | Authentication | Until account deleted |
| Firebase UID | Auto-generated | Identifying the user's Firestore subcollection | Until account deleted |
| Anonymous session token | Auto-generated (guest mode) | Guest session — no email required | Session duration only; cleared on sign-out |

### 2. Inventory Data (Cloud Firestore)

All inventory data is stored in a user-scoped Firestore subcollection
(`users/{uid}/items/{itemId}`) that is inaccessible to any other user.
Firestore security rules enforce this isolation.

| Data | Source | Purpose | Retention |
|------|--------|---------|-----------|
| Item name | User input / OCR pre-fill | Inventory record | Until item deleted by user |
| Item category | User selection | Organisation and filtering | Until item deleted |
| Expiry date | User input / OCR pre-fill | Reminder scheduling | Until item deleted |
| Purchase date | User input | Record keeping | Until item deleted |
| Notes | User input | Personal annotations | Until item deleted |
| `createdAt` / `updatedAt` timestamps | Auto-generated | Sort order and audit trail | Until item deleted |

### 3. OCR Processing (Google ML Kit — On-Device Only)

| Data | Source | Purpose | Retention |
|------|--------|---------|-----------|
| Camera image / gallery photo | User capture or gallery selection | OCR text extraction from product label | **Not stored** — processed in memory and discarded immediately |
| Extracted text (OCR result) | ML Kit on-device model | Expiry date and product name extraction to pre-fill the Add Item form | **Not stored** — used to populate the UI only |

**Key privacy fact:** OCR processing runs entirely **on the device** using
Google ML Kit's local model. No image or OCR text is ever uploaded to any server.
The user's photo is never persisted by the app.

### 4. Notification Preferences (On-Device Only)

| Data | Source | Purpose | Retention |
|------|--------|---------|-----------|
| Notifications enabled/disabled state | User toggle in Settings | Respecting user preference for local reminders | On-device (SharedPreferences); cleared on app uninstall |
| Scheduled notification entries | App logic | Pending expiry reminders | Managed by Android OS scheduler; cleared when item is deleted or notifications disabled |

**Key privacy fact:** All notification scheduling is on-device using
`flutter_local_notifications`. No notification data is sent to any remote server.

---

## Data NOT Collected

The app **does not** collect:

- Location data
- Contacts or phone book
- Unique device identifiers (IMEI, advertising ID)
- Clipboard content
- Files outside the user's selected gallery image
- Browsing history or app usage across other apps
- Payment card information

---

## Data Storage and Security

| Store | What | Where | Encrypted? |
|-------|------|-------|-----------|
| Cloud Firestore | Account data, inventory items | Google Cloud (default region) | Yes — at rest (AES-256) and in transit (TLS 1.2+) |
| Firebase Authentication | Email, UID, OAuth tokens | Google Cloud | Yes |
| SharedPreferences | Notifications enabled toggle (boolean only) | Local device | No — non-sensitive preference |
| Android OS Notification Scheduler | Pending notification entries | Local device | Managed by Android OS |

---

## Third-Party Data Sharing

| Third Party | Data Shared | Why | Their Privacy Policy |
|-------------|------------|-----|---------------------|
| Google Firebase (Auth + Firestore) | Email, UID, inventory items | Core app functionality — authentication and data storage | [firebase.google.com/support/privacy](https://firebase.google.com/support/privacy) |
| Google ML Kit | Camera image (on-device only; **never uploaded**) | OCR text recognition | [developers.google.com/ml-kit/terms](https://developers.google.com/ml-kit/terms) |
| Google Play Services | Android crash reporting | Android OS managed; not app-initiated | Google's Privacy Policy |

**The app does NOT share data with:**
- Advertising networks or ad tech platforms
- Analytics platforms (no Firebase Analytics)
- Data brokers
- Any other third parties not listed above

---

## Permissions and Their Purpose

| Android Permission | Dangerous? | Purpose | Required? |
|-------------------|-----------|---------|----------|
| `INTERNET` | No | Firebase network requests | Yes |
| `CAMERA` | Yes | Photograph product labels for OCR scanning | No — denied camera still allows gallery selection and manual entry |
| `READ_MEDIA_IMAGES` | Yes (API 33+) | Select product image from gallery for OCR | No — denied gallery still allows camera and manual entry |
| `POST_NOTIFICATIONS` | Yes (API 33+) | Display expiry reminder notifications | No — denied means reminders are silently skipped |
| `SCHEDULE_EXACT_ALARM` | Special | Schedule reminders at exact times | Yes for notification feature |
| `RECEIVE_BOOT_COMPLETED` | No | Reschedule notifications after device reboot | Yes for notification feature |

All dangerous permissions (`CAMERA`, `READ_MEDIA_IMAGES`, `POST_NOTIFICATIONS`)
are requested **at runtime**, not at install. The user can deny any of them and
still use the core item management features.

---

## User Rights

| Right | How to Exercise |
|-------|----------------|
| View all personal data | All data is visible within the app (dashboard + item list) |
| Edit data | Edit any item from the dashboard |
| Delete individual items | Long-press or edit → delete |
| Disable notifications | Settings → Notification Settings → toggle off |
| Delete account and all data | Email `praveen@blindmatrix.com` — account and all Firestore data deleted within 30 days |
| Withdraw consent / stop data collection | Delete account or uninstall the app |
| Export data | Not yet available — planned for a future version |

---

## Children's Privacy

Home Vault is intended for users **aged 13 and above**. The app does not
knowingly collect data from children under 13. If you believe a child under 13
has created an account, contact `praveen@blindmatrix.com` for immediate deletion.

---

## Privacy Policy Content Requirements

When drafting the hosted Privacy Policy page, include all of the following:

1. **Introduction** — App name, developer name (`Viya Labs / praveen@blindmatrix.com`), effective date
2. **Data collected** — Use the tables above (account, inventory, OCR, notifications)
3. **Why collected** — Core functionality; not for advertising or profiling
4. **How stored** — Firebase (Google Cloud), on-device only for notifications/preferences
5. **Data sharing** — Firebase, ML Kit (on-device only), no ad networks
6. **Retention** — Until user deletes items or requests account deletion
7. **User rights** — View, edit, delete items; request account deletion via email
8. **Children's privacy** — 13+ only; contact for under-13 deletion
9. **Contact** — `praveen@blindmatrix.com`
10. **Policy changes** — Users notified via app update notes
11. **Effective date** — Date of publication

**Recommended hosting options (all free):**
- GitHub Pages: `https://username.github.io/home-vault-privacy`
- Firebase Hosting: `https://your-project.web.app/privacy`
- Simple GitHub Gist rendered via a GitHub Pages theme

The URL must be **HTTPS**, **publicly accessible without sign-in**, and **stable**
(the same URL must remain valid as long as the app is published).

---

## Data Safety Answers (Play Console — Data Safety Tab)

Use these when completing the Data Safety section in Google Play Console:

**Does your app collect or share any of the required user data types?** → Yes

**Is all of the user data collected by your app encrypted in transit?** → Yes

**Do you provide a way for users to request that their data be deleted?** → Yes

### Data types collected

| Category | Data type | Collected | Shared | Ephemeral | Required | Purpose |
|----------|-----------|-----------|--------|-----------|----------|---------|
| Personal info | Name | Yes | No | No | No | Display name in app |
| Personal info | Email address | Yes | No | No | Yes | Account sign-in |
| Identifiers | User IDs | Yes | No | No | Yes | Firebase data isolation |
| Photos and videos | Photos | No (on-device OCR only) | No | Yes | No | Label scanning |
| App activity | App interactions | No | No | — | — | — |
| App info & performance | Crash logs | No | No | — | — | — |
