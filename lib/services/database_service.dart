import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_session_user.dart';
import '../models/app_user_data.dart';
import '../utils/albanian_date.dart';
import 'auth_service.dart';

class DatabaseService {
  DatabaseService({AuthService? authService})
    : _authService = authService ?? AuthService();

  static const _databaseUrl =
      'https://kuleta-digitale-n-db-default-rtdb.europe-west1.firebasedatabase.app';
  static final _controllers = <String, StreamController<AppUserData>>{};

  final AuthService _authService;

  Stream<AppUserData> watchUser(String uid) {
    final controller = _controllers.putIfAbsent(
      uid,
      () => StreamController<AppUserData>.broadcast(),
    );
    unawaited(_primeUser(uid));
    return controller.stream;
  }

  Future<AppUserData> cachedUser(String uid) async {
    return AppUserData.fromValue(await _cachedMap(uid));
  }

  Future<String> fetchDefaultQrCodeId() async {
    final value = await _publicGet('appConfig/defaultQrCodeId.json');
    return value?.toString().trim() ?? '';
  }

  Future<void> createDefaultUser({
    required AppSessionUser user,
    required String username,
    String qrCodeId = '',
  }) async {
    final now = DateTime.now();
    final expiration = oneMonthFrom(now);
    final timestamp = now.toUtc().toIso8601String();
    var configuredQrCodeId = '';
    try {
      configuredQrCodeId = await fetchDefaultQrCodeId();
    } catch (_) {
      // The registration screen can provide the last value read from Firebase.
    }
    final initialQrCodeId = configuredQrCodeId.isNotEmpty
        ? configuredQrCodeId
        : qrCodeId.trim();
    if (initialQrCodeId.isEmpty) {
      throw const DatabaseRestException(
        'A QR code ID is required when no Firebase default is configured.',
      );
    }
    final data = <String, Object?>{
      'email': user.email,
      'username': username.trim().isEmpty ? user.displayName : username.trim(),
      'wallet': {'balance': 0.0},
      'userTypeLabel': AppUserData.defaultUserType,
      'profile': {'localImagePath': ''},
      'ticket': {
        'expiresAt': expiration.toIso8601String(),
        'expiresAtText': formatAlbanianDate(expiration),
      },
      'qr': {'value': initialQrCodeId, 'updatedAt': timestamp},
      'qrOverlay': {
        'localImagePath': '',
        'positionX': 0.0,
        'positionY': 0.0,
        'updatedAt': timestamp,
      },
      'settings': {'language': 'sq', 'demoMode': true},
      'createdAt': timestamp,
      'updatedAt': timestamp,
    };

    await _cacheAndEmit(user.uid, data);
    try {
      await _put('users/${user.uid}.json', data);
    } catch (_) {
      await _queueSet(user.uid, data);
    }
  }

  Future<void> ensureUserData(AppSessionUser user) async {
    if (!await flushPendingWrites(user.uid)) {
      return;
    }
    Map<String, Object?> data;
    try {
      data = _map(await _get('users/${user.uid}.json'));
    } catch (_) {
      final cached = await _cachedMap(user.uid);
      if (cached.isEmpty) {
        await _cacheAndEmit(user.uid, _defaultUserMap(user));
      }
      return;
    }

    if (data.isEmpty) {
      final cached = await _cachedMap(user.uid);
      final existingQrCodeId = AppUserData.fromValue(cached).qrCodeId;
      await createDefaultUser(
        user: user,
        username: user.displayName,
        qrCodeId: existingQrCodeId,
      );
      return;
    }

    final now = DateTime.now();
    final expiration = oneMonthFrom(now);
    final expirationText = formatAlbanianDate(expiration);
    final ticket = _map(data['ticket']);
    final updates = <String, Object?>{};

    void addIfMissing(String path, Object? currentValue, Object defaultValue) {
      if (currentValue == null || currentValue.toString().trim().isEmpty) {
        updates[path] = defaultValue;
      }
    }

    addIfMissing('email', data['email'], user.email);
    addIfMissing('username', data['username'], user.displayName);
    addIfMissing(
      'userTypeLabel',
      data['userTypeLabel'],
      AppUserData.defaultUserType,
    );
    if (_map(data['wallet'])['balance'] == null) {
      updates['wallet/balance'] = 0.0;
    }
    addIfMissing(
      'profile/localImagePath',
      _map(data['profile'])['localImagePath'],
      '',
    );
    addIfMissing(
      'qrOverlay/localImagePath',
      _map(data['qrOverlay'])['localImagePath'],
      '',
    );
    if (_map(data['qrOverlay'])['positionX'] == null) {
      updates['qrOverlay/positionX'] = 0.0;
    }
    if (_map(data['qrOverlay'])['positionY'] == null) {
      updates['qrOverlay/positionY'] = 0.0;
    }
    if (ticket['expiresAtText'] == null ||
        ticket['expiresAtText'].toString().isEmpty) {
      updates['ticket/expiresAt'] = expiration.toIso8601String();
      updates['ticket/expiresAtText'] = expirationText;
    }
    if (_map(data['settings'])['language'] == null) {
      updates['settings/language'] = 'sq';
    }
    if (_map(data['settings'])['demoMode'] == null) {
      updates['settings/demoMode'] = true;
    }
    addIfMissing('createdAt', data['createdAt'], now.toUtc().toIso8601String());

    if (updates.isNotEmpty) {
      updates['updatedAt'] = now.toUtc().toIso8601String();
      await _update(user.uid, updates);
      data = await _cachedMap(user.uid);
    } else {
      await _cacheAndEmit(user.uid, data);
    }
  }

