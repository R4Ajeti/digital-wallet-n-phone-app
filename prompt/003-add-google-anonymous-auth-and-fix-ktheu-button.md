# 003 - Add Google and Anonymous Authentication and Fix the Kthehu Button

## Branch Name

```bash
003-add-google-anonymous-auth-and-fix-ktheu-button
```

## Task Title

**003 - Add Google and Anonymous Authentication and Fix the Kthehu Button**

---

## Prompt

Implement task `003-add-google-anonymous-auth-and-fix-ktheu-button` in the
existing Flutter project.

## Goal

Extend the current Firebase Authentication flow so users can sign in with:

- Email and password
- Google
- A shared guest mode backed by Firebase Anonymous Authentication

Guest mode has special data behavior:

- There is one shared guest workspace for the whole application.
- Every guest on Android, iOS, and Web reads and writes the same shared guest
  wallet data.
- The shared guest workspace is created once and reused. Starting guest mode
  must not create a new guest data record on every device or login.
- The imported profile photo is the only guest data that is not shared. Its
  bytes and reference remain local to each app/browser installation.
- The QR value, generated QR code, QR overlay/icon, overlay position, and all QR
  settings are shared and must appear the same for every guest.

The result must work on Android, iOS, and Web without breaking existing users,
stored sessions, Realtime Database access, offline behavior, or the current
email/password flow.

Also fix the issue where the `Kthehu` back button, referred to as `Ktheu` in
the task description, can be difficult or unreliable to press on Web and iOS.

## Existing Architecture to Preserve

Inspect the repository before editing and work with the current architecture.
At the time this prompt was written:

- `lib/services/auth_service.dart` implements Firebase Authentication through
  the Firebase Identity Toolkit REST API.
- Auth sessions and refresh tokens are persisted with `shared_preferences`.
- `DatabaseService` calls `AuthService.requireValidIdToken()` for authenticated
  Firebase Realtime Database requests.
- `AuthGate` listens to `AuthService.authStateChanges()`.
- Email/password login, registration, logout, password changes, token refresh,
  and existing stored sessions already depend on this contract.
- `AppSessionUser` currently assumes a string email and display name.

Do not replace this with a separate, competing authentication state. Prefer a
small extension of `AuthService` and its existing session model. If a Firebase
or Google SDK is needed to obtain the Google credential, exchange or bridge the
result into the existing session/token flow so Realtime Database requests keep
working through the same authenticated path.

Do not perform a broad authentication rewrite unless the existing design makes
the required cross-platform behavior impossible. If a larger migration is
truly necessary, document the reason and prove that existing email/password
users and sessions continue to work.

## Important Security Rules

Do not commit, print, paste into documentation, or expose:

- Secrets
- API keys
- OAuth client secrets
- Access tokens
- ID tokens
- Refresh tokens
- `.env` files
- Service-account files
- Private keys
- Credentials
- QR codes
- User data

Do not run `git add`, `git commit`, or push changes.

Use existing client configuration where appropriate, but do not duplicate its
values in source files, tests, logs, screenshots, or the final report. If new
Firebase or OAuth configuration must be downloaded or created manually, give
the user exact file locations and console steps without including the values.

Never use a service account, Firebase Admin SDK, or server-side credential in
the client application.

Do not implement the shared guest as one hardcoded email/password account, one
reusable refresh token, or one Firebase credential copied to every device.
Shared credentials in a public client can be extracted and abused.

Use separate Firebase anonymous authentication sessions for secure transport,
but map every anonymous session to one stable shared application data path.
In this prompt, "one shared guest account" means one shared guest workspace and
data record, not one secret Firebase credential distributed to all clients.

---

## Tasks

### 1. Establish a Baseline

Before making changes:

- Inspect `AuthService`, `DatabaseService`, `AuthGate`, `AppSessionUser`, the
  login and registration screens, settings, shared buttons, and navigation.
- Run the existing analyzer and tests.
- Identify how Firebase client configuration is currently supplied on each
  platform.
- Record existing failures separately from failures introduced by this task.

Do not remove or reset unrelated work already present in the repository.

### 2. Preserve Email/Password Authentication

Keep all existing behavior working:

- Registration
- Login
- Logout
- Password change for password-based users
- Session restoration after app restart
- ID-token refresh
- Auth-state updates through `AuthGate`
- Authenticated Realtime Database reads and writes

