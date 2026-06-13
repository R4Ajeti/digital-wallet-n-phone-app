# Kuleta Digitale

Prototip demonstrues Flutter për Android, i lidhur me projektin ekzistues
Firebase `kuleta-digitale-n-db`.

> Ky aplikacion nuk është shërbim zyrtar dhe nuk përfaqëson asnjë komunë,
> institucion publik ose sistem real të biletave.

## Identifikuesit

- Emri i instaluar: `Kuleta Digitale`
- Firebase project ID: `kuleta-digitale-n-db`
- Android package: `com.gentool.kuletadigitalen`
- iOS bundle ID për më vonë: `com.gentool.kuletadigitalen`

## Çfarë përfshin

- Regjistrim, kyçje, dalje dhe ndryshim fjalëkalimi me Firebase Auth.
- Sesion të qëndrueshëm përmes Firebase Auth.
- Të dhëna private për secilin përdorues në Realtime Database.
- QR kod aktiv nga vlera manuale ose vlera e skanuar.
- Skanim lokal me kamerë; ruhet vetëm teksti i dekoduar.
- Ikonë të lëvizshme mbi QR kod me pozicion të ruajtur.
- Fotografi profili dhe ikonë QR të ruajtura vetëm në pajisje.
- Datë vlefshmërie një muaj nga dita kur hapet aplikacioni.
- Ndërfaqe dhe mesazhe në shqip.

Nuk përdoren Firebase Admin SDK, service accounts, Firebase Storage ose
çelësa privatë.

## Konfigurimi i Firebase

FlutterFire është konfiguruar për aplikacionin Android dhe ka gjeneruar:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

Firebase Authentication nuk ishte inicializuar në këtë projekt gjatë
verifikimit. Para provës së parë:

1. Hape
   [Firebase Authentication](https://console.firebase.google.com/project/kuleta-digitale-n-db/authentication/providers).
2. Zgjidh `Get started`, nëse shfaqet.
3. Te `Sign-in method`, aktivizo `Email/Password`.
4. Ruaj ndryshimin.

Ky është konfigurim standard i Firebase client SDK; nuk nevojiten kredenciale
administratori.

## Nisja

```bash
flutter clean
flutter pub get
$HOME/.pub-cache/bin/flutterfire configure \
  --project=kuleta-digitale-n-db \
  --platforms=android \
  --android-package-name=com.gentool.kuletadigitalen
flutter run
```

Nëse `flutterfire` është në `PATH`, prefiksi
`$HOME/.pub-cache/bin/` mund të hiqet.

APK debug gjenerohet me:

```bash
flutter build apk --debug
```

Dalja është `build/app/outputs/flutter-apk/app-debug.apk`.

## Firebase Auth

`AuthGate` dëgjon `FirebaseAuth.instance.authStateChanges()` dhe hap ekranin e
kyçjes ose ekranin kryesor. Regjistrimi krijon përdoruesin e Auth dhe të dhënat
fillestare nën `/users/{uid}`. Ndryshimi i fjalëkalimit bën ri-autentikim me
fjalëkalimin aktual para `updatePassword`.

## Realtime Database

Të dhënat ruhen nën:

```text
/users/{uid}
  email
  username
  userTypeLabel
  profile/localImagePath
  ticket/expiresAt
  ticket/expiresAtText
  qr/manualValue
  qr/scannedValue
  qr/activeSource
  qr/activeValue
  qr/updatedAt
  qrOverlay/localImagePath
  qrOverlay/positionX
  qrOverlay/positionY
  qrOverlay/updatedAt
  settings/language
  settings/demoMode
  createdAt
  updatedAt
```

Të dhënat që mungojnë riparohen me vlera të sigurta kur hapet aplikacioni.
Pozicioni i ikonës ruhet si koordinatë e normalizuar `0.0` deri `1.0`, prandaj
mbetet i qëndrueshëm në madhësi të ndryshme ekrani.

## Skanimi dhe imazhet

`mobile_scanner` lexon QR kodin nga pamja live e kamerës. `returnImage` është
çaktivizuar: imazhi nuk ruhet dhe nuk ngarkohet; në Firebase shkruhet vetëm
`rawValue`.

`image_picker` zgjedh imazhin, ndërsa `path_provider` e kopjon te dosja e
dokumenteve të aplikacionit. Në Firebase ruhet vetëm rruga lokale.
`shared_preferences` mban një kopje rezervë të rrugës për pajisjen aktuale.
Imazhet nuk sinkronizohen në pajisje të tjera.

## Rregullat e databazës

`database.rules.json` lejon një përdorues të lexojë dhe shkruajë vetëm
`/users/{uid}` e vet.

```bash
firebase deploy --only database --project kuleta-digitale-n-db
```

## Verifikimi

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test test/core_test.dart
flutter build apk --debug
```

Testet mbulojnë datat në shqip, validimin, të dhënat e paplota nga Firebase,
gjendjen boshe të QR kodit, gjenerimin e QR kodit dhe një pamje golden të
hierarkisë kryesore.

## Struktura

```text
lib/
  app.dart
  firebase_options.dart
  main.dart
  models/
  screens/
  services/
  utils/
  widgets/
test/
  core_test.dart
  goldens/home_preview.png
```

Projekti është ndërtuar për Android. Për iOS më vonë, përdor bundle ID
`com.gentool.kuletadigitalen`, shto përshkrimet e kamerës/fotove dhe riekzekuto
FlutterFire me platformën `ios`.
