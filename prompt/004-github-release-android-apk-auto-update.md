# 004 - GitHub Release Android APK Auto-Update

Create a new prompt file inside the `prompt/` folder with this exact name:

`prompt/004-github-release-android-apk-auto-update.md`

## Goal

Add a safe release and update flow for the app using GitHub Releases.

The main priority is Android APK release distribution and update checking. For iOS, only implement an update flow if it is realistically supported by the current app type and Apple rules. If iOS auto-update is not possible, document the limitation clearly and keep the implementation Android-only.

## Requirements

### 1. Do not break current infrastructure

- Keep the existing app structure working.
- Do not remove or rewrite existing build, auth, Firebase, routing, or deployment logic unless required.
- Make changes incrementally and document every important change.
- Keep all existing Android, iOS, and Web flows working.

### 2. GitHub Release for Android

Add support for publishing the Android app as a GitHub Release asset.

The generated APK should use a clear versioned name, for example:

`kuleta-digitale-n-app-v1.0.0-android.apk`

Use a naming format like:

`<app-name>-v<version>-android.apk`

The GitHub Release should include:

- Release tag, for example `v1.0.0`
- Release title, for example `Kuleta Digitale v1.0.0`
- APK file as a release asset
- Short changelog
- Build date
- Version name and version code
- Installation notes for Android users

### 3. GitHub Actions build and release workflow

Create or update a GitHub Actions workflow that can:

- Build the Android APK
- Sign the APK if signing is already configured
- Store signing credentials safely using GitHub Actions Secrets
- Create a GitHub Release
- Upload the APK as a release asset
- Never expose secrets in logs or committed files

Do not commit:

- `.env` files
- keystore files
- passwords
- API keys
- tokens
- Firebase private credentials
- QR codes
- sponsor codes
- redemption links

### 4. Android auto-update behavior

Add an Android update-checking mechanism that checks the latest GitHub Release.

The app should:

- Check the latest GitHub Release version
- Compare it with the installed app version
- Show a user-friendly update message if a newer APK exists
- Open the GitHub Release APK download link or release page
- Never force silent installation, because Android normally requires user confirmation for APK installation
- Handle network errors safely
- Handle missing release assets safely
- Avoid blocking the app if the update check fails

Example user message:

`A new version of Kuleta Digitale is available. Please update to continue using the latest features.`

### 5. iOS behavior

Check whether iOS auto-update is possible for the current project.

If this is a native iOS app:

- Do not attempt APK-style auto-update.
- Explain clearly that iOS apps must normally update through the App Store or TestFlight.
- Do not generate unsupported or unsafe IPA auto-install logic.

If this is a PWA:

- Use the service worker update flow if available.
- Add a safe “new version available” refresh prompt for Web/iOS PWA users if supported.

If iOS auto-update is not supported, leave the implementation Android-only and document why.

### 6. Versioning

Add or verify version tracking.

Use a clear version source, such as:

- Android `versionName`
- Android `versionCode`
- App config version
- GitHub Release tag

The app should compare versions safely using semantic versioning where possible.

### 7. Documentation

Update or create documentation explaining:

- How to create a new Android release
- How the APK name is generated
- How Android users install the APK
- How the in-app update check works
- Why iOS auto-update may not be supported
- What GitHub Secrets are required
- How to test the release workflow

### 8. Testing

Add or document manual tests for:

- Existing app still starts normally
- Android APK builds successfully
- GitHub Release is created successfully
- APK is uploaded with the correct name
- App detects a newer version
- App does not crash when GitHub API is unavailable
- App handles missing APK release asset
- iOS behavior is documented or safely handled

## Expected Result

- A new prompt file exists at:

`prompt/004-github-release-android-apk-auto-update.md`

- Android APK release automation is planned or implemented safely.
- GitHub Releases contain a versioned APK with a clean name.
- Android users can be notified when a new APK release exists.
- iOS is handled honestly:
  - App Store/TestFlight for native iOS, or
  - service worker update prompt for PWA, if supported.
- No secrets or credentials are committed.