Existing Firebase UIDs must remain unchanged. Do not migrate, recreate, merge,
or delete existing accounts.

Add regression coverage around the current email/password session behavior
before changing shared authentication code.

### 3. Add Shared Guest Mode

Add an explicit anonymous or guest sign-in action to the login screen.

Requirements:

- Use Firebase Authentication's anonymous provider for each installation's
  authenticated session.
- Create and persist the same application session shape used by other methods.
- Ensure anonymous ID tokens refresh correctly.
- Allow `DatabaseService` to use the anonymous user's ID token normally.
- Mark the session as guest/anonymous so data routing and provider-specific UI
  do not depend on whether the email string is empty.
- Route every guest session to one stable shared data location such as
  `/sharedGuest/default`, rather than `/users/{anonymousUid}`.
- Define the shared guest path in one constant or repository abstraction. Do
  not scatter the literal path throughout widgets and services.
- Initialize the shared guest record only if it does not already exist. Use a
  transaction, ETag/conditional write, or another atomic approach so two first
  visitors cannot reset or replace each other's data.
- Never overwrite the existing shared guest record during sign-in.
- Never write shared guest data under a newly generated anonymous UID.
- Preserve the current `/users/{uid}` behavior for email/password and Google
  users.
- Prevent duplicate requests while sign-in is in progress.
- Show a safe Albanian error message when sign-in fails.

Anonymous users may not have an email address. Update the user/session model
only as much as necessary, and make all affected UI and database fallback
behavior safe for an empty or absent email.

Do not show password-change actions to an anonymous user. Logout must still
work normally.

Closing and reopening the application without logging out must restore the
stored guest session and cached shared guest data. After the app has been
opened successfully online at least once, the same installation must be able to
open its cached guest experience while offline.

Explicitly logging out may discard the current anonymous Firebase identity.
When the user enters guest mode again with internet access, Firebase may return
a different anonymous UID, but the app must still:

- Open the same shared guest workspace.
- Reuse the same local guest profile-image namespace on that installation.
- Show the local profile photo previously imported on that installation.

A first-time anonymous sign-in and a new sign-in after explicit logout may
require internet access. Do not pretend that Firebase can create a new
anonymous session offline.

Do not automatically link, upgrade, or delete anonymous accounts as part of
this task unless the repository already has a deliberate account-linking flow.

### 4. Keep Only the Guest Profile Photo Local

The profile photo selected in shared guest mode must remain local to the
current Android installation, iOS installation, browser profile, or installed
PWA. No other guest data should vary by installation.

Requirements:

- Do not upload the guest profile-image bytes to Firebase Realtime Database,
  Firebase Storage, or another remote service.
- Do not save a guest-local profile filesystem path, browser reference, base64
  value, or `local-image://` reference in the shared guest record.
- Do not use the temporary anonymous Firebase UID as the profile-image storage
  key. A new anonymous UID after logout would otherwise hide the old local
  profile photo.
- Use a stable local guest profile namespace, such as
  `shared_guest_profile`, or a stable installation identifier stored locally.
- On Android and iOS, store image files inside the app's local documents/data
  area and retain only local lookup metadata.
- On Web/PWA, store image data in browser-compatible local storage with size
  checks and safe failure handling.
- On startup, resolve the guest profile photo directly from local storage,
  independently of the shared Firebase guest record.
- Replacing a profile photo on one device must not change or remove another
  device's profile photo.
- Logging out and re-entering guest mode on the same installation must retain
  that installation's local profile photo.
- Clearing app data, uninstalling the native app, removing the PWA, clearing
  browser/site storage, or using a different browser/device may remove or hide
  the local profile photo. Document this limitation clearly.

QR requirements for shared guest mode:

- Use the same shared QR value for every guest.
- Generate the same QR code from that shared value on every platform.
- Keep QR overlay/icon selection, overlay position, scanner result, and QR
  settings in the shared guest workspace when those features are enabled.
- Do not read a guest QR overlay/icon from device-specific local storage.
- Do not allow a local guest QR customization to make one guest's displayed QR
  different from another guest's displayed QR.
- If the current QR overlay icon can only be stored locally, use one common
  bundled/default QR overlay asset for shared guest mode and disable
  guest-specific overlay importing. Do not introduce Firebase Storage only for
  this task unless remote shared QR image upload is explicitly approved.
