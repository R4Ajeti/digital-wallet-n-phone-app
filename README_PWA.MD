# Kuleta Digitale PWA

Kuleta Digitale can now run as an installable Progressive Web App (PWA). On an
iPhone, it can be installed from Safari without Xcode, signing certificates,
Developer Mode, TestFlight, or an IPA file.

The app remains a Flutter Android/iOS application. The PWA is an additional
deployment target, not a replacement for the mobile builds.

## What Was Added

- Flutter web project files under `web/`.
- An installable PWA manifest and padded square application icons.
- A 180x180 Apple touch icon.
- A custom service worker for app-shell and runtime caching.
- Firebase Hosting configuration with HTTPS and SPA route fallback.
- Cross-platform Firebase REST networking through `package:http`.
- Browser-compatible local profile and QR overlay image storage.
- Web QR scanning with a locally hosted ZXing library.
- Web-specific camera permission guidance and no web flashlight button.

## Important Limitations

- Profile images are local to one browser/PWA installation. Registered users'
  QR overlay images are also local. Guest mode always uses the common bundled
  QR overlay so guest QR presentation cannot diverge by browser.
- Removing the PWA, clearing Safari website data, or clearing browser storage
  can remove local images and locally cached data.
- Each selected local image is limited to about 1.5 MB after resizing.
- Login, token refresh, uncached data, and synchronization still require an
  internet connection.
- A first guest sign-in after installation or explicit logout requires an
  internet connection. A guest session that was already opened online can
  reopen its cached shared data offline if the user did not log out.
- The app can open offline after it has been loaded successfully at least once.
  Existing app caching and queued database writes continue to handle app data.
- Camera scanning requires HTTPS in production. `localhost` is allowed for
  development.
- This project is a demonstration and is not an official municipal or
  ticketing service.

## Run Locally

Install dependencies:

```bash
flutter pub get
```

Run the web app in Chrome:

```bash
flutter run -d chrome --dart-define=GOOGLE_WEB_CLIENT_ID=...
```

For testing from another device on the same network, a plain local IP address
is not enough for camera access because iOS requires a secure HTTPS context.
Use the deployed Firebase Hosting URL for real iPhone camera and installation
testing.

## Build the PWA

Create the release bundle:

```bash
flutter build web --release --dart-define=GOOGLE_WEB_CLIENT_ID=...
```

The deployable files are written to:

```text
build/web
```

The release build copies `web/sw.js`, the custom Flutter bootstrap, manifest,
icons, and the locally hosted ZXing scanner runtime into that directory.

## Deploy to Firebase Hosting

The repository already targets Firebase project:

```text
kuleta-digitale-n-db
```

Install the Firebase CLI if it is not installed:

```bash
npm install -g firebase-tools
```

Log in and select the project:

```bash
firebase login
firebase use kuleta-digitale-n-db
```

Build and deploy only Hosting:

```bash
flutter pub get
flutter build web --release --dart-define=GOOGLE_WEB_CLIENT_ID=...
firebase deploy --only hosting
```

Firebase prints the exact HTTPS Hosting URL after deployment. The default site
will normally be available at:

```text
https://kuleta-digitale-n-db.web.app
```

Do not run `firebase init hosting` again unless you intend to reconfigure the
project. The required Hosting configuration is already present in
`firebase.json`, alongside the existing Realtime Database rules.

To deploy both Hosting and database rules intentionally:

```bash
firebase deploy --only hosting,database
```

## Install on iPhone

Use Safari for these steps:

1. Deploy the latest release and copy the HTTPS URL printed by Firebase.
2. Open the URL in Safari on the iPhone.
3. Wait for the app to load completely at least once.
4. Tap Safari's **Share** button. Depending on the Safari layout, first tap the
   **More** button and then **Share**.
5. Scroll down and tap **Add to Home Screen**.
6. If that action is missing, scroll to the bottom, tap **Edit Actions**, and
   add **Add to Home Screen**.
7. Turn on **Open as Web App**.
8. Keep or edit the name, then tap **Add**.
9. Return to the Home Screen and open **Kuleta** from its new icon.
10. Log in or enter guest mode inside the installed PWA. Safari and the
    installed web app might not always share an existing login session or
    local guest profile photo.

The installed PWA opens in a standalone window and can be launched like a
normal app.

## Allow Camera Access on iPhone

1. Open the installed **Kuleta** PWA.
2. Open QR settings and tap **Skano QR Code**.
3. Tap **Allow** when iOS asks for camera access.
4. Point the camera at a QR code and keep it inside the scan frame.

If camera access was denied:

1. Open the same HTTPS URL in Safari.
2. Open the page controls or website settings for that site.
3. Set **Camera** to **Allow** or **Ask**.
4. Close and reopen the installed PWA, then try the scanner again.

If the camera still does not open, confirm that the URL begins with `https://`
and that Screen Time or device-management restrictions are not blocking it.

## Access the PWA Later

- Tap **Kuleta** on the iPhone Home Screen.
- The phone does not need to remain connected to a Mac.
- Xcode, provisioning profiles, and an Apple Developer account are not needed.
- Any supported iPhone can open the same Firebase Hosting URL and install its
  own copy.

## Publish an Update

After changing the app:

```bash
flutter build web --release
firebase deploy --only hosting
```

Then close and reopen the PWA. The service worker checks the network first and
caches the new app files as they are received. If an old version remains:

1. Make sure the new Firebase deployment completed.
2. Open the Hosting URL once in Safari.
3. Close the PWA from the app switcher and reopen it.
4. As a last resort, remove the Home Screen app, clear that site's Safari
   website data, and install it again.

When changing `web/sw.js` caching behavior or its pre-cached file list, also
increment `CACHE_NAME` so old caches are removed.

## iPhone Test Checklist

Test these on a real iPhone after deployment:

- Install before login and log in from the Home Screen app.
- Install after login and confirm whether another login is requested.
- Relaunch from the Home Screen.
- Check layout around the notch and Home indicator.
- Allow, deny, and re-enable camera permission.
- Scan and save a QR code.
- Select profile and QR overlay images, then restart the PWA.
- Enter guest mode from two browser profiles and verify shared wallet/QR data
  with different local profile photos.
- Log out of guest mode, enter it again online, and verify the local profile
  photo remains.
- Start online once, enable airplane mode, and test offline startup.
- Queue a database change offline, reconnect, and verify synchronization.
- Leave the app long enough to exercise Firebase token refresh.
- Deploy an update and verify that the new version appears.

## Verification Commands

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug
```

## Reference Documentation

- Apple: https://support.apple.com/guide/iphone/open-as-web-app-iphea86e5236/ios
- Flutter web deployment: https://docs.flutter.dev/deployment/web
- Flutter web service workers:
  https://docs.flutter.dev/platform-integration/web/faq
- Firebase Hosting: https://firebase.google.com/docs/hosting
- Firebase Hosting configuration:
  https://firebase.google.com/docs/hosting/full-config
