# Home Vault — Android Release Signing Guide

## Overview

The production release build must be signed with a private keystore before
submitting to the Play Store. The debug keystore (`signingConfigs.debug`) used
during development is **not accepted** by the Play Store.

This guide covers:
1. Generating the release keystore
2. Configuring `android/key.properties` (gitignored)
3. Updating `android/app/build.gradle` to use the release signing config
4. Updating the Firebase SHA-1 fingerprint
5. Building and verifying the signed AAB

---

## Step 1 — Generate the Release Keystore

Run **once**. Store the resulting `.jks` file **outside the repository** in a
secure location.

```bash
keytool -genkey -v \
  -keystore ~/home_vault_release.jks \
  -alias home_vault \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

You will be prompted for:
- **Keystore password** — choose a strong password (min 16 chars)
- **Key alias password** — can match the keystore password
- **Name, organisation, location** — used in the certificate; not user-visible

**Back up `home_vault_release.jks` immediately in at least 2 locations:**
- Password manager attachment, encrypted cloud drive, or offline USB
- If this file is lost you **cannot update the app** on the Play Store — you must
  unpublish and republish under a new package ID

> **NEVER commit `home_vault_release.jks` or any `.jks`/`.keystore` file to the
> repository.** Both extensions are gitignored — see `.gitignore`.

---

## Step 2 — Create `android/key.properties`

Create the file at `android/key.properties` (this file is gitignored):

```properties
storePassword=<keystore-password>
keyPassword=<key-alias-password>
keyAlias=home_vault
storeFile=<absolute-path-to>/home_vault_release.jks
```

**Example — macOS / Linux:**
```properties
storePassword=MyStrongPass123!
keyPassword=MyStrongPass123!
keyAlias=home_vault
storeFile=/Users/praveen/home_vault_release.jks
```

**Example — Windows (use forward slashes):**
```properties
storePassword=MyStrongPass123!
keyPassword=MyStrongPass123!
keyAlias=home_vault
storeFile=C:/Users/prave/home_vault_release.jks
```

---

## Step 3 — Update `android/app/build.gradle`

Replace the entire file with the following. The key changes are:
- Read `key.properties` at the top of the `android {}` block
- Add `signingConfigs.release` that reads from `key.properties`
- Change `buildTypes.release.signingConfig` from `signingConfigs.debug` to
  `signingConfigs.release`

```groovy
plugins {
    id "com.android.application"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"
}

// Redirect build output to where Flutter expects it (fixes cross-drive path on Windows)
buildDir = new File(rootProject.projectDir.parentFile, "build/app")

// ── Read signing credentials from key.properties (gitignored) ────────────────
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace "com.viyalabs.home_vault"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    signingConfigs {
        release {
            keyAlias     = keystoreProperties['keyAlias']
            keyPassword  = keystoreProperties['keyPassword']
            storeFile    = keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword = keystoreProperties['storePassword']
        }
    }

    defaultConfig {
        applicationId = "com.viyalabs.home_vault"
        minSdkVersion = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"
            signingConfig signingConfigs.release   // ← production keystore
        }
    }
}

flutter {
    source = "../.."
}
```

---

## Step 4 — Update Firebase SHA-1 Fingerprint

Google Sign-In requires the SHA-1 fingerprint of the **release** keystore to be
registered in the Firebase Console (the debug SHA-1 used during development is
different).

```bash
# Extract the SHA-1 of the release keystore
keytool -list -v \
  -keystore ~/home_vault_release.jks \
  -alias home_vault
```

Then:
1. Firebase Console → Project Settings → Your Apps → Android app (`com.viyalabs.home_vault`)
2. Under "SHA certificate fingerprints" → Add fingerprint → paste the SHA-1
3. Download the updated `google-services.json`
4. Place it at `android/app/google-services.json` (gitignored — overwrite the existing file)
5. Re-run `flutterfire configure` to regenerate `lib/core/config/firebase_options.dart`:
   ```bash
   flutterfire configure
   ```

---

## Step 5 — Build and Verify the Release AAB

```bash
# Clean first to ensure no stale debug artifacts
flutter clean && flutter pub get

# Build release App Bundle (Play Store requires AAB, not APK)
flutter build appbundle --release

# Output location:
# build/app/outputs/bundle/release/app-release.aab
```

**Verify the AAB is signed with the release key** (not the debug key):
```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

The output should show your name/org from Step 1, not "Android Debug".

---

## Step 6 — Play App Signing (Recommended)

Google Play App Signing lets Google manage the distribution signing key. You
upload an AAB signed with your upload key; Google re-signs it for distribution.

Benefits:
- Google can recover your app if the upload keystore is lost
- Smaller download size via AAB optimisation per device

To opt in: Play Console → Release → Setup → App signing → Accept terms.

---

## Security Checklist

- [ ] `home_vault_release.jks` stored outside the repo and backed up
- [ ] `android/key.properties` created and confirmed gitignored
- [ ] Keystore password stored in a password manager
- [ ] SHA-1 fingerprint added to Firebase Console
- [ ] Updated `google-services.json` in `android/app/` (gitignored)
- [ ] `signingConfig signingConfigs.release` confirmed in `build.gradle`
- [ ] Release AAB verified with `keytool -printcert` — shows release certificate

---

## File Locations Reference

| File | Location | Committed to repo? |
|------|----------|--------------------|
| `home_vault_release.jks` | Outside repo (e.g., `~/` or password manager) | **NO** |
| `android/key.properties` | `android/key.properties` | **NO — gitignored** |
| `android/app/google-services.json` | `android/app/` | **NO — gitignored** |
| `lib/core/config/firebase_options.dart` | `lib/core/config/` | **NO — gitignored** |
| `android/app/build.gradle` | In repo | **YES — no secrets** |
| `android/app/proguard-rules.pro` | In repo | **YES** |
| `firestore.rules` | In repo | **YES** |
