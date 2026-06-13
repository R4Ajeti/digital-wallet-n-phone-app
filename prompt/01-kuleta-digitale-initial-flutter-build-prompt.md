# Kuleta Digitale — Full Flutter + Firebase Build Prompt

You are already inside the existing project folder:

```text
kuleta-digitale-n-app
```

Do not create another parent folder. Work inside the current directory.

Build a complete Flutter mobile app for Android first, with a clean structure so iOS can be added later.

---

## Project Identity

Project name:

```text
kuleta-digitale-n-app
```

Installed app name:

```text
Kuleta Digitale
```

Firebase project ID:

```text
kuleta-digitale-n-db
```

Android package name:

```text
com.gentool.kuletadigitalen
```

iOS bundle ID for later:

```text
com.gentool.kuletadigitalen
```

## Main Technology

Use:

- Flutter
- Firebase client SDK through FlutterFire
- Firebase Authentication
- Firebase Realtime Database
- QR code generation
- QR scanning locally on device
- Local image picker/storage for profile image and QR overlay icon

Do not use:

- Firebase Admin SDK
- Service account private keys
- Firebase Storage
- Cloud Storage bucket
- Server-side credentials
- `Generate new private key`
- Admin credentials inside the mobile app

---

## Firebase Setup

Use Firebase CLI and FlutterFire CLI.

First, check whether the current folder has Firebase CLI config files.

If `.firebaserc`, `firebase.json`, or `database.rules.json` do not exist, create them.

Create `.firebaserc`:

```json
{
  "projects": {
    "default": "kuleta-digitale-n-db"
  }
}
```

Create `firebase.json`:

```json
{
  "database": {
    "rules": "database.rules.json"
  }
}
```

Create `database.rules.json`:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid"
      }
    }
  }
}
```

Then run or verify these commands:

```bash
firebase login
firebase use
flutterfire configure --project=kuleta-digitale-n-db --platforms=android
```

If FlutterFire CLI is missing, install it:

```bash
dart pub global activate flutterfire_cli
```

If Firebase CLI is missing, install it:

```bash
npm install -g firebase-tools
```

The app should use the generated FlutterFire config file:

```text
lib/firebase_options.dart
```

---

## Required Flutter Packages

Install these packages:

```bash
flutter pub add firebase_core firebase_auth firebase_database
flutter pub add qr_flutter mobile_scanner image_picker permission_handler shared_preferences path_provider
```

Add other packages only if truly needed.

---

## Environment Variables

Create a `.env.example` file with:

```env
FIREBASE_PROJECT_ID=kuleta-digitale-n-db
ANDROID_PACKAGE_NAME=com.gentool.kuletadigitalen
IOS_BUNDLE_ID=com.gentool.kuletadigitalen
```

Do not require Firebase Admin environment variables.

Do not use these:

```env
FIREBASE_ADMIN_PRIVATE_KEY=
FIREBASE_CLIENT_EMAIL=
GOOGLE_APPLICATION_CREDENTIALS=
SERVICE_ACCOUNT_KEY_BASE64=
```

---

## Firebase Authentication

Use Firebase Authentication with email/password.

Implement:

- Register
- Login
- Logout
- Change password
- Persistent user session using Firebase Auth session

After logout, return the user to the login screen.

---

## Firebase Realtime Database

Use Firebase Realtime Database as the main database.

Use this structure:

```text
/users/{uid}
  email: string
  username: string
  userTypeLabel: string
  profile:
    localImagePath: string
  ticket:
    expiresAt: string
    expiresAtText: string
  qr:
    manualValue: string
    scannedValue: string
    activeSource: "manual" | "scanned"
    activeValue: string
    updatedAt: string
  qrOverlay:
    localImagePath: string
    positionX: number
    positionY: number
    updatedAt: string
  settings:
    language: "sq"
    demoMode: true
  createdAt: string
  updatedAt: string
