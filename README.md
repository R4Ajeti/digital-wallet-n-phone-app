# Kuleta Digitale

A Flutter demonstration app for Android, iOS, and the web, connected to Firebase
Authentication and Firebase Realtime Database.

> This app is not an official service and does not represent any municipality,
> public institution, or real ticketing system.

## Overview

- Email registration, Google sign-in, shared guest mode, sign-out, and
  provider-aware password changes.
- Locally persisted sessions with automatic Firebase ID token refresh.
- Private Realtime Database data for each user.
- One authenticated shared guest workspace with a device-local guest profile
  photo.
- Editable wallet balance and ticket expiration date.
- A QR code ID saved through manual entry or camera scanning.
- A Firebase-managed default QR code ID for new users.
- Offline support with local caching and queued write synchronization.
- Profile pictures and QR overlay images stored only on the device.
- Albanian app interface and messages.
- Android and iOS launcher icons.
- Installable Progressive Web App support for iPhone and iPad.

For web deployment and step-by-step iPhone installation, see
[`README_PWA.MD`](README_PWA.MD).

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
- `google_sign_in` for obtaining Google ID credentials
- Firebase Realtime Database REST API
- `mobile_scanner` for QR code scanning
- `permission_handler` for camera permission
- `shared_preferences` for sessions, caching, and offline writes
- `image_picker`, `path_provider`, and browser storage for local images

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

Enable **Email/Password**, **Google**, and **Anonymous** under
**Firebase Console > Authentication > Sign-in method**.

The session is stored on the device. When the Firebase ID token is close to
expiration, the app refreshes it through the Firebase Secure Token API.
Google credentials are exchanged through Firebase Authentication's REST API,
then stored in the same application session used by email/password and
anonymous users.

### Google Sign-In Configuration

The repository intentionally does not contain newly generated OAuth values.
Complete these console steps before testing Google sign-in:

**Android**

1. Confirm the Firebase Android app package matches
   `android/app/build.gradle.kts`.
2. Run `cd android && ./gradlew signingReport` and register the SHA-1 and
   SHA-256 fingerprints for every debug and distribution signing certificate.
3. Confirm Android and Web OAuth clients exist for the package and matching
   certificate.
4. Download a refreshed `google-services.json` to
   `android/app/google-services.json`.
5. Keep the Google Services Gradle plugin enabled. It is already applied in
   this project.

The currently checked local Android configuration has no OAuth client entries,
so Google sign-in will remain unavailable until it is refreshed.

**iOS**

1. Confirm the Firebase iOS app bundle ID matches the Runner target.
2. Download `GoogleService-Info.plist` to
   `ios/Runner/GoogleService-Info.plist` and add it to the Runner target.
3. Add the plist's reversed client ID as a URL scheme in
   `ios/Runner/Info.plist`.
4. Test on a simulator where supported and on a signed real device.

The required plist and URL scheme are not currently present in this repository.

**Web**

1. Create or verify the Web OAuth client and configure its authorized
   JavaScript origins.
2. Add local and production domains to Firebase Authentication's authorized
   domains.
3. Supply the Web OAuth client at build or run time with
   `--dart-define=GOOGLE_WEB_CLIENT_ID=...`.
4. Verify popup/FedCM behavior in a real browser on `localhost` and the
   production HTTPS domain.

The app uses the Google Identity Services button rendered by the current
`google_sign_in` web implementation.

### Shared Guest Workspace

Each guest installation receives its own Firebase anonymous identity and token,
but all guest application data is routed to:

```text
/sharedGuest/default
```

The first shared record is created with an atomic conditional write. Existing
guest data is never replaced during sign-in. Guest updates use field-level
patches with last-write-wins behavior, and active guest screens periodically
refresh the shared record.

Balance, ticket settings, QR value, scanner result, overlay position, and the
bundled QR overlay selection are shared. The guest profile photo and its local
lookup reference use the stable `shared_guest_profile` namespace and never
leave the installation. Logging out and entering guest mode again retains that
photo on the same installation even if Firebase assigns another anonymous UID.

Clearing browser/site storage, clearing app data, uninstalling the native app,
or using another device may remove or hide the local guest photo. Do not put
private or sensitive information in the shared guest workspace.

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

sharedGuest/default/
  username
  userTypeLabel
  wallet/
    balance
  ticket/
    expiresAt
    expiresAtText
  qr/
    value
    updatedAt
  qrOverlay/
    type
    positionX
    positionY
    updatedAt
  settings/
    language
    demoMode
  createdAt
  updatedAt
```

Image paths are local and do not synchronize image files between devices.
Guest profile references are excluded from Firebase entirely. The QR scanner
stores only the decoded text, not camera frames or images.

### Database Rules

`database.rules.json` allows public read access only to `appConfig`, prevents
client writes to that configuration, restricts each user profile to its
authenticated owner, and permits the validated shared guest record only for
anonymous-provider sessions.

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
