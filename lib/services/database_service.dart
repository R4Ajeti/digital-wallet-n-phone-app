import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_session_user.dart';
import '../models/app_user_data.dart';
import '../utils/albanian_date.dart';
import 'auth_service.dart';

typedef DatabaseHttpClientFactory = http.Client Function();

class DatabaseService {
  DatabaseService({
    AuthService? authService,
    DatabaseHttpClientFactory? clientFactory,
  }) : _authService = authService ?? AuthService(),
       _clientFactory = clientFactory ?? http.Client.new;

  static const _databaseUrl =
      'https://kuleta-digitale-n-db-default-rtdb.europe-west1.firebasedatabase.app';
  static const sharedGuestPath = 'sharedGuest/default';
  static final _controllers = <String, StreamController<AppUserData>>{};
  static final _guestRefreshTimers = <String, Timer>{};

  final AuthService _authService;
  final DatabaseHttpClientFactory _clientFactory;

  Stream<AppUserData> watchUser(AppSessionUser user) {
    final dataKey = user.dataKey;
    final controller = _controllers.putIfAbsent(dataKey, () {
      late final StreamController<AppUserData> created;
      created = StreamController<AppUserData>.broadcast(
        onCancel: () {
          if (!created.hasListener) {
            _guestRefreshTimers.remove(dataKey)?.cancel();
          }
        },
      );
      return created;
    });
    unawaited(_primeUser(user));
    if (user.isAnonymous) {
      _guestRefreshTimers.putIfAbsent(
        dataKey,
        () => Timer.periodic(
          const Duration(seconds: 10),
          (_) => unawaited(_primeUser(user)),
        ),
      );
    }
    return controller.stream;
  }

  Future<AppUserData> cachedUser(AppSessionUser user) async {
    return AppUserData.fromValue(await _cachedMap(user.dataKey));
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
    if (user.isAnonymous) {
      throw const DatabaseRestException(
        'Anonymous users must use the shared guest workspace.',
      );
    }
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

    await _cacheAndEmit(user.dataKey, data);
    try {
      await _put('${_dataPath(user)}.json', data);
    } catch (_) {
      await _queueSet(user.dataKey, data);
    }
  }

  Future<void> ensureUserData(AppSessionUser user) async {
    if (user.isAnonymous) {
      await _ensureSharedGuestData(user);
      return;
    }

    final dataKey = user.dataKey;
    if (!await flushPendingWrites(user)) {
      return;
    }
    Map<String, Object?> data;
    try {
      data = _map(await _get('${_dataPath(user)}.json'));
    } catch (_) {
      final cached = await _cachedMap(dataKey);
      if (cached.isEmpty) {
        await _cacheAndEmit(dataKey, _defaultUserMap(user));
      }
      return;
    }

    if (data.isEmpty) {
      final cached = await _cachedMap(dataKey);
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
      await _cacheAndEmit(dataKey, data);
      await _update(user, updates);
      data = await _cachedMap(dataKey);
    } else {
      await _cacheAndEmit(dataKey, data);
    }
  }

