# Android GitHub Releases

Android APK releases are published from `pubspec.yaml` through
`.github/workflows/android-release.yml`. Native iOS releases are not distributed
this way: Apple requires normal App Store or TestFlight distribution. The web
and iOS PWA use the service worker refresh prompt in `web/index.html`.

## Versioning

The `pubspec.yaml` value is the source of truth:

```yaml
version: 1.0.1+2
```

- `1.0.1` becomes Android `versionName` and Git tag `v1.0.1`.
- `2` becomes Android `versionCode`.
- The release asset becomes
  `kuleta-digitale-n-app-v1.0.1-android.apk`.

Increase both values for every Android release. Tags that do not match the
version name are rejected by the workflow.

## Required GitHub Actions Secrets

Configure these repository secrets under **Settings > Secrets and variables >
Actions**:

- `ANDROID_KEYSTORE_BASE64`: base64-encoded release keystore.
- `ANDROID_KEYSTORE_PASSWORD`: keystore password.
- `ANDROID_KEY_ALIAS`: key alias.
- `ANDROID_KEY_PASSWORD`: key password.

The keystore and passwords must never be committed. Published updates must keep
using the same signing key or Android will reject an APK installed over an
older version.

The initial release key on the setup Mac is stored outside the repository at
`~/.config/kuleta-digitale/android-signing/kuleta-release.jks`. Its passwords
are stored in the macOS Keychain. Keep an additional encrypted backup because
GitHub Actions secrets cannot be downloaded again.

## Create A Release

1. Update `version:` in `pubspec.yaml`.
2. Add and test the release changes.
3. Commit and push the commit to `main`.
4. Create and push the matching tag, for example:

   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

The workflow analyzes and tests the app, builds a signed APK, creates the
GitHub Release, and uploads the versioned APK. It can also be run manually from
the **Actions** tab with the matching tag and a short changelog.

## In-App Update Check

On Android, the app checks GitHub's latest release API after startup. A newer
semantic version opens a prompt; accepting it opens the APK asset in the
browser. If the APK asset is missing, the release page opens instead. Network,
API, malformed response, and missing-asset failures do not block app startup.

Users can repeat the check from **Menyja > Kontrollo për përditësime**.
Android requires the user to allow the download source and confirm installation.
The app never attempts silent installation.

## PWA And Native iOS

The PWA service worker downloads a new app shell in the background and shows
`Një version i ri është gati.`. Tapping **Rifresko** activates it and reloads
the app. This works for supported browsers and installed iOS PWAs.

Native iOS cannot safely install an IPA from a GitHub Release. Publish native
iOS builds through TestFlight or the App Store and use Apple's update flow.

## Test Checklist

- Run `flutter analyze` and `flutter test`.
- Run `flutter build apk --release` locally for a development-signed check.
- Confirm the GitHub workflow succeeds with all four signing secrets.
- Confirm the release title, build date, version name, version code, and APK
  filename are correct.
- Install the APK on Android and verify normal startup.
- Publish a higher test version and verify the update prompt opens its APK.
- Verify API failure does not show a startup error or block login.
- Verify a release without an APK falls back to the release page.
- Deploy the PWA twice and verify the refresh banner appears.
