import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kuletadigitalen/models/app_session_user.dart';
import 'package:kuletadigitalen/services/auth_service.dart';
import 'package:kuletadigitalen/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppSessionUser guestA;
  late AppSessionUser guestB;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    guestA = const AppSessionUser(
      uid: 'anonymous-a',
      email: '',
      displayName: 'Mysafir',
      provider: AppAuthProvider.anonymous,
    );
    guestB = const AppSessionUser(
      uid: 'anonymous-b',
      email: '',
      displayName: 'Mysafir',
      provider: AppAuthProvider.anonymous,
    );
  });

  test(
    'all anonymous UIDs resolve to one path, cache, and profile namespace',
    () {
      expect(
        DatabaseService.dataPathForUser(guestA),
        DatabaseService.sharedGuestPath,
      );
      expect(
        DatabaseService.dataPathForUser(guestB),
        DatabaseService.sharedGuestPath,
      );
      expect(guestA.dataKey, guestB.dataKey);
      expect(
        DatabaseService.cacheKeyForUser(guestA),
        DatabaseService.cacheKeyForUser(guestB),
      );
      expect(
        guestA.profileImageNamespace,
        AppSessionUser.sharedGuestProfileNamespace,
      );
      expect(guestA.profileImageNamespace, guestB.profileImageNamespace);
    },
  );

  test(
    'shared guest initialization is atomic and never overwrites a winner',
    () async {
      var sharedReads = 0;
      var conditionalWrites = 0;
      Map<String, dynamic>? proposedData;
      final existing = _sharedData(balance: 37);
      final service = DatabaseService(
        authService: _FakeAuthService(),
        clientFactory: () => MockClient((request) async {
          if (request.url.path.endsWith('/appConfig/defaultQrCodeId.json')) {
            return http.Response(jsonEncode(''), 200);
          }
          if (request.url.path.endsWith('/sharedGuest/default.json') &&
              request.method == 'GET') {
            sharedReads++;
            return http.Response(
              sharedReads == 1 ? 'null' : jsonEncode(existing),
              200,
            );
          }
          if (request.url.path.endsWith('/sharedGuest/default.json') &&
              request.method == 'PUT') {
            conditionalWrites++;
            expect(request.headers['if-match'], 'null_etag');
            proposedData = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response('', 412);
          }
          fail('Unexpected request: ${request.method} ${request.url.path}');
        }),
      );

      await service.ensureUserData(guestA);
      final cached = await service.cachedUser(guestA);

      expect(conditionalWrites, 1);
      expect(cached.balance, 37);
      expect(proposedData, isNot(contains('profile')));
      expect(jsonEncode(proposedData), isNot(contains('localImagePath')));
    },
  );

  test('shared cache survives an anonymous UID change', () async {
    SharedPreferences.setMockInitialValues({
      DatabaseService.cacheKeyForUser(guestA): jsonEncode(
        _sharedData(balance: 12),
      ),
    });
    final service = DatabaseService(authService: _FakeAuthService());

    final restored = await service.cachedUser(guestB);

    expect(restored.balance, 12);
    expect(restored.qrCodeId, isEmpty);
  });

  test(
    'guest profile references are never sent to shared Firebase data',
    () async {
      var requests = 0;
      final service = DatabaseService(
        authService: _FakeAuthService(),
        clientFactory: () => MockClient((_) async {
          requests++;
          return http.Response('{}', 200);
        }),
      );

      await service.saveProfileImagePath(
        guestA,
        'local-image://profile/device-only',
      );

      expect(requests, 0);
      expect((await service.cachedUser(guestA)).profileImagePath, isEmpty);
    },
  );

  test('a shared write is read by another anonymous session', () async {
    final backend = _sharedData(balance: 0);
    final service = DatabaseService(
      authService: _FakeAuthService(),
      clientFactory: () => MockClient((request) async {
        if (request.url.path.endsWith('/sharedGuest/default.json') &&
            request.method == 'GET') {
          return http.Response(jsonEncode(backend), 200);
        }
        if (request.url.path.endsWith('/sharedGuest/default.json') &&
            request.method == 'PATCH') {
          _merge(backend, jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response(jsonEncode(backend), 200);
        }
        fail('Unexpected request: ${request.method} ${request.url.path}');
      }),
    );

    await service.ensureUserData(guestA);
    await service.saveBalance(guestA, 18);
    await service.ensureUserData(guestB);

    expect((await service.cachedUser(guestB)).balance, 18);
    expect(
      (await service.cachedUser(guestA)).qrCodeId,
      (await service.cachedUser(guestB)).qrCodeId,
    );
  });

  test('database rules isolate and validate the shared guest record', () async {
    final rules =
        jsonDecode(await File('database.rules.json').readAsString())
            as Map<String, dynamic>;
    final root = rules['rules'] as Map<String, dynamic>;
    final shared =
        (root['sharedGuest'] as Map<String, dynamic>)['default']
            as Map<String, dynamic>;

    expect(shared['.read'], contains('anonymous'));
    expect(shared['.write'], contains('anonymous'));
    expect(shared, isNot(contains('profile')));
    expect((shared[r'$other'] as Map<String, dynamic>)['.validate'], isFalse);
  });
}

class _FakeAuthService extends AuthService {
  @override
  Future<String> requireValidIdToken() async => 'test-auth-value';
}

Map<String, dynamic> _sharedData({required num balance}) {
  return {
    'username': 'Mysafir',
    'wallet': {'balance': balance},
    'userTypeLabel': 'Test label',
    'ticket': {
      'expiresAt': '2026-07-14T00:00:00.000',
      'expiresAtText': 'Test date',
    },
    'qr': {'value': '', 'updatedAt': '2026-06-14T00:00:00.000Z'},
    'qrOverlay': {
      'type': 'default',
      'positionX': 0.25,
      'positionY': 0.75,
      'updatedAt': '2026-06-14T00:00:00.000Z',
    },
    'settings': {'language': 'sq', 'demoMode': true},
    'createdAt': '2026-06-14T00:00:00.000Z',
    'updatedAt': '2026-06-14T00:00:00.000Z',
  };
}

void _merge(Map<String, dynamic> target, Map<String, dynamic> source) {
  for (final entry in source.entries) {
    final current = target[entry.key];
    final incoming = entry.value;
    if (current is Map<String, dynamic> && incoming is Map<String, dynamic>) {
      _merge(current, incoming);
    } else {
      target[entry.key] = incoming;
    }
  }
}