  Future<void> _ensureSharedGuestData(AppSessionUser user) async {
    final dataKey = user.dataKey;
    if (!await flushPendingWrites(user)) {
      return;
    }

    Map<String, Object?> data;
    try {
      data = _map(await _get('${_dataPath(user)}.json'));
    } catch (_) {
      final cached = await _cachedMap(dataKey);
      if (cached.isEmpty) {
        await _cacheAndEmit(dataKey, _defaultUserMap(user, sharedGuest: true));
      }
      return;
    }

    if (data.isEmpty) {
      var qrCodeId = '';
      try {
        qrCodeId = await fetchDefaultQrCodeId();
      } catch (_) {
        qrCodeId = AppUserData.fromValue(await _cachedMap(dataKey)).qrCodeId;
      }
      final candidate = _defaultUserMap(
        user,
        sharedGuest: true,
        qrCodeId: qrCodeId,
      );

      try {
        final created = await _putIfAbsent(
          '${_dataPath(user)}.json',
          candidate,
        );
        data = created
            ? candidate
            : _map(await _get('${_dataPath(user)}.json'));
      } catch (_) {
        await _cacheAndEmit(dataKey, candidate);
        return;
      }
    }

    final now = DateTime.now();
    final expiration = oneMonthFrom(now);
    final ticket = _map(data['ticket']);
    final qr = _map(data['qr']);
    final overlay = _map(data['qrOverlay']);
    final settings = _map(data['settings']);
    final updates = <String, Object?>{};

    void addIfMissing(String path, Object? currentValue, Object defaultValue) {
      if (currentValue == null || currentValue.toString().trim().isEmpty) {
        updates[path] = defaultValue;
      }
    }

    addIfMissing('username', data['username'], 'Mysafir');
    addIfMissing(
      'userTypeLabel',
      data['userTypeLabel'],
      AppUserData.defaultUserType,
    );
    if (_map(data['wallet'])['balance'] == null) {
      updates['wallet/balance'] = 0.0;
    }
    if (ticket['expiresAt'] == null) {
      updates['ticket/expiresAt'] = expiration.toIso8601String();
    }
    if (ticket['expiresAtText'] == null) {
      updates['ticket/expiresAtText'] = formatAlbanianDate(expiration);
    }
    if (qr['value'] == null) {
      updates['qr/value'] = '';
    }
    addIfMissing('qr/updatedAt', qr['updatedAt'], _timestamp);
    addIfMissing('qrOverlay/type', overlay['type'], 'default');
    if (overlay['positionX'] == null) {
      updates['qrOverlay/positionX'] = 0.0;
    }
    if (overlay['positionY'] == null) {
      updates['qrOverlay/positionY'] = 0.0;
    }
    addIfMissing('qrOverlay/updatedAt', overlay['updatedAt'], _timestamp);
    if (settings['language'] == null) {
      updates['settings/language'] = 'sq';
    }
    if (settings['demoMode'] == null) {
      updates['settings/demoMode'] = true;
    }
    addIfMissing('createdAt', data['createdAt'], _timestamp);

    if (updates.isEmpty) {
      await _cacheAndEmit(dataKey, data);
    } else {
      await _cacheAndEmit(dataKey, data);
      await _update(user, updates);
    }
  }

