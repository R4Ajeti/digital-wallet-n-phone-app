# Kuleta Digitale

A Flutter demonstration app for Android and iOS, connected to Firebase
Authentication and Firebase Realtime Database.

> This app is not an official service and does not represent any municipality,
> public institution, or real ticketing system.

## Overview

- Email registration, sign-in, sign-out, and password changes.
- Locally persisted sessions with automatic Firebase ID token refresh.
- Private Realtime Database data for each user.
- Editable wallet balance and ticket expiration date.
- A QR code ID saved through manual entry or camera scanning.
- A Firebase-managed default QR code ID for new users.
- Offline support with local caching and queued write synchronization.
- Profile pictures and QR overlay images stored only on the device.
- Albanian app interface and messages.
- Android and iOS launcher icons.

## Application Identifiers

| Setting | Value |
| --- | --- |
| Application name | `Kuleta Digitale` |
| Firebase project ID | `kuleta-digitale-n-db` |
| Android application ID | `com.gentool.kuletadigitalen` |
| iOS bundle ID | `com.gentool.kuletadigitalen` |
| Version | `1.0.0+1` |

## Technology

- Flutter `3.44.2`
- Dart `3.12.2`
- Firebase Authentication REST API
- Firebase Realtime Database REST API
- `mobile_scanner` for QR code scanning
- `permission_handler` for camera permission
- `shared_preferences` for sessions, caching, and offline writes
- `image_picker` and `path_provider` for local images

The app does not depend on FlutterFire at runtime. Firebase Authentication and
Realtime Database are accessed directly through their REST APIs. The app does
not use the Firebase Admin SDK, service accounts, Firebase Storage, or private
keys.

## Requirements

- Flutter SDK on the stable channel
- Android Studio and the Android SDK for Android development
- Xcode and an Apple Development Team for iOS development
- Firebase CLI when changing or deploying database rules
- A device with Developer Mode enabled for direct development installation

Check the development environment:

```bash
flutter doctor
flutter devices
flutter pub get
```

## Running on Android

Connect the device, enable USB debugging, and verify that it is detected:

```bash
adb devices
flutter devices
```

Run the app on the selected device:

```bash
flutter run -d <android-device-id>
```

Example using the currently configured Android device:

```bash
flutter run -d 21121FDF6001KZ
```

Build a debug APK:

```bash
flutter build apk --debug
```

The APK is created at `build/app/outputs/flutter-apk/app-debug.apk`.

> The current Android configuration uses debug signing for release builds.
> Configure a private release keystore before publishing to Google Play.

## Running on iPhone

The iOS project uses the bundle ID `com.gentool.kuletadigitalen`. On another
Mac or Apple account, open `ios/Runner.xcworkspace` in Xcode and select the
Development Team under **Runner > Signing & Capabilities**.

Run a development build with the Flutter debugger:

```bash
flutter run -d <ios-device-id>
```

A debug build may depend on its Flutter debugger connection. To install a
build that can be opened from the Home Screen without a USB connection, use
release mode:

```bash
flutter run --release --no-resident -d <ios-device-id>
```

Example using the configured iPhone:

```bash
flutter run --release --no-resident -d 00008140-000C75443A62801C
```

After installation, stop the command if it is still running, disconnect the
USB cable, and open the app normally from the Home Screen. The app remains
launchable while its provisioning profile and developer certificate are valid.

If iOS prevents the app from opening:

1. Enable **Settings > Privacy & Security > Developer Mode**.
2. Trust the developer account under **VPN & Device Management** if prompted.
3. Check the signing team and provisioning profile in Xcode.
4. Reinstall the release build after making signing changes.

## Firebase

### Authentication

Enable the **Email/Password** provider under
**Firebase Console > Authentication > Sign-in method**.

The session is stored on the device. When the Firebase ID token is close to
expiration, the app refreshes it through the Firebase Secure Token API.

### Default QR Code ID

During registration, the app reads:

```text
/appConfig/defaultQrCodeId
```

The currently configured value is:

```text
AD307A67-E263-4800-87C0-C14D0B1B83AF
```

When this value exists in Firebase, it is saved to the new user's profile. If
it is missing or cannot be read, the registration form requires the user to
enter a QR code ID.

After profile creation, the QR code ID changes only when the user:

- enters a new value on the QR settings screen; or
- scans a new QR code with the camera.

The value is cached locally and stored at:

```text
/users/{uid}/qr/value
```

### Database Structure

```text
appConfig/
  defaultQrCodeId

users/{uid}/
  email
  username
  userTypeLabel
  wallet/
    balance
  profile/
    localImagePath
  ticket/
    expiresAt
    expiresAtText
  qr/
    value
    updatedAt
  qrOverlay/
    localImagePath
    positionX
    positionY
    updatedAt
  settings/
    language
    demoMode
  createdAt
  updatedAt
```

Image paths are local and do not synchronize image files between devices. The
QR scanner stores only the decoded text, not camera frames or images.

### Database Rules

`database.rules.json` allows public read access only to `appConfig`, prevents
client writes to that configuration, and restricts each user profile to its
authenticated owner.

Deploy the rules:

```bash
firebase login
firebase use kuleta-digitale-n-db
firebase deploy --only database
```

Manage `appConfig/defaultQrCodeId` through Firebase Console or another
administrative environment, not through the client app.

## Permissions

Android declares internet, network state, camera, and image selection
permissions in `android/app/src/main/AndroidManifest.xml`.

iOS declares `NSCameraUsageDescription` in `ios/Runner/Info.plist`. When the
user taps the scan button, the app:

1. Requests camera permission.
2. Opens the scanner when permission is granted.
3. Shows a clear message when permission is denied.
4. Directs the user to Settings when permission is permanently denied or
   restricted.

## Application Icon

The source image is:

```text
experimental-resource/icon/stema-komunes-prishtines.png
```

Regenerate icons for both platforms:

```bash
dart run flutter_launcher_icons
```

## Verification

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --release
```

The tests cover validation, date formatting, incomplete Firebase data, legacy
QR schema migration, manual QR value persistence, empty states, QR generation,
and the home screen golden image.

## Project Structure

```text
android/                 Android configuration
ios/                     Active iOS project
lib/
  models/                Session and user models
  screens/               Application screens
  services/              Firebase REST, caching, and local images
  theme/                 Colors and styles
  utils/                 Validation, dates, and messages
  widgets/               Reusable UI components
test/                    Widget, unit, and golden tests
database.rules.json      Realtime Database rules
commands.txt             Useful local device commands
```
