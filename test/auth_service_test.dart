import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kuletadigitalen/models/app_session_user.dart';
import 'package:kuletadigitalen/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.resetForTesting();
  });

  test('email login keeps the existing REST session contract', () async {
    final service = AuthService(
      clientFactory: () => MockClient((request) async {
        expect(request.url.path, contains('signInWithPassword'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'person@example.test');
        expect(body['password'], 'password-value');
        return http.Response(
          jsonEncode({
            'idToken': 'test-id-value',
            'refreshToken': 'test-refresh-value',
            'localId': 'password-user',
            'email': 'person@example.test',
            'displayName': 'Person',
            'expiresIn': '3600',
          }),
          200,
        );
      }),
    );

    final user = await service.login(
      email: ' person@example.test ',
      password: 'password-value',
    );

    expect(user.uid, 'password-user');
    expect(user.provider, AppAuthProvider.password);
    expect(user.canChangePassword, isTrue);
    expect(await service.requireValidIdToken(), 'test-id-value');
  });

  test(
    'stored sessions restore provider metadata without a network call',
    () async {
      final service = AuthService(
        clientFactory: () => MockClient(
          (_) async => http.Response(
            jsonEncode({
              'idToken': 'stored-id-value',
              'refreshToken': 'stored-refresh-value',
              'localId': 'stored-user',
              'email': 'stored@example.test',
              'expiresIn': '3600',
            }),
            200,
          ),
        ),
      );
      await service.login(
        email: 'stored@example.test',
        password: 'password-value',
      );

      await AuthService.resetForTesting(clearStoredSession: false);
      final restored = await AuthService(
        clientFactory: () => MockClient((_) async {
          fail('Session restoration must not call the network.');
        }),
      ).currentUser();

      expect(restored?.uid, 'stored-user');
      expect(restored?.provider, AppAuthProvider.password);
    },
  );

  test('token refresh preserves the stored authentication provider', () async {
    final initialTime = DateTime.utc(2026, 1, 1);
    var refreshCalls = 0;
    http.Client clientFactory() => MockClient((request) async {
      if (request.url.host == 'securetoken.googleapis.com') {
        refreshCalls++;
        return http.Response(
          jsonEncode({
            'id_token': 'refreshed-id-value',
            'refresh_token': 'refreshed-refresh-value',
            'user_id': 'refresh-user',
            'expires_in': '3600',
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'idToken': 'expired-id-value',
          'refreshToken': 'initial-refresh-value',
          'localId': 'refresh-user',
          'email': 'refresh@example.test',
          'expiresIn': '1',
        }),
        200,
      );
    });
    final service = AuthService(
      now: () => initialTime,
      clientFactory: clientFactory,
    );
    await service.login(
      email: 'refresh@example.test',
      password: 'password-value',
    );

    final refreshingService = AuthService(
      now: () => initialTime.add(const Duration(hours: 1)),
      clientFactory: clientFactory,
    );
    final value = await refreshingService.requireValidIdToken();

    expect(value, 'refreshed-id-value');
    expect(refreshCalls, 1);
    expect(
      (await refreshingService.currentUser())?.provider,
      AppAuthProvider.password,
    );
  });

  test('anonymous login persists an empty-email guest session', () async {
    final service = AuthService(
      clientFactory: () => MockClient(
        (_) async => http.Response(
          jsonEncode({
            'idToken': 'anonymous-id-value',
            'refreshToken': 'anonymous-refresh-value',
            'localId': 'anonymous-user-a',
            'expiresIn': '3600',
          }),
          200,
        ),
      ),
    );

    final user = await service.loginAnonymously();

    expect(user.email, isEmpty);
    expect(user.displayName, 'Mysafir');
    expect(user.isAnonymous, isTrue);
    expect(user.canChangePassword, isFalse);
    expect(user.dataKey, AppSessionUser.sharedGuestDataKey);
  });

  test('Google Firebase response maps into the common session model', () async {
    final service = AuthService(
      clientFactory: () => MockClient((request) async {
        expect(request.url.path, contains('signInWithIdp'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['postBody'], contains('providerId=google.com'));
        return http.Response(
          jsonEncode({
            'idToken': 'firebase-google-id-value',
            'refreshToken': 'firebase-google-refresh-value',
            'localId': 'google-user',
            'email': 'google@example.test',
            'displayName': 'Google Person',
            'expiresIn': '3600',
          }),
          200,
        );
      }),
    );

    final user = await service.loginWithGoogleIdToken(
      'google-credential-value',
    );

    expect(user.uid, 'google-user');
    expect(user.provider, AppAuthProvider.google);
    expect(user.canChangePassword, isFalse);
  });

  test('provider errors map to safe Albanian messages', () {
    expect(
      authErrorInAlbanian(const RestAuthException('google-canceled')),
      contains('anulua'),
    );
    expect(
      authErrorInAlbanian(
        const RestAuthException('account-exists-with-different-credential'),
      ),
      contains('metodën origjinale'),
    );
    expect(
      authErrorInAlbanian(const RestAuthException('OPERATION_NOT_ALLOWED')),
      contains('nuk është aktivizuar'),
    );
  });
}
