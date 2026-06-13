class AppUserData {
  const AppUserData({
    required this.email,
    required this.username,
    required this.userTypeLabel,
    required this.profileImagePath,
    required this.expiresAt,
    required this.expiresAtText,
    required this.manualQrValue,
    required this.scannedQrValue,
    required this.activeQrSource,
    required this.activeQrValue,
    required this.overlayImagePath,
    required this.overlayPositionX,
    required this.overlayPositionY,
  });

  static const defaultUserType =
      'Student/e në Universitet me bazë në Prishtinë';

  final String email;
  final String username;
  final String userTypeLabel;
  final String profileImagePath;
  final String expiresAt;
  final String expiresAtText;
  final String manualQrValue;
  final String scannedQrValue;
  final String activeQrSource;
  final String activeQrValue;
  final String overlayImagePath;
  final double overlayPositionX;
  final double overlayPositionY;

  factory AppUserData.fromValue(Object? value) {
    final root = _stringMap(value);
    final profile = _stringMap(root['profile']);
    final ticket = _stringMap(root['ticket']);
    final qr = _stringMap(root['qr']);
    final overlay = _stringMap(root['qrOverlay']);

    return AppUserData(
      email: _text(root['email']),
      username: _text(root['username']),
      userTypeLabel: _text(root['userTypeLabel'], fallback: defaultUserType),
      profileImagePath: _text(profile['localImagePath']),
      expiresAt: _text(ticket['expiresAt']),
      expiresAtText: _text(ticket['expiresAtText']),
      manualQrValue: _text(qr['manualValue']),
      scannedQrValue: _text(qr['scannedValue']),
      activeQrSource: _text(qr['activeSource'], fallback: 'manual'),
      activeQrValue: _text(qr['activeValue']),
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
}
