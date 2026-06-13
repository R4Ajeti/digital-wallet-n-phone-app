import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_session_user.dart';

class AuthService {
  static const _apiKey = 'AIzaSyDJe3177j-8bH9GJMFrnPyH-3YEAjDQ3Jg';
  static const _sessionKey = 'firebase_rest_auth_session';
  static final _controller = StreamController<AppSessionUser?>.broadcast();

  static _AuthSession? _session;
  static Future<void>? _loadFuture;

  Stream<AppSessionUser?> authStateChanges() async* {
    yield await currentUser();
    yield* _controller.stream;
  }

  Future<AppSessionUser?> currentUser() async {
    await _loadSession();
    return _session?.user;
  }

  Future<String> requireValidIdToken() async {
    await _loadSession();
    final session = _session;
    if (session == null) {
      throw const RestAuthException('no-current-user', 'No current user.');
    }

    if (session.expiresAt.isAfter(
      DateTime.now().add(const Duration(minutes: 5)),
    )) {
      return session.idToken;
    }

    final refreshed = await _refreshSession(session.refreshToken);
    await _saveSession(refreshed);
    return refreshed.idToken;
  }

  Future<AppSessionUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _postJson(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_apiKey',
      {'email': email.trim(), 'password': password, 'returnSecureToken': true},
    );
    final session = _sessionFromIdentityResponse(response);
    await _saveSession(session);
    return session.user;
  }

  Future<AppSessionUser> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final response = await _postJson(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey',
      {'email': email.trim(), 'password': password, 'returnSecureToken': true},
    );
    var session = _sessionFromIdentityResponse(response);

    final trimmedUsername = username.trim();
    if (trimmedUsername.isNotEmpty) {
      final update = await _postJson(
        'https://identitytoolkit.googleapis.com/v1/accounts:update?key=$_apiKey',
        {
          'idToken': session.idToken,
          'displayName': trimmedUsername,
          'returnSecureToken': true,
        },
      );
      session = _sessionFromIdentityResponse(
        update,
        fallbackRefreshToken: session.refreshToken,
      );
    }

    await _saveSession(session);
    return session.user;
  }

  Future<void> logout() async {
    await _loadSession();
    _session = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
    _controller.add(null);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _loadSession();
    final session = _session;
    final email = session?.user.email;
    if (session == null || email == null || email.isEmpty) {
      throw const RestAuthException('no-current-user', 'No current user.');
    }

    final signedIn = await _postJson(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_apiKey',
      {'email': email, 'password': currentPassword, 'returnSecureToken': true},
    );
    final freshSession = _sessionFromIdentityResponse(signedIn);

    final updated = await _postJson(
      'https://identitytoolkit.googleapis.com/v1/accounts:update?key=$_apiKey',
      {
        'idToken': freshSession.idToken,
        'password': newPassword,
        'returnSecureToken': true,
      },
    );
    await _saveSession(
      _sessionFromIdentityResponse(
        updated,
        fallbackRefreshToken: freshSession.refreshToken,
      ),
    );
  }

  static Future<void> _loadSession() {
    return _loadFuture ??= _loadSessionFromDisk();
  }

  static Future<void> _loadSessionFromDisk() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _session = _AuthSession.fromJson(data);
    } catch (_) {
      await preferences.remove(_sessionKey);
    }
  }

  static Future<void> _saveSession(_AuthSession session) async {
    _session = session;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, jsonEncode(session.toJson()));
    _controller.add(session.user);
  }

  Future<_AuthSession> _refreshSession(String refreshToken) async {
    final response = await _postForm(
      'https://securetoken.googleapis.com/v1/token?key=$_apiKey',
      {'grant_type': 'refresh_token', 'refresh_token': refreshToken},
    );

    final idToken = _text(response['id_token']);
    final userId = _text(response['user_id']);
    final nextRefreshToken = _text(
      response['refresh_token'],
      fallback: refreshToken,
    );
    final expiresIn = int.tryParse(_text(response['expires_in'])) ?? 3600;
    final currentUser = _session?.user;

    if (idToken.isEmpty || userId.isEmpty || currentUser == null) {
      throw const RestAuthException(
        'token-refresh-failed',
        'Token refresh failed.',
      );
    }

    return _AuthSession(
      user: AppSessionUser(
        uid: userId,
        email: currentUser.email,
        displayName: currentUser.displayName,
      ),
      idToken: idToken,
      refreshToken: nextRefreshToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  Future<Map<String, dynamic>> _postJson(
    String url,
    Map<String, Object?> body,
  ) {
    return _send(
      url: url,
      body: jsonEncode(body),
      contentType: ContentType.json,
    );
  }

  Future<Map<String, dynamic>> _postForm(String url, Map<String, String> body) {
    return _send(
      url: url,
      body: body.entries
          .map(
            (entry) =>
                '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
          )
          .join('&'),
      contentType: ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      ),
    );
  }

  Future<Map<String, dynamic>> _send({
    required String url,
    required String body,
    required ContentType contentType,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client
          .postUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      request.headers.contentType = contentType;
      request.write(body);
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final text = await response.transform(utf8.decoder).join();
      final decoded = text.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = decoded['error'];
        final message = error is Map ? _text(error['message']) : '';
        throw RestAuthException(
          message.isEmpty ? 'request-failed' : message,
          message,
        );
      }
      return decoded;
    } on RestAuthException {
      rethrow;
    } on TimeoutException {
      throw const RestAuthException(
        'network-request-failed',
        'Request timed out.',
      );
    } on SocketException {
      throw const RestAuthException(
        'network-request-failed',
        'Network failed.',
      );
    } finally {
      client.close(force: true);
    }
  }

  _AuthSession _sessionFromIdentityResponse(
    Map<String, dynamic> data, {
    String? fallbackRefreshToken,
  }) {
    final idToken = _text(data['idToken']);
    final refreshToken = _text(
      data['refreshToken'],
      fallback: fallbackRefreshToken ?? '',
    );
    final uid = _text(data['localId']);
    final email = _text(data['email']);
    final displayName = _text(
      data['displayName'],
      fallback: _usernameFromEmail(email),
    );
    final expiresIn = int.tryParse(_text(data['expiresIn'])) ?? 3600;

    if (idToken.isEmpty || refreshToken.isEmpty || uid.isEmpty) {
      throw const RestAuthException(
        'invalid-auth-response',
        'Invalid auth response.',
      );
    }

    return _AuthSession(
      user: AppSessionUser(uid: uid, email: email, displayName: displayName),
      idToken: idToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }
}

