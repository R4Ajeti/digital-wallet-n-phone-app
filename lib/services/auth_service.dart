import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_session_user.dart';
import 'google_sign_in_service.dart';

typedef AuthHttpClientFactory = http.Client Function();

class AuthService {
  AuthService({
    AuthHttpClientFactory? clientFactory,
    Future<void> Function()? googleSignOut,
    DateTime Function()? now,
  }) : _clientFactory = clientFactory ?? http.Client.new,
       _googleSignOut = googleSignOut ?? GoogleSignInService.instance.signOut,
       _now = now ?? DateTime.now;

  static const _apiKey = 'AIzaSyDJe3177j-8bH9GJMFrnPyH-3YEAjDQ3Jg';
  static const _sessionKey = 'firebase_rest_auth_session';
  static final _controller = StreamController<AppSessionUser?>.broadcast();

  static _AuthSession? _session;
  static Future<void>? _loadFuture;

  final AuthHttpClientFactory _clientFactory;
  final Future<void> Function() _googleSignOut;
  final DateTime Function() _now;

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

    if (session.expiresAt.isAfter(_now().add(const Duration(minutes: 5)))) {
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
    final session = _sessionFromIdentityResponse(
      response,
      provider: AppAuthProvider.password,
    );
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
    var session = _sessionFromIdentityResponse(
      response,
      provider: AppAuthProvider.password,
    );

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
        provider: AppAuthProvider.password,
      );
    }

    await _saveSession(session);
    return session.user;
  }

  Future<AppSessionUser> loginAnonymously() async {
    final response = await _postJson(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey',
      {'returnSecureToken': true},
    );
    final session = _sessionFromIdentityResponse(
      response,
      provider: AppAuthProvider.anonymous,
      fallbackDisplayName: 'Mysafir',
    );
    await _saveSession(session);
    return session.user;
  }

  Future<AppSessionUser> loginWithGoogleIdToken(String googleIdToken) async {
    final normalized = googleIdToken.trim();
    if (normalized.isEmpty) {
      throw const RestAuthException(
        'google-invalid-credential',
        'Missing Google ID credential.',
      );
    }

    Map<String, dynamic> response;
    try {
      response = await _postJson(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=$_apiKey',
        {
          'requestUri': kIsWeb ? Uri.base.origin : 'http://localhost',
          'postBody': Uri(
            queryParameters: {
              'id_token': normalized,
              'providerId': 'google.com',
            },
          ).query,
          'returnSecureToken': true,
          'returnIdpCredential': true,
        },
      );
    } on RestAuthException catch (error) {
      final code = error.code.toUpperCase();
      if (code.contains('EMAIL_EXISTS') ||
          code.contains('FEDERATED_USER_ID_ALREADY_LINKED')) {
        throw const RestAuthException(
          'account-exists-with-different-credential',
        );
      }
      rethrow;
    }

    if (response['needConfirmation'] == true) {
      throw const RestAuthException('account-exists-with-different-credential');
    }

    final session = _sessionFromIdentityResponse(
      response,
      provider: AppAuthProvider.google,
    );
    await _saveSession(session);
    return session.user;
  }

  Future<void> logout() async {
    await _loadSession();
    final provider = _session?.user.provider;
    _session = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
    _controller.add(null);
    if (provider == AppAuthProvider.google) {
      try {
        await _googleSignOut();
      } catch (_) {
        // Firebase logout is complete even if the Google SDK cannot clear UI.
      }
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _loadSession();
    final session = _session;
    final email = session?.user.email;
    if (session == null ||
        !session.user.canChangePassword ||
        email == null ||
        email.isEmpty) {
      throw const RestAuthException('no-current-user', 'No current user.');
    }

    final signedIn = await _postJson(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_apiKey',
      {'email': email, 'password': currentPassword, 'returnSecureToken': true},
    );
    final freshSession = _sessionFromIdentityResponse(
      signedIn,
      provider: AppAuthProvider.password,
    );

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
        provider: AppAuthProvider.password,
      ),
    );
  }

  static Future<void> resetForTesting({bool clearStoredSession = true}) async {
    _session = null;
    _loadFuture = null;
    if (clearStoredSession) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_sessionKey);
    }
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
        provider: currentUser.provider,
      ),
      idToken: idToken,
      refreshToken: nextRefreshToken,
      expiresAt: _now().add(Duration(seconds: expiresIn)),
    );
  }

  Future<Map<String, dynamic>> _postJson(
    String url,
    Map<String, Object?> body,
  ) {
    return _send(
      url: url,
      body: jsonEncode(body),
      contentType: 'application/json; charset=utf-8',
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
      contentType: 'application/x-www-form-urlencoded; charset=utf-8',
    );
  }

  Future<Map<String, dynamic>> _send({
    required String url,
    required String body,
    required String contentType,
  }) async {
    final client = _clientFactory();
    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': contentType},
            body: body,
          )
          .timeout(const Duration(seconds: 20));
      final text = response.body;
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
    } on http.ClientException {
      throw const RestAuthException(
        'network-request-failed',
        'Network failed.',
      );
    } finally {
      client.close();
    }
  }

  _AuthSession _sessionFromIdentityResponse(
    Map<String, dynamic> data, {
    required AppAuthProvider provider,
    String? fallbackRefreshToken,
    String? fallbackDisplayName,
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
      fallback: fallbackDisplayName ?? _usernameFromEmail(email),
    );
    final expiresIn = int.tryParse(_text(data['expiresIn'])) ?? 3600;

    if (idToken.isEmpty || refreshToken.isEmpty || uid.isEmpty) {
      throw const RestAuthException(
        'invalid-auth-response',
        'Invalid auth response.',
      );
    }

    return _AuthSession(
      user: AppSessionUser(
        uid: uid,
        email: email,
        displayName: displayName,
        provider: provider,
      ),
      idToken: idToken,
      refreshToken: refreshToken,
      expiresAt: _now().add(Duration(seconds: expiresIn)),
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
        provider: _providerFromValue(json['provider']),
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
      'provider': user.provider.name,
      'idToken': idToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}

String authErrorInAlbanian(Object error) {
  if (error is RestGoogleSignInException) {
    return authErrorInAlbanian(RestAuthException(error.code));
  }
  if (error is RestAuthException) {
    final code = error.code.toUpperCase();
    if (code.contains('CONFIGURATION_NOT_FOUND')) {
      return 'Firebase Authentication nuk është aktivizuar ende. '
          'Hap Firebase Console, kliko Get started dhe aktivizo Email/Password.';
    }

    if (code.contains('ACCOUNT-EXISTS-WITH-DIFFERENT-CREDENTIAL') ||
        code.contains('ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL')) {
      return 'Kjo adresë përdor një mënyrë tjetër kyçjeje. '
          'Përdor metodën origjinale.';
    }
    if (code.contains('GOOGLE-CANCELED')) {
      return 'Kyçja me Google u anulua.';
    }
    if (code.contains('GOOGLE-POPUP-CLOSED')) {
      return 'Dritarja e Google u mbyll para përfundimit.';
    }
    if (code.contains('GOOGLE-UI-UNAVAILABLE')) {
      return 'Dritarja e Google nuk mund të hapej. '
          'Lejo dritaret kërcyese dhe provo përsëri.';
    }
    if (code.contains('GOOGLE-CONFIGURATION-FAILED')) {
      return 'Kyçja me Google nuk është konfiguruar si duhet.';
    }
    if (code.contains('GOOGLE-INVALID-CREDENTIAL')) {
      return 'Google nuk ktheu një kredencial të vlefshëm.';
    }
    if (code.contains('GOOGLE-PROVIDER-FAILED')) {
      return 'Kyçja me Google dështoi. Provo përsëri.';
    }
    if (code.contains('OPERATION_NOT_ALLOWED') ||
        code.contains('ADMIN_ONLY_OPERATION')) {
      return 'Kjo mënyrë kyçjeje nuk është aktivizuar në Firebase.';
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

AppAuthProvider _providerFromValue(Object? value) {
  final name = _text(value);
  return AppAuthProvider.values.firstWhere(
    (provider) => provider.name == name,
    orElse: () => AppAuthProvider.password,
  );
}
