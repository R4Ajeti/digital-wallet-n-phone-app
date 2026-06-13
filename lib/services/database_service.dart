import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/app_user_data.dart';
import '../utils/albanian_date.dart';

class DatabaseService {
  DatabaseService({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  DatabaseReference _userRef(String uid) => _database.ref('users/$uid');

  Stream<AppUserData> watchUser(String uid) {
    return _userRef(
      uid,
    ).onValue.map((event) => AppUserData.fromValue(event.snapshot.value));
  }

  Future<void> createDefaultUser({
    required User user,
    required String username,
  }) async {
    final now = DateTime.now();
    final expiration = oneMonthFrom(now);
    final timestamp = now.toUtc().toIso8601String();

    await _userRef(user.uid).set({
      'email': user.email ?? '',
      'username': username.trim(),
      'userTypeLabel': AppUserData.defaultUserType,
      'profile': {'localImagePath': ''},
      'ticket': {
        'expiresAt': expiration.toIso8601String(),
        'expiresAtText': formatAlbanianDate(expiration),
      },
      'qr': {
        'manualValue': '',
        'scannedValue': '',
        'activeSource': 'manual',
        'activeValue': '',
        'updatedAt': timestamp,
      },
      'qrOverlay': {
        'localImagePath': '',
        'positionX': 0.5,
        'positionY': 0.5,
        'updatedAt': timestamp,
      },
      'settings': {'language': 'sq', 'demoMode': true},
      'createdAt': timestamp,
      'updatedAt': timestamp,
    });
  }

  Future<void> ensureUserData(User user) async {
    final reference = _userRef(user.uid);
    final snapshot = await reference.get();
    if (!snapshot.exists) {
      await createDefaultUser(
        user: user,
        username: user.displayName ?? _usernameFromEmail(user.email),
      );
      return;
    }

    final data = _map(snapshot.value);
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

    addIfMissing('email', data['email'], user.email ?? '');
    addIfMissing(
      'username',
      data['username'],
      user.displayName ?? _usernameFromEmail(user.email),
    );
    addIfMissing(
      'userTypeLabel',
      data['userTypeLabel'],
      AppUserData.defaultUserType,
    );
    addIfMissing(
      'profile/localImagePath',
      _map(data['profile'])['localImagePath'],
      '',
    );
    addIfMissing('qr/manualValue', _map(data['qr'])['manualValue'], '');
    addIfMissing('qr/scannedValue', _map(data['qr'])['scannedValue'], '');
    addIfMissing('qr/activeSource', _map(data['qr'])['activeSource'], 'manual');
    addIfMissing('qr/activeValue', _map(data['qr'])['activeValue'], '');
    addIfMissing(
      'qrOverlay/localImagePath',
      _map(data['qrOverlay'])['localImagePath'],
      '',
    );
    if (_map(data['qrOverlay'])['positionX'] == null) {
      updates['qrOverlay/positionX'] = 0.5;
    }
    if (_map(data['qrOverlay'])['positionY'] == null) {
      updates['qrOverlay/positionY'] = 0.5;
    }
    if (ticket['expiresAtText'] != expirationText) {
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
      await reference.update(updates);
    }
  }

  Future<void> saveManualValue(String uid, String value) {
    return _update(uid, {
      'qr/manualValue': value.trim(),
      'qr/updatedAt': _timestamp,
    });
  }

  Future<void> saveScannedValue(String uid, String value) {
    return _update(uid, {
      'qr/scannedValue': value.trim(),
      'qr/updatedAt': _timestamp,
    });
  }

  Future<void> setActiveQr({
    required String uid,
    required String source,
    required String value,
  }) {
    return _update(uid, {
      'qr/activeSource': source,
      'qr/activeValue': value.trim(),
      'qr/updatedAt': _timestamp,
    });
  }

  Future<void> clearQrValue({
    required String uid,
    required String source,
    required bool isActive,
  }) {
    return _update(uid, {
      'qr/${source == 'manual' ? 'manualValue' : 'scannedValue'}': '',
      if (isActive) 'qr/activeValue': '',
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

  Future<void> _update(String uid, Map<String, Object?> updates) {
    return _userRef(uid).update({...updates, 'updatedAt': _timestamp});
  }

  String get _timestamp => DateTime.now().toUtc().toIso8601String();

  String _usernameFromEmail(String? email) {
    final value = email?.split('@').first.trim() ?? '';
    return value.isEmpty ? 'Përdorues demo' : value;
  }

  Map<String, Object?> _map(Object? value) {
    if (value is! Map) {
      return const {};
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}
