import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleIdCredential {
  const GoogleIdCredential({required this.idToken});

  final String idToken;
}

class GoogleSignInService {
  GoogleSignInService._();

  static final GoogleSignInService instance = GoogleSignInService._();

  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  final _webCredentials = StreamController<GoogleIdCredential>.broadcast();
  Future<void>? _initialization;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _webSubscription;

  Stream<GoogleIdCredential> get webCredentials => _webCredentials.stream;

  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    final signIn = GoogleSignIn.instance;
    await signIn.initialize(
      clientId: kIsWeb && _webClientId.isNotEmpty ? _webClientId : null,
      serverClientId: !kIsWeb && _serverClientId.isNotEmpty
          ? _serverClientId
          : null,
    );

    if (kIsWeb) {
      _webSubscription = signIn.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          try {
            _webCredentials.add(_credentialFromAccount(event.user));
          } catch (error, stackTrace) {
            _webCredentials.addError(error, stackTrace);
          }
        }
      }, onError: _webCredentials.addError);
    }
  }

  Future<GoogleIdCredential> authenticate() async {
    await initialize();
    final signIn = GoogleSignIn.instance;
    if (!signIn.supportsAuthenticate()) {
      throw const RestGoogleSignInException('google-ui-unavailable');
    }

    try {
      return _credentialFromAccount(await signIn.authenticate());
    } on GoogleSignInException catch (error) {
      throw RestGoogleSignInException(_mapExceptionCode(error.code));
    }
  }

  Future<void> signOut() async {
    await initialize();
    await GoogleSignIn.instance.signOut();
  }

  Future<void> dispose() async {
    await _webSubscription?.cancel();
    await _webCredentials.close();
  }

  GoogleIdCredential _credentialFromAccount(GoogleSignInAccount account) {
    final idToken = account.authentication.idToken?.trim() ?? '';
    if (idToken.isEmpty) {
      throw const RestGoogleSignInException('google-invalid-credential');
    }
    return GoogleIdCredential(idToken: idToken);
  }

  String _mapExceptionCode(GoogleSignInExceptionCode code) {
    return switch (code) {
      GoogleSignInExceptionCode.canceled => 'google-canceled',
      GoogleSignInExceptionCode.interrupted => 'google-popup-closed',
      GoogleSignInExceptionCode.uiUnavailable => 'google-ui-unavailable',
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        'google-configuration-failed',
      _ => 'google-provider-failed',
    };
  }
}

class RestGoogleSignInException implements Exception {
  const RestGoogleSignInException(this.code);

  final String code;
}
