# Kuleta Digitale

Aplikacion demonstrues Flutter për Android dhe iOS, i lidhur me Firebase
Authentication dhe Firebase Realtime Database.

> Ky aplikacion nuk është shërbim zyrtar dhe nuk përfaqëson asnjë komunë,
> institucion publik ose sistem real të biletave.

## Përmbledhje

- Regjistrim, kyçje, dalje dhe ndryshim fjalëkalimi me email.
- Sesion i ruajtur lokalisht dhe rifreskim automatik i Firebase ID token.
- Të dhëna private për secilin përdorues në Realtime Database.
- Bilanc dhe datë vlefshmërie të biletës të ndryshueshme.
- QR Code ID i ruajtur nga vlera manuale ose nga skanimi me kamerë.
- QR Code ID standard për përdoruesit e rinj, i lexuar nga Firebase.
- Mbështetje offline me cache lokale dhe sinkronizim të shkrimeve të pritshme.
- Fotografi profili dhe ikonë mbi QR të ruajtura vetëm në pajisje.
- Ndërfaqe dhe mesazhe në shqip.
- Ikona të aplikacionit për Android dhe iOS.

## Identifikuesit

| Konfigurimi | Vlera |
| --- | --- |
| Emri i aplikacionit | `Kuleta Digitale` |
| Firebase project ID | `kuleta-digitale-n-db` |
| Android application ID | `com.gentool.kuletadigitalen` |
| iOS bundle ID | `com.gentool.kuletadigitalen` |
| Versioni | `1.0.0+1` |

## Teknologjitë

- Flutter `3.44.2`
- Dart `3.12.2`
- Firebase Authentication REST API
- Firebase Realtime Database REST API
- `mobile_scanner` për skanimin e QR kodeve
- `permission_handler` për lejen e kamerës
- `shared_preferences` për sesionin, cache dhe shkrimet offline
- `image_picker` dhe `path_provider` për imazhet lokale

Aplikacioni nuk varet nga FlutterFire gjatë ekzekutimit. Firebase Auth dhe
Realtime Database përdoren drejtpërdrejt përmes REST API. Nuk përdoren Firebase
Admin SDK, service accounts, Firebase Storage ose çelësa privatë.

## Kërkesat

- Flutter SDK në kanalin stable
- Android Studio dhe Android SDK për Android
- Xcode dhe një Apple Development Team për iOS
- Firebase CLI vetëm kur ndryshohen ose publikohen rregullat e databazës
- Pajisje me Developer Mode aktiv për instalim direkt gjatë zhvillimit

Kontrollo mjedisin:

```bash
flutter doctor
flutter devices
flutter pub get
```

## Nisja në Android

Lidhe pajisjen, aktivizo USB debugging dhe kontrollo që shfaqet:

```bash
adb devices
flutter devices
```

Nise në pajisjen e zgjedhur:

```bash
flutter run -d <android-device-id>
```

Shembulli për pajisjen e përdorur aktualisht:

```bash
flutter run -d 21121FDF6001KZ
```

Gjenero APK:

```bash
flutter build apk --debug
```

APK-ja krijohet te `build/app/outputs/flutter-apk/app-debug.apk`.

> Konfigurimi aktual Android përdor debug signing edhe për build-in release.
> Para publikimit në Play Store duhet shtuar një release keystore privat.

## Nisja në iPhone

Projekti iOS është i konfiguruar me bundle ID
`com.gentool.kuletadigitalen`. Në një Mac ose Apple account tjetër, hape
`ios/Runner.xcworkspace` në Xcode dhe zgjidh Development Team te
**Runner > Signing & Capabilities**.

Për zhvillim me debugger:

```bash
flutter run -d <ios-device-id>
```

Debug build mund të varet nga lidhja me Flutter debugger. Për ta instaluar
aplikacionin që të hapet nga Home Screen pa kabllo, përdor release mode:

```bash
flutter run --release --no-resident -d <ios-device-id>
```

Shembulli për iPhone-in e konfiguruar:

```bash
flutter run --release --no-resident -d 00008140-000C75443A62801C
```

