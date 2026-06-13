import '../utils/albanian_date.dart';

class AppUserData {
  const AppUserData({
    required this.email,
    required this.username,
    required this.balance,
    required this.userTypeLabel,
    required this.profileImagePath,
    required this.expiresAt,
    required this.expiresAtText,
    required this.qrCodeId,
    required this.overlayImagePath,
    required this.overlayPositionX,
    required this.overlayPositionY,
  });

  static const defaultUserType =
      'Student/e në Universitet me bazë në Prishtinë';

  final String email;
  final String username;
  final double balance;
  final String userTypeLabel;
  final String profileImagePath;
  final String expiresAt;
  final String expiresAtText;
  final String qrCodeId;
  final String overlayImagePath;
  final double overlayPositionX;
  final double overlayPositionY;

  factory AppUserData.demo({
    required String uid,
    String? email,
    String? username,
  }) {
    final expiration = oneMonthFrom(DateTime.now());

    return AppUserData(
      email: _text(email),
      username: _text(username, fallback: _usernameFromEmail(email)),
      balance: 0.0,
      userTypeLabel: defaultUserType,
      profileImagePath: '',
      expiresAt: expiration.toIso8601String(),
      expiresAtText: formatAlbanianDate(expiration),
      qrCodeId: '',
      overlayImagePath: '',
      overlayPositionX: 0.0,
      overlayPositionY: 0.0,
    );
  }

  factory AppUserData.fromValue(Object? value) {
    final root = _stringMap(value);
    final profile = _stringMap(root['profile']);
    final wallet = _stringMap(root['wallet']);
    final ticket = _stringMap(root['ticket']);
    final qr = _stringMap(root['qr']);
    final overlay = _stringMap(root['qrOverlay']);
    final qrCodeId = _firstRealQrValue([
      qr['value'],
      qr['activeValue'],
      qr['scannedValue'],
      qr['manualValue'],
    ]);

    return AppUserData(
      email: _text(root['email']),
      username: _text(root['username']),
      balance: _number(wallet['balance'] ?? root['balance'], fallback: 0.0),
      userTypeLabel: _text(root['userTypeLabel'], fallback: defaultUserType),
      profileImagePath: _text(profile['localImagePath']),
      expiresAt: _text(ticket['expiresAt']),
      expiresAtText: _text(ticket['expiresAtText']),
      qrCodeId: qrCodeId,
      overlayImagePath: _text(overlay['localImagePath']),
      overlayPositionX: _number(overlay['positionX'], fallback: 0.0),
      overlayPositionY: _number(overlay['positionY'], fallback: 0.0),
    );
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is! Map) {
      return const {};
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static double _number(Object? value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String _firstRealQrValue(Iterable<Object?> values) {
    for (final value in values) {
      final text = _text(value);
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static String _usernameFromEmail(String? email) {
    final value = email?.split('@').first.trim() ?? '';
    return value.isEmpty ? 'Përdorues demo' : value;
  }
}