- Changing shared QR data from one guest must update the shared record and
  become visible to the other guests after synchronization.

For non-guest email/password and Google users, preserve the existing image
behavior unless a small adapter is necessary to keep the code clean.

### 5. Add Google Sign-In

Add a Google sign-in action to the login screen.

Use a currently supported Flutter package or Firebase-supported flow that works
on Android, iOS, and Web. Follow the installed package version's current API
instead of copying an outdated example.

Preferred integration shape:

1. Obtain the Google credential with the platform-appropriate Google flow.
2. Authenticate that credential with the existing Firebase project.
3. Convert the Firebase result into the existing `AuthService` session model.
4. Persist the Firebase ID token, refresh token, expiry, UID, email, and display
   name through the existing session path.
5. Emit the authenticated user through the existing auth-state stream.

If the existing REST architecture is retained, use Firebase Identity Toolkit's
supported identity-provider exchange rather than introducing a second
long-lived auth state. If a Firebase Auth SDK is introduced, make the SDK the
source of credentials while preserving the public behavior expected by
`DatabaseService` and `AuthGate`.

Handle these cases safely:

- User cancels the Google flow
- Popup is blocked or closed on Web
- Network timeout or loss
- Invalid or missing Google credential
- Google provider is disabled or misconfigured
- Account exists with another sign-in method
- Firebase rejects the credential
- App widget is disposed before the operation completes

Do not silently merge accounts. If Firebase reports an account conflict, tell
the user to use the original sign-in method. Keep the message concise and do
not expose raw tokens or provider payloads.

Google users who do not use a password must not be sent through the current
password-change flow.

### 6. Update the Login Experience

Keep the existing email/password form and registration button.

Add clear, accessible actions such as:

- `Vazhdo me Google`
- `Vazhdo si mysafir`

Requirements:

- Match the current visual system and responsive maximum width.
- Keep each action at least 48 logical pixels tall.
- Provide visible keyboard focus and hover behavior on Web.
- Add semantic labels and useful tooltips where appropriate.
- Prevent double submission.
- Keep loading states understandable without disabling unrelated navigation.
- Preserve email/password validation and submit behavior.
- Ensure the layout does not overflow on narrow phones or browser windows.
- Explain briefly that guest wallet and QR data are shared, while only the
  profile photo remains on the current device/browser.

### 7. Keep User Data Compatible

After Google sign-in:

- Reuse the Firebase UID returned by Authentication.
- Call the existing user-data initialization path only when data is missing.
- Preserve existing data for returning Google users.
- Keep Realtime Database security based on `auth.uid`.

Review settings and profile UI for assumptions that every user has an email or
password. Show only actions that are valid for the active provider.

For shared guest mode:

- Use one stable shared data/cache key that does not depend on the anonymous
  UID.
- Share balance, QR value, ticket expiration, username/label, overlay position,
  QR overlay/icon configuration, scanner result, and other guest settings.
- Exclude only the imported profile-photo bytes and local reference from shared
  data.
- Keep cached shared guest data available across anonymous UID changes.
- Handle concurrent guest writes intentionally. At minimum, document
  last-write-wins behavior and avoid resetting unrelated fields.
- Never store personal, private, or sensitive information in the shared guest
  workspace because every guest can read and modify it.

Keep existing `/users/{uid}` security rules unchanged for registered and Google
users. Add a dedicated rule only for the stable shared guest path. It should:

- Require an authenticated Firebase user.
- Restrict access to anonymous-provider sessions when Firebase rules can verify
  the sign-in provider.
- Permit only the fields and value shapes needed by the demo.
- Reject local profile-image bytes, local profile paths, local profile
  references, credentials, and unexpected fields.

Do not make `/users`, the database root, or unrelated application data public.

### 8. Verify Android Google Configuration

Re-check the current files rather than assuming configuration is complete.

At the time this prompt was written,
`android/app/google-services.json` contained no Android OAuth clients. Treat
that as a configuration warning that must be verified.

Verify and document:

- The Firebase Android app uses the exact package name from the project.
- Debug SHA-1 and SHA-256 fingerprints are registered.
- Release SHA-1 and SHA-256 fingerprints are registered for the signing setup
  used to distribute the app.