  Future<bool> flushPendingWrites(String uid) async {
    final preferences = await SharedPreferences.getInstance();
    final pending = preferences.getStringList(_pendingKey(uid)) ?? const [];
    if (pending.isEmpty) {
      return true;
    }

    final remaining = <String>[];
    for (final item in pending) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        final type = decoded['type']?.toString() ?? 'patch';
        final data = _map(decoded['data']);
        if (type == 'set') {
          await _put('users/$uid.json', data);
        } else {
          await _patch('users/$uid.json', data);
        }
      } catch (_) {
        remaining.add(item);
      }
    }

    if (remaining.isEmpty) {
      await preferences.remove(_pendingKey(uid));
    } else {
      await preferences.setStringList(_pendingKey(uid), remaining);
    }
    return remaining.isEmpty;
  }

  Future<void> saveBalance(String uid, double balance) {
    return _update(uid, {'wallet/balance': balance.clamp(0.0, 999999.0)});
  }

  Future<void> saveTicketExpiration(String uid, DateTime expiration) {
    final normalized = DateTime(
      expiration.year,
      expiration.month,
      expiration.day,
    );
    return _update(uid, {
      'ticket/expiresAt': normalized.toIso8601String(),
      'ticket/expiresAtText': formatAlbanianDate(normalized),
    });
  }

  Future<void> saveQrCodeId(String uid, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, 'value', 'QR code ID cannot be empty.');
    }
    return _update(uid, {
      'qr/value': normalized,
      'qr/manualValue': null,
      'qr/scannedValue': null,
      'qr/activeSource': null,
      'qr/activeValue': null,
      'qr/updatedAt': _timestamp,
    });
  }

  Future<void> saveProfileImagePath(String uid, String path) {
    return _update(uid, {'profile/localImagePath': path});
  }

  Future<void> saveOverlayImagePath(String uid, String path) {
    return _update(uid, {
      'qrOverlay/localImagePath': path,
      'qrOverlay/updatedAt': _timestamp,
    });
  }

  Future<void> saveOverlayPosition(
    String uid,
    double positionX,
    double positionY,
  ) {
    return _update(uid, {
      'qrOverlay/positionX': positionX.clamp(0.0, 1.0),
      'qrOverlay/positionY': positionY.clamp(0.0, 1.0),
      'qrOverlay/updatedAt': _timestamp,
    });
  }

  Future<void> _primeUser(String uid) async {
    final cached = await _cachedMap(uid);
    if (cached.isNotEmpty) {
      _emit(uid, AppUserData.fromValue(cached));
    } else {
      _emit(uid, AppUserData.demo(uid: uid));
    }

    if (!await flushPendingWrites(uid)) {
      return;
    }
    try {
      final remote = _map(await _get('users/$uid.json'));
      if (remote.isNotEmpty) {
        await _cacheAndEmit(uid, remote);
      }
    } catch (_) {
      // Cached data has already been emitted; the next write/read will retry.
    }
  }

  Future<void> _update(String uid, Map<String, Object?> updates) async {
    final patch = _expandPathUpdates({...updates, 'updatedAt': _timestamp});
    final current = await _cachedMap(uid);
    final next = _deepCopy(current);
    _mergeDeep(next, patch);
    await _cacheAndEmit(uid, next);

    try {
      if (!await flushPendingWrites(uid)) {
        throw const DatabaseRestException('Pending writes are not synced.');
      }
      await _patch('users/$uid.json', patch);
    } catch (_) {
      await _queuePatch(uid, patch);
    }
  }

  Future<Object?> _get(String path) => _request('GET', path);
  Future<Object?> _publicGet(String path) => _requestWithoutAuth('GET', path);

  Future<void> _put(String path, Object? data) async {
    await _request('PUT', path, data: data);
  }

  Future<void> _patch(String path, Object? data) async {
    await _request('PATCH', path, data: data);
  }

  Future<Object?> _request(String method, String path, {Object? data}) async {
    final token = await _authService.requireValidIdToken();
    final separator = path.contains('?') ? '&' : '?';
    return _sendRequest(
      method,
      Uri.parse(
        '$_databaseUrl/$path$separator'
        'auth=${Uri.encodeQueryComponent(token)}',
      ),
      data: data,
    );
  }

  Future<Object?> _requestWithoutAuth(
    String method,
    String path, {
    Object? data,
  }) {
    return _sendRequest(method, Uri.parse('$_databaseUrl/$path'), data: data);
  }

  Future<Object?> _sendRequest(String method, Uri uri, {Object? data}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client
          .openUrl(method, uri)
          .timeout(const Duration(seconds: 8));
      if (data != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(data));
      }
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final text = await response.transform(utf8.decoder).join();
      final decoded = text.isEmpty ? null : jsonDecode(text);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map ? decoded['error']?.toString() : null;
        throw DatabaseRestException(message ?? 'Database request failed.');
      }
      return decoded;
    } on TimeoutException {
      throw const DatabaseRestException('Database request timed out.');
    } on SocketException {
      throw const DatabaseRestException('Network unavailable.');
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, Object?>> _cachedMap(String uid) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_cacheKey(uid));
    if (raw == null || raw.isEmpty) {
      return const {};
    }
    try {
      return _map(jsonDecode(raw));
    } catch (_) {
      await preferences.remove(_cacheKey(uid));
      return const {};
    }
  }

  Future<void> _cacheAndEmit(String uid, Map<String, Object?> data) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_cacheKey(uid), jsonEncode(data));
    _emit(uid, AppUserData.fromValue(data));
  }

  void _emit(String uid, AppUserData data) {
    final controller = _controllers[uid];
    if (controller != null && !controller.isClosed) {
      controller.add(data);
    }
  }

  Future<void> _queuePatch(String uid, Map<String, Object?> patch) {
    return _queue(uid, 'patch', patch);
  }

  Future<void> _queueSet(String uid, Map<String, Object?> data) {
    return _queue(uid, 'set', data);
  }

  Future<void> _queue(
    String uid,
    String type,
    Map<String, Object?> data,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final pending = preferences.getStringList(_pendingKey(uid)) ?? <String>[];
    pending.add(jsonEncode({'type': type, 'data': data}));
    await preferences.setStringList(_pendingKey(uid), pending);
  }

  Map<String, Object?> _defaultUserMap(AppSessionUser user) {
    final now = DateTime.now();
    final expiration = oneMonthFrom(now);
    return {
      'email': user.email,
      'username': user.displayName,
      'wallet': {'balance': 0.0},
      'userTypeLabel': AppUserData.defaultUserType,
      'profile': {'localImagePath': ''},
      'ticket': {
        'expiresAt': expiration.toIso8601String(),
        'expiresAtText': formatAlbanianDate(expiration),
      },
      'qrOverlay': {
        'localImagePath': '',
        'positionX': 0.0,
        'positionY': 0.0,
        'updatedAt': _timestamp,
      },
      'settings': {'language': 'sq', 'demoMode': true},
      'createdAt': _timestamp,
      'updatedAt': _timestamp,
    };
  }

  Map<String, Object?> _expandPathUpdates(Map<String, Object?> updates) {
    final root = <String, Object?>{};
    for (final entry in updates.entries) {
      _setPath(root, entry.key.split('/'), entry.value);
    }
    return root;
  }

  void _setPath(Map<String, Object?> root, List<String> parts, Object? value) {
    if (parts.length == 1) {
      root[parts.first] = value;
      return;
    }
    final key = parts.first;
    final child = root[key];
    final next = child is Map
        ? child.map((key, item) => MapEntry(key.toString(), item))
        : <String, Object?>{};
    root[key] = next;
    _setPath(next, parts.sublist(1), value);
  }

  Map<String, Object?> _deepCopy(Map<String, Object?> value) {
    return _map(jsonDecode(jsonEncode(value)));
  }

  void _mergeDeep(Map<String, Object?> target, Map<String, Object?> source) {
    for (final entry in source.entries) {
      final existing = target[entry.key];
      final incoming = entry.value;
      if (existing is Map && incoming is Map) {
        final existingMap = existing.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        target[entry.key] = existingMap;
        _mergeDeep(
          existingMap,
          incoming.map((key, value) => MapEntry(key.toString(), value)),
        );
      } else {
        target[entry.key] = incoming;
      }
    }
  }

  String get _timestamp => DateTime.now().toUtc().toIso8601String();
  String _cacheKey(String uid) => 'user_data_cache_$uid';
  String _pendingKey(String uid) => 'pending_user_writes_$uid';

  Map<String, Object?> _map(Object? value) {
    if (value is! Map) {
      return const {};
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}

class DatabaseRestException implements Exception {
  const DatabaseRestException(this.message);

  final String message;

  @override
  String toString() => message;
}