class RestAuthException implements Exception {
  const RestAuthException(this.code, [this.message = '']);

  final String code;
  final String message;

  @override
  String toString() => 'RestAuthException($code): $message';
}

class _AuthSession {
  const _AuthSession({
    required this.user,
    required this.idToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final AppSessionUser user;
  final String idToken;
  final String refreshToken;
  final DateTime expiresAt;

  factory _AuthSession.fromJson(Map<String, dynamic> json) {
    return _AuthSession(
      user: AppSessionUser(
        uid: _text(json['uid']),
        email: _text(json['email']),
        displayName: _text(json['displayName']),
      ),
      idToken: _text(json['idToken']),
      refreshToken: _text(json['refreshToken']),
      expiresAt:
          DateTime.tryParse(_text(json['expiresAt'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'idToken': idToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}

String authErrorInAlbanian(Object error) {
  if (error is RestAuthException) {
    final code = error.code.toUpperCase();
    if (code.contains('CONFIGURATION_NOT_FOUND')) {
      return 'Firebase Authentication nuk është aktivizuar ende. '
          'Hap Firebase Console, kliko Get started dhe aktivizo Email/Password.';
    }

    if (code.contains('INVALID_EMAIL')) {
      return 'Email-i nuk është i vlefshëm.';
    }
    if (code.contains('USER_DISABLED')) {
      return 'Kjo llogari është çaktivizuar.';
    }
    if (code.contains('EMAIL_NOT_FOUND') ||
        code.contains('INVALID_PASSWORD') ||
        code.contains('INVALID_LOGIN_CREDENTIALS') ||
        code.contains('INVALID_CREDENTIAL')) {
      return 'Email-i ose fjalëkalimi është i pasaktë.';
    }
    if (code.contains('EMAIL_EXISTS')) {
      return 'Ky email është përdorur nga një llogari tjetër.';
    }
    if (code.contains('WEAK_PASSWORD')) {
      return 'Zgjidh një fjalëkalim më të fortë.';
    }
    if (code.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
      return 'Ka pasur shumë tentativa. Provo përsëri më vonë.';
    }
    switch (error.code) {
      case 'network-request-failed':
        return 'Kontrollo lidhjen me internetin.';
      case 'no-current-user':
        return 'Sesioni ka përfunduar. Kyçu përsëri.';
    }
  }
  return 'Diçka nuk shkoi mirë. Provo përsëri.';
}

String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _usernameFromEmail(String? email) {
  final value = email?.split('@').first.trim() ?? '';
  return value.isEmpty ? 'Përdorues demo' : value;
}
