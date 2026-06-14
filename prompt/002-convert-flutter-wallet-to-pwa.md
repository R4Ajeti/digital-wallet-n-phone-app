# 02 - Convert Flutter Wallet App to Progressive Web App for iOS Installation

## Branch Name

```bash
02-convert-flutter-wallet-to-pwa
```

## Task Title

**02 - Convert Flutter Wallet App to Progressive Web App for iOS Installation**

---

## Prompt

Can you implement task `02-convert-flutter-wallet-to-pwa` for this Flutter project?

## Goal

Convert the current Flutter mobile wallet app into a Progressive Web App so it can be installed on iOS through Safari without Xcode, provisioning profiles, signing certificates, or TestFlight.

## Context

The project was already analyzed and the verdict was positive: it is a good PWA candidate.

The existing UI, QR generation, Firebase REST data model, and offline queue can mostly remain.

This should be a moderate platform adaptation, not a full rewrite.

## Important Security Notes

Do **not** commit any of the following:

- Secrets
- Private Firebase keys
- Tokens
- `.env` files
- Sponsor codes
- QR codes
- Credentials
- Private local files

Existing public Firebase client configuration can remain only if it is already part of the app and safe for client-side usage.

---

## Tasks

### 1. Create a New Branch

Create and use this branch:

```bash
git checkout -b 02-convert-flutter-wallet-to-pwa
```

---

### 2. Add Flutter Web Support

Run:

```bash
flutter create --platforms=web .
```

This should generate:

```text
web/index.html
web/manifest.json
PWA icons
Flutter web service-worker support
```

Then verify the project can build:

```bash
flutter build web --release
```

Expected result:

The Flutter web build should complete successfully and produce the deployment bundle in:

```text
build/web
```

---

### 3. Replace Native `dart:io` HTTP Usage

The following files currently use `dart:io` / `HttpClient`, which does not work on Flutter web:

```text
lib/services/auth_service.dart
lib/services/database_service.dart
```

Add the cross-platform HTTP package:

```bash
flutter pub add http
```

Then replace `HttpClient` with `package:http`.

Keep the current Firebase REST API architecture unless a small change is clearly needed.

Do **not** migrate to FlutterFire unless it is necessary.

Expected result:

Authentication and database requests should work on:

- Android
- iOS
- Web

---

### 4. Redesign Local Image Persistence for Web

The following files use filesystem-based image handling and `File` / `Image.file`, which does not work on web:

```text
lib/services/local_image_service.dart
lib/widgets/local_image_editor.dart
lib/widgets/profile_card.dart
lib/widgets/qr_ticket_widget.dart
```

Update image handling so it works on web.

Preferred options:

#### Option A: Local-only

Store image bytes using browser-compatible storage and render with:

```dart
Image.memory(...)
```

This is simpler and good if the image only needs to exist on the same browser/device.

#### Option B: Cross-device

Upload images to Firebase Storage and save the download URL.

This is better if images must:

- Survive browser storage clearing
- Sync across devices
- Be available after reinstalling the PWA
- Be shared between user sessions

Choose the simplest reliable approach for this project.

If images need to survive browser storage clearing or sync across devices, prefer Firebase Storage.

---

### 5. Adapt QR Scanning for Web

The project uses `mobile_scanner`, which supports web.

Update web-specific behavior:

- Hide or disable the flashlight / torch button on web.
- Replace “Open app settings” behavior with browser camera permission instructions.
- Make sure the scanner works only over HTTPS.
- Keep mobile behavior unchanged where possible.
- Consider self-hosting ZXing if needed for better offline behavior.

Relevant files:

```text
lib/screens/qr_scanner_screen.dart
lib/screens/qr_settings_screen.dart
```

Expected result:

QR scanning should continue to work on mobile and should work on supported web browsers with camera permission.

---

### 6. Configure the PWA Manifest

Update:

```text
web/manifest.json
```

Use these values:

```json
{
  "name": "Kuleta Digitale",
  "short_name": "Kuleta",
  "display": "standalone",
  "orientation": "portrait-primary"
}
```

Also configure:

- Correct theme color
- Correct background color
- 192x192 icon
- 512x512 icon
- Maskable icons
- 180x180 Apple touch icon

The current crest is not square, so create padded square icon files instead of cropping it badly.

Expected icon files should include something similar to:

```text
web/icons/Icon-192.png
web/icons/Icon-512.png
web/icons/Icon-maskable-192.png
web/icons/Icon-maskable-512.png
web/apple-touch-icon.png
```

---

### 7. Configure Firebase Hosting

The current `firebase.json` only handles database rules.

Add Firebase Hosting.

Hosting should serve:

```text
build/web
```

Add SPA rewrite support so all routes rewrite to:

```text
/index.html
```

Expected commands:

```bash
flutter build web --release
firebase init hosting
firebase deploy --only hosting
```

Example `firebase.json` structure:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

If the existing `firebase.json` already contains database rules, preserve them and add hosting without deleting the existing configuration.

---

### 8. Test PWA Behavior

Test these cases separately in Safari and from the installed iPhone Home Screen app:

- Login
- Token refresh
- Offline startup
- Queued database writes
- Image persistence after browser restart
- Camera permission
- QR scanning
- PWA install from Safari
- PWA launch from iPhone Home Screen
- Safe area around iPhone notch
- App update behavior with service-worker cache
- Installation before login
- Installation after login

Important iOS note:

Users may need to log in again after installing the PWA to the Home Screen because browser state and installed web app state may not always be shared reliably.

---

### 9. Keep Platform-specific Behavior Clean

Use platform checks where needed so Android/iOS behavior does not break.

Avoid large rewrites.

Prefer small, clear adapters for:

- HTTP
- Image storage/display
- QR scanner controls
- App settings instructions

Expected result:

The app should still work as a normal mobile Flutter app while also working as a PWA.

---

### 10. Final Validation

Run:

```bash
flutter analyze
flutter test
flutter build web --release
```

If possible, also test:

```bash
flutter build apk
```

Optional if iOS tooling is available:

```bash
flutter build ios --no-codesign
```

---

## Final Report Required

At the end, give me a clear summary with:

- Files changed
- What was added
- What was adapted for web
- What still needs manual iPhone testing
- Any Firebase Hosting setup steps I must complete manually
- Any risks or limitations
- Whether Android/iOS mobile behavior was preserved
- Whether the web release build passed
- Whether tests passed

---

## Expected Outcome

The project should become a working Progressive Web App that can be opened in Safari and installed on iPhone using:

```text
Safari → Share → Add to Home Screen → Open as Web App → Add
```

This should remove the need for:

- Xcode signing
- Apple Developer provisioning profiles
- Developer Mode
- TestFlight
- Manual IPA installation