- A Google OAuth client exists for the Android package and matching SHA
  certificate.
- The required Web OAuth client exists when the Google package needs a server
  client ID.
- The local `google-services.json` is refreshed after Firebase configuration
  changes.
- Gradle applies the required Google services configuration.

Use commands such as `./gradlew signingReport` only to obtain fingerprints
locally. Do not place fingerprints, client IDs, or generated configuration
contents in this prompt or the final report.

If Firebase Console access is unavailable, do not invent values. Complete the
code work that can be completed and provide a precise manual-action checklist.

### 9. Verify iOS Google Configuration

At the time this prompt was written, the repository had no visible
`GoogleService-Info.plist` in `ios/Runner` and no Google URL scheme in
`ios/Runner/Info.plist`. Re-check this before editing.

Verify and document:

- The Firebase iOS app uses the exact bundle ID from the Xcode project.
- The correct local `GoogleService-Info.plist` is available to the Runner
  target.
- The reversed client ID is configured as an iOS URL scheme when required by
  the selected package version.
- Any required iOS callback or application delegate setup is present.
- The configuration works on both simulator-supported flows and a real device,
  noting where real-device testing is mandatory.

Do not fabricate plist values or commit newly supplied credentials. If the
required file is unavailable, provide the exact destination and manual setup
steps without showing its contents.

### 10. Verify Web Google Configuration

Verify the Firebase and Google configuration used by the Flutter Web build:

- Correct Firebase project and Web app
- Google provider enabled
- OAuth Web client configured for the app
- Authorized JavaScript origins
- Authorized redirect URIs when required
- Firebase Authentication authorized domains
- Local development domains such as `localhost`
- The actual Firebase Hosting or production domain

Use the existing configuration mechanism when possible. Do not hardcode a new
client ID or API key into a widget or duplicate it across files.

Test popup behavior in a real browser. If the selected implementation requires
a redirect fallback for browsers that block popups, implement it without
breaking session restoration or navigation.

### 11. Fix the Kthehu Button

Audit every visible `Kthehu` back action, with special attention to:

- `lib/screens/ticket_screen.dart`
- `lib/widgets/brand_mark.dart`
- `lib/widgets/app_button.dart`
- `lib/widgets/screen_shell.dart`
- Registration, settings, image editor, balance, password, ticket expiration,
  QR settings, and QR scanner screens

There is a likely hit-testing problem in `ticket_screen.dart`: interactive
content is positioned below its parent `Stack` using negative `bottom` values.
Flutter may paint a child outside a stack's bounds while pointer hit testing
outside those bounds remains unreliable. Do not leave an interactive control
outside the valid bounds of its parent.

Fix the layout structurally:

- Keep the button inside a valid, hit-testable layout region.
- Respect `SafeArea`, browser viewport changes, and iOS bottom insets.
- Avoid invisible `Stack`, overlay, modal barrier, or scroll-view layers above
  the button.
- Keep a minimum 48x48 logical-pixel tap target.
- Add comfortable padding around the label and icon.
- Preserve visible hover, focus, pressed, and disabled states.
- Ensure one click or tap triggers navigation exactly once.
- Use safe navigation behavior such as `maybePop` where the route may not have
  a parent, with an intentional fallback when appropriate.
- Do not make a back button unresponsive merely because an unrelated background
  operation is running unless leaving would corrupt state.

Test pointer, touch, and keyboard activation at narrow mobile widths, iPhone
safe-area sizes, and desktop Web widths.

### 12. Add Safe Error Handling

Extend the existing Albanian auth error mapping with user-safe messages for:

- Google cancellation
- Popup blocked or closed
- Google/Firebase configuration failure
- Anonymous provider disabled
- Network failure and timeout
- Invalid credential
- Account conflict
- Too many attempts
- General provider failure

Keep raw exceptions available for development diagnostics only when they do not
contain credentials. User-visible messages must not contain API responses,
tokens, stack traces, client IDs, or internal configuration values.

### 13. Tests

Add focused tests for the changed behavior.

At minimum, cover:

- Existing email/password login regression
- Existing stored session restoration and refresh behavior
- Anonymous session creation and persistence
- Every anonymous UID resolves to the same shared guest data path
- Shared guest initialization is non-destructive and concurrency-safe
- Shared guest cache survives an anonymous UID change
- Guest data changes are visible to another simulated guest session
- Guest profile photos use a stable local namespace rather than an anonymous UID
- Guest profile photos remain after logout and guest re-entry on the same
  installation