  Future<bool> flushPendingWrites(AppSessionUser user) async {
    final dataKey = user.dataKey;
    final dataPath = _dataPath(user);
    final preferences = await SharedPreferences.getInstance();
    final pending = preferences.getStringList(_pendingKey(dataKey)) ?? const [];
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
          if (user.isAnonymous) {
            continue;
          }
          await _put('$dataPath.json', data);
        } else {
          await _patch('$dataPath.json', data);
        }
      } catch (_) {
        remaining.add(item);
      }
    }

    if (remaining.isEmpty) {
      await preferences.remove(_pendingKey(dataKey));
    } else {
      await preferences.setStringList(_pendingKey(dataKey), remaining);
    }
    return remaining.isEmpty;
  }

  Future<void> saveBalance(AppSessionUser user, double balance) {
    return _update(user, {'wallet/balance': balance.clamp(0.0, 999999.0)});
  }

  Future<void> saveTicketExpiration(AppSessionUser user, DateTime expiration) {
    final normalized = DateTime(
      expiration.year,
      expiration.month,
      expiration.day,
    );
    return _update(user, {
      'ticket/expiresAt': normalized.toIso8601String(),
      'ticket/expiresAtText': formatAlbanianDate(normalized),
    });
  }

  Future<void> saveQrCodeId(AppSessionUser user, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, 'value', 'QR code ID cannot be empty.');
    }
    return _update(user, {
      'qr/value': normalized,
      'qr/manualValue': null,
      'qr/scannedValue': null,
      'qr/activeSource': null,
      'qr/activeValue': null,
      'qr/updatedAt': _timestamp,
    });
  }

  Future<void> saveProfileImagePath(AppSessionUser user, String path) {
    if (user.isAnonymous) {
      return Future<void>.value();
    }
    return _update(user, {'profile/localImagePath': path});
  }

  Future<void> saveOverlayImagePath(AppSessionUser user, String path) {
    if (user.isAnonymous) {
      throw const DatabaseRestException(
        'Guest QR overlays use the shared bundled icon.',
      );
    }
    return _update(user, {
      'qrOverlay/localImagePath': path,
      'qrOverlay/updatedAt': _timestamp,
    });
  }

  Future<void> saveOverlayPosition(
    AppSessionUser user,
    double positionX,
    double positionY,
  ) {
    return _update(user, {
      'qrOverlay/positionX': positionX.clamp(0.0, 1.0),
      'qrOverlay/positionY': positionY.clamp(0.0, 1.0),
      'qrOverlay/updatedAt': _timestamp,
    });
  }

  Future<void> _primeUser(AppSessionUser user) async {
    final dataKey = user.dataKey;
    final cached = await _cachedMap(dataKey);
    if (cached.isNotEmpty) {
      _emit(dataKey, AppUserData.fromValue(cached));
    } else {
      _emit(
        dataKey,
        AppUserData.demo(
          uid: user.uid,
          email: user.email,
          username: user.displayName,
        ),
      );
    }

    if (!await flushPendingWrites(user)) {
      return;
    }
    try {
      final remote = _map(await _get('${_dataPath(user)}.json'));
      if (remote.isNotEmpty) {
        await _cacheAndEmit(dataKey, remote);
      }
    } catch (_) {
      // Cached data has already been emitted; the next write/read will retry.
    }
  }

  Future<void> _update(
    AppSessionUser user,
    Map<String, Object?> updates,
  ) async {
    final dataKey = user.dataKey;
    final patch = _expandPathUpdates({...updates, 'updatedAt': _timestamp});
    final current = await _cachedMap(dataKey);
    final next = _deepCopy(current);
    _mergeDeep(next, patch);
    await _cacheAndEmit(dataKey, next);

    try {
      if (!await flushPendingWrites(user)) {
        throw const DatabaseRestException('Pending writes are not synced.');
      }
      await _patch('${_dataPath(user)}.json', patch);
    } catch (_) {
      await _queuePatch(dataKey, patch);
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

  Future<bool> _putIfAbsent(String path, Map<String, Object?> data) async {
    final token = await _authService.requireValidIdToken();
    final separator = path.contains('?') ? '&' : '?';
    final uri = Uri.parse(
      '$_databaseUrl/$path$separator'
      'auth=${Uri.encodeQueryComponent(token)}',
    );
    final client = _clientFactory();
    try {
      final request = http.Request('PUT', uri)
        ..headers['Content-Type'] = 'application/json; charset=utf-8'
        ..headers['If-Match'] = 'null_etag'
        ..body = jsonEncode(data);
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 412) {
        await response.stream.drain<void>();
        return false;
      }
      final text = await response.stream.bytesToString();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final decoded = text.isEmpty ? null : jsonDecode(text);
        final message = decoded is Map ? decoded['error']?.toString() : null;
        throw DatabaseRestException(message ?? 'Database request failed.');
      }
      return true;
    } on TimeoutException {
      throw const DatabaseRestException('Database request timed out.');
    } on http.ClientException {
      throw const DatabaseRestException('Network unavailable.');
    } finally {
      client.close();
    }
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
    final client = _clientFactory();
    try {
      final request = http.Request(method, uri);
      if (data != null) {
        request.headers['Content-Type'] = 'application/json; charset=utf-8';
        request.body = jsonEncode(data);
      }
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 12));
      final text = await response.stream.bytesToString();
      final decoded = text.isEmpty ? null : jsonDecode(text);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map ? decoded['error']?.toString() : null;
        throw DatabaseRestException(message ?? 'Database request failed.');
      }
      return decoded;
    } on TimeoutException {
      throw const DatabaseRestException('Database request timed out.');
    } on http.ClientException {
      throw const DatabaseRestException('Network unavailable.');
    } finally {
      client.close();
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

  Map<String, Object?> _defaultUserMap(
    AppSessionUser user, {
    bool sharedGuest = false,
    String qrCodeId = '',
  }) {
    final now = DateTime.now();
    final expiration = oneMonthFrom(now);
    final data = <String, Object?>{
      'username': user.displayName,
      'wallet': {'balance': 0.0},
      'userTypeLabel': AppUserData.defaultUserType,
      'ticket': {
        'expiresAt': expiration.toIso8601String(),
        'expiresAtText': formatAlbanianDate(expiration),
      },
      'qr': {'value': qrCodeId.trim(), 'updatedAt': _timestamp},
      'qrOverlay': <String, Object?>{
        if (sharedGuest) 'type': 'default' else 'localImagePath': '',
        'positionX': 0.0,
        'positionY': 0.0,
        'updatedAt': _timestamp,
      },
      'settings': {'language': 'sq', 'demoMode': true},
      'createdAt': _timestamp,
      'updatedAt': _timestamp,
    };
    if (!sharedGuest) {
      data['email'] = user.email;
      data['profile'] = {'localImagePath': ''};
    }
    return data;
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
  static String dataPathForUser(AppSessionUser user) =>
      user.isAnonymous ? sharedGuestPath : 'users/${user.uid}';
  static String cacheKeyForUser(AppSessionUser user) =>
      'user_data_cache_${user.dataKey}';

  String _dataPath(AppSessionUser user) => dataPathForUser(user);
  String _cacheKey(String dataKey) => 'user_data_cache_$dataKey';
  String _pendingKey(String dataKey) => 'pending_user_writes_$dataKey';

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
