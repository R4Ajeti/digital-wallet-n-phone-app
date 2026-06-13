import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuletadigitalen/app.dart';
import 'package:kuletadigitalen/models/app_user_data.dart';
import 'package:kuletadigitalen/screens/qr_settings_screen.dart';
import 'package:kuletadigitalen/services/auth_service.dart';
import 'package:kuletadigitalen/utils/albanian_date.dart';
import 'package:kuletadigitalen/utils/validators.dart';
import 'package:kuletadigitalen/widgets/brand_mark.dart';
import 'package:kuletadigitalen/widgets/profile_card.dart';
import 'package:kuletadigitalen/widgets/qr_ticket_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  group('Datat në shqip', () {
    test('shton një muaj duke respektuar fundin e muajit', () {
      expect(oneMonthFrom(DateTime(2026, 1, 31)), DateTime(2026, 2, 28));
      expect(oneMonthFrom(DateTime(2024, 1, 31)), DateTime(2024, 2, 29));
      expect(oneMonthFrom(DateTime(2026, 12, 13)), DateTime(2027, 1, 13));
    });

    test('formaton emrat e muajve në shqip', () {
      expect(formatAlbanianDate(DateTime(2026, 7, 23)), '23 Korrik 2026');
      expect(formatAlbanianDate(DateTime(2026, 11, 1)), '1 Nëntor 2026');
    });
  });

  group('Validimi', () {
    test('refuzon email dhe fjalëkalim të pavlefshëm', () {
      expect(validateEmail('jo-email'), isNotNull);
      expect(validateEmail('demo@example.com'), isNull);
      expect(validatePassword('123'), isNotNull);
      expect(validatePassword('123456'), isNull);
    });
  });

  test('shpjegon qartë kur Firebase Authentication nuk është aktivizuar', () {
    final message = authErrorInAlbanian(
      const RestAuthException('CONFIGURATION_NOT_FOUND'),
    );

    expect(message, contains('Firebase Authentication nuk është aktivizuar'));
    expect(message, contains('Email/Password'));
  });

  test('modeli toleron të dhëna të paplota nga Firebase', () {
    final data = AppUserData.fromValue({
      'email': 'demo@example.com',
      'qrOverlay': {'positionX': 0.25},
    });

    expect(data.email, 'demo@example.com');
    expect(data.userTypeLabel, AppUserData.defaultUserType);
    expect(data.qrCodeId, isEmpty);
    expect(data.overlayPositionX, 0.25);
    expect(data.overlayPositionY, 0.0);
  });

  test('modeli përdor vlerën e vetme QR dhe toleron skemën e vjetër', () {
    final data = AppUserData.fromValue({
      'qr': {'value': 'QR-I-RI', 'manualValue': 'QR-I-RUAJTUR-NGA-PERDORUESI'},
    });

    expect(data.qrCodeId, 'QR-I-RI');
    expect(AppUserData.demo(uid: 'user-123').qrCodeId, isEmpty);
  });

  testWidgets('cilësimet QR kanë vetëm një fushë dhe butonin e skanimit', (
    tester,
  ) async {
    var savedValue = '';
    var scanCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: QrSettingsContent(
          qrCodeId: '',
          onSave: (value) async => savedValue = value,
          onScan: () async => scanCount++,
        ),
      ),
    );

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Skano QR Code'), findsOneWidget);
    expect(find.text('Burimi aktiv'), findsNothing);
    expect(find.text('Kodi i skanuar'), findsNothing);
    expect(find.text('Fshij'), findsNothing);

    await tester.enterText(find.byType(TextFormField), '  QR-MANUAL-123  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(savedValue, 'QR-MANUAL-123');

    await tester.tap(find.text('Skano QR Code'));
    await tester.pump();
    expect(scanCount, 1);
  });

  testWidgets('fusha bosh nuk e mbishkruan QR ID ekzistues', (tester) async {
    var saveCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: QrSettingsContent(
          qrCodeId: 'QR-EKZISTUES',
          onSave: (_) async => saveCount++,
          onScan: () async {},
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(saveCount, 0);
  });

  testWidgets('QR widget tregon gjendjen boshe pa udhëzuesin e lëvizjes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: QrTicketWidget(
            qrValue: '',
            overlayImagePath: '',
            positionX: 0.5,
            positionY: 0.5,
            onPositionSaved: (_, _) async {},
          ),
        ),
      ),
    );

    expect(find.text('Nuk ka ende një QR kod aktiv'), findsOneWidget);
    expect(find.text('Ikona lëvizet'), findsNothing);
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('QR widget gjeneron kodin aktiv', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: QrTicketWidget(
            qrValue: 'QR-AKTIV-123',
            overlayImagePath: '',
            positionX: 0.5,
            positionY: 0.5,
            onPositionSaved: (_, _) async {},
          ),
        ),
      ),
    );

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.byType(BrandMark), findsOneWidget);
  });

  testWidgets('paraqitja kryesore ruan hierarkinë vizuale', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  QrTicketWidget(
                    qrValue: 'QR-PREVIEW-2026',
                    overlayImagePath: '',
                    positionX: 0.5,
                    positionY: 0.42,
                    onPositionSaved: (_, _) async {},
                  ),
                  const SizedBox(height: 16),
                  const ProfileCard(
                    userTypeLabel: AppUserData.defaultUserType,
                    imagePath: '',
                  ),
                  const SizedBox(height: 16),
                  const TicketValidityCard(expirationText: '13 Korrik 2026'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/home_preview.png'),
    );
  });
}