```

Security rule requirement:

- Authenticated users can read and write only their own data under `/users/{uid}`.
- A user must not access another user’s data.

---

## Image Handling

Do not upload images to Firebase.

Profile image:

- Pick/select image from the phone gallery.
- Save/store the image locally on the device.
- Save only the local image path in Firebase Realtime Database.

QR overlay icon image:

- Pick/select image from the phone gallery.
- Save/store the image locally on the device.
- Save only the local image path in Firebase Realtime Database.

It is acceptable that local images do not sync to another device.

This is a demo app.

---

## QR Code Feature

Show a large QR code on the main/home screen.

The QR code must be generated from the active QR value stored in Firebase Realtime Database.

The user can set the QR value in two ways.

### Option A — Manual QR Value

The user can type or paste QR code text manually.

Save it as:

```text
/users/{uid}/qr/manualValue
```

### Option B — Scanned QR Value

The user can open the camera scanner.

The app should:

- Scan the QR code locally on the device.
- Decode/extract the QR text/value.
- Do not upload the image.
- Do not save the captured image.
- Save only the decoded QR text/value in Firebase Realtime Database.

Save it as:

```text
/users/{uid}/qr/scannedValue
```

The user must be able to choose the active QR source:

- Manual value
- Scanned value

Save:

```text
/users/{uid}/qr/activeSource
/users/{uid}/qr/activeValue
/users/{uid}/qr/updatedAt
```

---

## QR Settings Screen

Screen title:

```text
Cilësimet e QR Kodit
```

Features:

- Input field for manual QR value.
- Button to save manual value.
- Button to open QR scanner.
- Show scanned QR value after scanning.
- Choose active QR source:
  - `Përdor kodin manual`
  - `Përdor kodin e skanuar`
- Save active QR source and value to Firebase.
- Clear manual QR value.
- Clear scanned QR value.
- Return back.

Button labels:

```text
Ruaj
Fshij
Skano QR Kod
Kthehu
Anulo
Ruaj kodin
```

---

## QR Scanner Screen

The QR scanner screen should:

- Ask for camera permission.
- Open live camera preview.
- Detect QR code locally.
- Decode QR text/value.
- Show decoded value to the user.
- Have button: `Ruaj kodin`
- Have button: `Anulo`
- After saving, write the scanned value to Firebase Realtime Database.
- Return to QR settings screen after saving.
- Never upload or store the captured QR image.

---

## Main/Home Screen

Main screen must include:

- App title: `Kuleta Digitale`
- Large QR code area
- Visible `DEMO` label
- Small footer text:

```text
Ky aplikacion është vetëm prototip demonstrues.
```

- Profile card with selected local profile image
- User type label:

```text
Student/e në Universitet me bazë në Prishtinë
```

- Ticket validity text:

```text
Bileta juaj është e vlefshme deri më
```

- Expiration date below the validity text
- Menu button to open settings

---

## Ticket Expiration

Expiration date must always be calculated as **1 month from the current date**.

Show date in Albanian month format.

Example:

```text
23 Korrik 2026
```

Save:

```text
/users/{uid}/ticket/expiresAt
/users/{uid}/ticket/expiresAtText
```

Update it when the user opens the app if needed.

---

## Movable QR Overlay Icon

Add a small icon/image overlay on top of the QR code.

The user can drag and move the icon anywhere over the QR code.

Save the icon position in Firebase Realtime Database:

```text
/users/{uid}/qrOverlay/positionX
/users/{uid}/qrOverlay/positionY
```

When the app opens again:

- Load saved icon position from Firebase.
- Place the icon in the last saved position.

Icon image rule:

- The icon image itself is local only.
- Save only local path in Firebase.
- Use a default demo icon if the user has not selected one.
- Do not use any official logo.

---

## Settings/Menu Screen

Only include these menu items:

```text
Cilësimet e QR Kodit
Ndrysho fotografinë
Ndrysho ikonën e QR Kodit
Ndrysho fjalëkalimin
Dil nga aplikacioni
```

Remove all other menu items.

---

## Change Password Screen

Screen title:

```text
Ndrysho fjalëkalimin
```

Fields:

```text
Fjalëkalimi aktual
Fjalëkalimi i ri
Konfirmo fjalëkalimin e ri
```

Buttons:

```text
Ruaj
Kthehu
```

Validation:

- Current password is required.
- New password cannot be empty.
- New password and confirmation must match.
- Use Firebase Authentication to update the password.
- If re-authentication is required, handle it properly.
- Show success and error messages in Albanian.

---

## Login Screen

Screen title:

```text
Kuleta Digitale
```

Fields:

```text
Email
Fjalëkalimi
```

Buttons:

```text
Kyçu
Krijo llogari
```

---

## Register Screen

Fields:

```text
Email
Përdoruesi
Fjalëkalimi
Konfirmo fjalëkalimin
```

Buttons:

```text
Krijo llogari
Kthehu
```

When a new user registers:

- Create Firebase Auth user.
- Create default user data under `/users/{uid}` in Realtime Database.
- Set default `userTypeLabel`:

```text
Student/e në Universitet me bazë në Prishtinë
```

- Set default demo mode to `true`.
- Set default ticket expiration date to 1 month from today.

---

## Profile Image Screen

Screen title:

```text
Ndrysho fotografinë
```

Features:

- Pick image from gallery.
- Save image locally.
- Save local path to Firebase Realtime Database under:

```text
/users/{uid}/profile/localImagePath
```

- Show selected image preview.

Buttons:

```text
Ruaj
Kthehu
```

---

## QR Overlay Icon Image Screen

Screen title:

```text
Ndrysho ikonën e QR Kodit
```

Features:

- Pick image from gallery.
- Save image locally.
- Save local path to Firebase Realtime Database under:

```text
/users/{uid}/qrOverlay/localImagePath
```

- Show selected icon preview.

Buttons:

```text
Ruaj
Kthehu
```

---

## App Language

The entire app must be in Albanian.

Use correct Albanian text with:

- ë
- ç

All errors, success messages, labels, buttons, menus, and titles must be Albanian.

---

## UI Design

Use:

- Clean modern mobile design
- Card-based layout
- Rounded corners
- Good spacing
- Mobile-first layout
- Original colors
- Original branding
- Simple original color palette

Do not copy any real official app exactly.

---

## Required Screens

Implement:

- Login screen
- Register screen
- Main/Home screen
- QR presentation section on home screen
- Settings/Menu screen
- QR settings screen
- QR camera scanner screen
- Change password screen
- Profile image change screen
- QR overlay icon change screen

---

## Code Architecture

Use a clean structure like:

```text
lib/
  main.dart
  firebase_options.dart
  app.dart
  models/
  services/
    auth_service.dart
    database_service.dart
    local_image_service.dart
  screens/
    login_screen.dart
    register_screen.dart
    home_screen.dart
    settings_screen.dart
    qr_settings_screen.dart
    qr_scanner_screen.dart
    change_password_screen.dart
    profile_image_screen.dart
    qr_overlay_icon_screen.dart
  widgets/
    qr_ticket_widget.dart
    profile_card.dart
    app_button.dart
    app_text_field.dart
  utils/
    albanian_date.dart
    validators.dart