Pas instalimit, mbylle procesin e komandës nëse është ende aktiv, shkëpute
kabllon dhe hape aplikacionin normalisht nga Home Screen. Aplikacioni vazhdon
të hapet për sa kohë provisioning profile dhe developer certificate janë të
vlefshme.

Nëse iOS bllokon hapjen:

1. Aktivizo **Settings > Privacy & Security > Developer Mode**.
2. Konfirmo besimin për developer account në **VPN & Device Management**, nëse
   kërkohet.
3. Kontrollo signing team dhe provisioning profile në Xcode.
4. Riinstalo build-in release pas çdo ndryshimi të signing.

## Firebase

### Authentication

Në Firebase Console, te **Authentication > Sign-in method**, duhet të jetë
aktivizuar provideri **Email/Password**.

Sesioni ruhet në pajisje. Kur ID token është afër skadimit, aplikacioni e
rifreskon me Firebase Secure Token API.

### QR Code ID standard

Gjatë regjistrimit aplikacioni lexon:

```text
/appConfig/defaultQrCodeId
```

Vlera e konfiguruar aktualisht është:

```text
AD307A67-E263-4800-87C0-C14D0B1B83AF
```

Nëse kjo vlerë ekziston në Firebase, ajo ruhet te profili i përdoruesit të ri.
Nëse mungon ose nuk mund të lexohet, formulari i regjistrimit kërkon që
përdoruesi ta shkruajë QR Code ID.

Pas krijimit të profilit, QR Code ID ndryshon vetëm kur përdoruesi:

- shkruan një vlerë të re te **Cilësimet e QR Code-it**; ose
- skanon një QR kod të ri me kamerë.

Vlera ruhet lokalisht dhe në:

```text
/users/{uid}/qr/value
```

### Struktura e databazës

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

Rrugët e imazheve janë lokale dhe nuk sinkronizojnë skedarët ndërmjet
pajisjeve. QR scanner ruan vetëm tekstin e dekoduar, jo pamjen nga kamera.

### Rregullat e databazës

`database.rules.json` lejon lexim publik vetëm të `appConfig`, ndalon shkrimin
e tij nga klienti dhe kufizon çdo profil te përdoruesi i autentikuar përkatës.

Publiko rregullat:

```bash
firebase login
firebase use kuleta-digitale-n-db
firebase deploy --only database
```

Vlera `appConfig/defaultQrCodeId` duhet administruar nga Firebase Console ose
nga një mjedis administrativ, jo nga aplikacioni klient.

## Lejet

Android deklaron lejet për internet, gjendjen e rrjetit, kamerën dhe zgjedhjen
e imazheve në `android/app/src/main/AndroidManifest.xml`.

iOS deklaron `NSCameraUsageDescription` në `ios/Runner/Info.plist`. Kur
përdoruesi shtyp **Skano QR Code**, aplikacioni:

1. kërkon lejen e kamerës;
2. hap scanner-in kur leja pranohet;
3. shfaq mesazh kur leja refuzohet; dhe
4. drejton te Settings kur leja është permanently denied ose restricted.

## Ikona e aplikacionit

Burimi i ikonës është:

```text
experimental-resource/icon/stema-komunes-prishtines.png
```

Rigjenero ikonat për të dy platformat:

```bash
dart run flutter_launcher_icons
```

## Verifikimi

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --release
```

Testet mbulojnë validimin, formatimin e datave, të dhënat e paplota nga
Firebase, migrimin e skemës së vjetër QR, ruajtjen manuale, gjendjen boshe,
gjenerimin e QR kodit dhe pamjen golden të ekranit kryesor.

## Struktura e projektit

```text
android/                 Konfigurimi Android
ios/                     Projekti aktiv iOS
lib/
  models/                Modelet e sesionit dhe përdoruesit
  screens/               Ekranet e aplikacionit
  services/              Firebase REST, cache dhe imazhet lokale
  theme/                 Ngjyrat dhe stilet
  utils/                 Validimi, datat dhe mesazhet
  widgets/               Komponentët e ripërdorshëm
test/                    Testet widget, unit dhe golden
database.rules.json      Rregullat e Realtime Database
commands.txt             Komanda lokale të dobishme për pajisjet
```