- Different simulated installations can hold different guest profile photos
- Guest profile-photo references and bytes are never written to shared Firebase
  data
- Shared QR values render the same QR code on different guest installations
- Guest QR overlay/icon and QR settings cannot diverge through local storage
- Google Firebase-response/session mapping without using real credentials
- Empty-email anonymous users
- Provider-aware password-change visibility
- Cancellation and failure error mapping
- Login-screen loading and duplicate-tap prevention
- `Kthehu` button hit testing and navigation
- Responsive login layout at mobile and Web sizes

Use fakes or injected adapters for Google and HTTP behavior. Tests must never
call real OAuth flows or contain real tokens, API keys, or credentials.

### 14. Validation

Run:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
flutter build apk
```

When macOS and Xcode dependencies are available, also run:

```bash
flutter build ios --no-codesign
```

Manually verify:

| Flow | Android | iOS | Web |
| --- | --- | --- | --- |
| Existing email/password login | Required | Required | Required |
| Existing user session restore | Required | Required | Required |
| Google sign-in success | Required | Required | Required |
| Google cancellation/failure | Required | Required | Required |
| Anonymous sign-in | Required | Required | Required |
| Shared guest data visible across two installations | Required | Required | Required |
| Different local profile photos across installations | Required | Required | Required |
| Same shared QR code and QR presentation | Required | Required | Required |
| Guest profile photo retained after logout and online re-entry | Required | Required | Required |
| Cached guest reopen while offline without logout | Required | Required | Required |
| Logout and return to login | Required | Required | Required |
| Realtime Database access | Required | Required | Required |
| `Kthehu` touch/click | Required | Required | Required |
| Narrow/responsive layout | Required | Required | Required |

Do not claim a platform passed if it was not actually built or tested.

---

## Acceptance Criteria

- Existing email/password users can still register, sign in, restore sessions,
  refresh tokens, access their data, change passwords, and log out.
- Google sign-in works through the same Firebase project on Android, iOS, and
  Web.
- Anonymous sign-in works on Android, iOS, and Web.
- All anonymous guest sessions access one stable shared guest data record.
- Starting guest mode never resets or recreates existing shared guest data.
- A change to shared guest data is visible to guests on other
  installations after synchronization.
- Guest profile-photo bytes and references remain local and are never stored in
  the shared guest record.
- Two devices can show different imported profile photos while displaying the
  same shared guest wallet and QR data.
- The QR value, generated QR code, QR overlay/icon, overlay position, and QR
  settings are the same for every guest after synchronization.
- Guest profile photos survive logout and online guest re-entry on the same
  installation, even when Firebase issues a different anonymous UID.
- A previously initialized guest installation can reopen cached guest data and
  its local profile photo offline when the user did not explicitly log out.
- Google and email/password users continue to access their own
  `/users/{uid}` data.
- Returning users keep the same Firebase UID and existing data.
- Anonymous and Google users are not shown invalid password-only actions.
- Failed or cancelled provider flows leave the login screen usable.
- The `Kthehu` button is reliably clickable or tappable with one action on Web
  and iOS and remains correct on Android.
- No interactive button is positioned outside its hit-testable parent bounds.
- Existing `/users/{uid}` security is not weakened; shared access is limited to
  a dedicated validated guest path.
- No secret, key, token, credential, `.env` file, QR code, or private user data
  is added.
- Analyzer, tests, and supported platform builds pass, or any tooling/config
  blocker is documented precisely.

## Final Report Required

At the end, provide:

- Files changed
- Authentication architecture used
- How existing email/password behavior was preserved
- Google and anonymous flow implementation details
- Shared guest data path, initialization, caching, concurrency, and security
  behavior
- How guest profile photos remain local, installation-specific, and stable
  across anonymous UID changes
- How QR values and QR presentation remain shared and identical for all guests
- Android, iOS, and Web configuration checks completed
- Manual Firebase Console actions still required
- Root cause and fix for the `Kthehu` button
- Tests added
- Exact validation commands run and their results
- Platforms actually tested
- Remaining risks or limitations

Do not include configuration values, fingerprints, client IDs, API keys,
tokens, credentials, QR data, or user data in the report.