```

---

## Required Implementation Details

- Initialize Firebase in `main.dart` using `DefaultFirebaseOptions.currentPlatform`.
- Use Firebase Auth auth state to decide whether to show login or home.
- Use Firebase Realtime Database references under `/users/{uid}`.
- Add loading states.
- Add error handling.
- Add empty-state if no QR value exists.
- Use placeholder QR text only if needed, but show it as demo.
- Never crash if Firebase data is missing.
- Create default user data if it does not exist.

---

## Permissions

### Android

Add camera permission.

Add gallery/photo permission if needed.

Configure package name correctly:

```text
com.gentool.kuletadigitalen
```

### iOS Later

Add camera usage description.

Add photo library usage description.

Configure bundle ID correctly:

```text
com.gentool.kuletadigitalen
```

Do not fully configure iOS now unless necessary, but keep the project ready.

---

## Commands to Run

After implementation, provide commands:

```bash
flutter clean
flutter pub get
flutterfire configure --project=kuleta-digitale-n-db --platforms=android
flutter run
```

Deploy database rules:

```bash
firebase deploy --only database --project kuleta-digitale-n-db
```

---

## Final Output Required

Build the app fully.

Show all files created/changed.

Explain:

- How to run it
- How Firebase Auth is used
- How Realtime Database is used
- How QR scanning works locally
- How profile image is stored locally
- How QR overlay icon image is stored locally
- How to deploy database rules
- Which Firebase project is used
- Which Android package name is used
- Which iOS bundle ID should be used later

Do not ask for Firebase Admin keys.

Do not use Firebase Storage.

Do not create another Firebase project.

Use the existing Firebase project:

```text
kuleta-digitale-n-db
```

Use these identifiers:

```env
ANDROID_PACKAGE_NAME=com.gentool.kuletadigitalen
IOS_BUNDLE_ID=com.gentool.kuletadigitalen
```
