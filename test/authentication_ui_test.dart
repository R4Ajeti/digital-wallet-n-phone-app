import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuletadigitalen/app.dart';
import 'package:kuletadigitalen/models/app_session_user.dart';
import 'package:kuletadigitalen/models/app_user_data.dart';
import 'package:kuletadigitalen/screens/login_screen.dart';
import 'package:kuletadigitalen/screens/settings_screen.dart';
import 'package:kuletadigitalen/screens/ticket_screen.dart';
import 'package:kuletadigitalen/services/auth_service.dart';
import 'package:kuletadigitalen/services/database_service.dart';
import 'package:kuletadigitalen/services/local_image_service.dart';

void main() {
  testWidgets('login is responsive and prevents duplicate guest submissions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _DelayedGuestAuthService();
    final database = _FakeDatabaseService();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: LoginScreen(authService: auth, databaseService: database),
      ),
    );
    await tester.pump();

    expect(find.text('Vazhdo me Google'), findsOneWidget);
    expect(find.text('Vazhdo si mysafir'), findsOneWidget);
    expect(find.textContaining('kuleta dhe QR kodi ndahen'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('guest-login-button'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);

    final guestButton = find.byKey(const Key('guest-login-button'));
    await tester.ensureVisible(guestButton);
    await tester.pump();
    await tester.tap(guestButton);
    await tester.tap(guestButton, warnIfMissed: false);
    expect(auth.anonymousCalls, 1);

    auth.complete();
    await tester.pump();
    expect(database.ensureCalls, 1);
  });

  testWidgets('password and local QR overlay actions are provider-aware', (
    tester,
  ) async {
    const guest = AppSessionUser(
      uid: 'anonymous-settings',
      email: '',
      displayName: 'Mysafir',
      provider: AppAuthProvider.anonymous,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const SettingsScreen(user: guest),
      ),
    );

    expect(find.text('Ndrysho fjalëkalimin'), findsNothing);
    expect(find.text('Ndrysho ikonën e QR Kodit'), findsNothing);
    expect(find.textContaining('hapësirën e përbashkët'), findsOneWidget);

    const googleUser = AppSessionUser(
      uid: 'google-settings',
      email: 'google@example.test',
      displayName: 'Google Person',
      provider: AppAuthProvider.google,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const SettingsScreen(user: googleUser),
      ),
    );

    expect(find.text('Ndrysho fjalëkalimin'), findsNothing);
    expect(find.text('Ndrysho ikonën e QR Kodit'), findsOneWidget);
  });

  testWidgets('ticket Kthehu stays inside the viewport and pops once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const user = AppSessionUser(
      uid: 'ticket-user',
      email: 'ticket@example.test',
      displayName: 'Ticket Person',
    );
    final database = _FakeDatabaseService();
    final images = _FakeLocalImageService();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TicketScreen(
                      user: user,
                      databaseService: database,
                      localImageService: images,
                    ),
                  ),
                ),
                child: const Text('Hap biletën'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Hap biletën'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final backButton = find.byKey(const Key('ticket-back-button'));
    expect(backButton, findsOneWidget);
    expect(tester.getSize(backButton).height, greaterThanOrEqualTo(48));
    expect(
      tester.getBottomRight(backButton).dy,
      lessThanOrEqualTo(tester.view.physicalSize.height / 2),
    );

    await tester.tap(backButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Hap biletën'), findsOneWidget);
    expect(backButton, findsNothing);
  });
}

class _DelayedGuestAuthService extends AuthService {
  final _completer = Completer<AppSessionUser>();
  int anonymousCalls = 0;

  @override
  Future<AppSessionUser> loginAnonymously() {
    anonymousCalls++;
    return _completer.future;
  }

  void complete() {
    _completer.complete(
      const AppSessionUser(
        uid: 'anonymous-login',
        email: '',
        displayName: 'Mysafir',
        provider: AppAuthProvider.anonymous,
      ),
    );
  }
}

class _FakeDatabaseService extends DatabaseService {
  int ensureCalls = 0;

  @override
  Future<void> ensureUserData(AppSessionUser user) async {
    ensureCalls++;
  }

  @override
  Stream<AppUserData> watchUser(AppSessionUser user) {
    return Stream<AppUserData>.value(_testUserData);
  }

  @override
  Future<void> saveOverlayPosition(
    AppSessionUser user,
    double positionX,
    double positionY,
  ) async {}
}

class _FakeLocalImageService extends LocalImageService {
  @override
  Future<Uint8List?> resolveAvailableBytes({
    required String uid,
    required LocalImageKind kind,
    required String firebasePath,
  }) async {
    return null;
  }
}

const _testUserData = AppUserData(
  email: '',
  username: 'Test',
  balance: 0,
  userTypeLabel: AppUserData.defaultUserType,
  profileImagePath: '',
  expiresAt: '',
  expiresAtText: 'Test date',
  qrCodeId: '',
  overlayImagePath: '',
  overlayPositionX: 0,
  overlayPositionY: 0,
);
