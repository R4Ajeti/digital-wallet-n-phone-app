import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/google_sign_in_service.dart';
import '../utils/messages.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/brand_mark.dart';
import '../widgets/google_sign_in_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    this.authService,
    this.databaseService,
    this.googleSignInService,
    super.key,
  });

  final AuthService? authService;
  final DatabaseService? databaseService;
  final GoogleSignInService? googleSignInService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthService _authService;
  late final DatabaseService _databaseService;
  late final GoogleSignInService _googleSignInService;
  StreamSubscription<GoogleIdCredential>? _googleSubscription;

  String? _activeMethod;
  bool _googleReady = false;
  Object? _googleInitializationError;

  bool get _isBusy => _activeMethod != null;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _databaseService =
        widget.databaseService ?? DatabaseService(authService: _authService);
    _googleSignInService =
        widget.googleSignInService ?? GoogleSignInService.instance;
    unawaited(_initializeGoogle());
  }

  @override
  void dispose() {
    _googleSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BrandMark(size: 62),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Kuleta\nDigitale',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bileta juaj demo, e qartë dhe gjithmonë pranë.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.outline),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.07),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Mirë se erdhe',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          const Text('Kyçu për ta hapur kuletën tënde demo.'),
                          const SizedBox(height: 22),
                          AppTextField(
                            controller: _emailController,
                            label: 'Email',
                            prefixIcon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: validateEmail,
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _passwordController,
                            label: 'Fjalëkalimi',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: validatePassword,
                            onSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: 20),
                          AppButton(
                            key: const Key('email-login-button'),
                            label: 'Kyçu',
                            icon: Icons.login_rounded,
                            isLoading: _activeMethod == 'email',
                            onPressed: _isBusy ? null : _login,
                          ),
                          const SizedBox(height: 11),
                          AppButton(
                            label: 'Krijo llogari',
                            style: AppButtonStyle.secondary,
                            onPressed: _openRegister,
                          ),
                          const SizedBox(height: 18),
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('ose'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (kIsWeb && _googleReady)
                            IgnorePointer(
                              ignoring: _isBusy,
                              child: AnimatedOpacity(
                                opacity: _isBusy ? 0.55 : 1,
                                duration: const Duration(milliseconds: 150),
                                child: const GoogleSignInWebButton(
                                  key: Key('google-login-button'),
                                ),
                              ),
                            )
                          else
                            AppButton(
                              key: const Key('google-login-button'),
                              label: 'Vazhdo me Google',
                              icon: Icons.account_circle_outlined,
                              style: AppButtonStyle.secondary,
                              isLoading: _activeMethod == 'google',
                              tooltip: 'Kyçu duke përdorur llogarinë Google',
                              onPressed: _isBusy ? null : _loginWithGoogle,
                            ),
                          const SizedBox(height: 11),
                          AppButton(
                            key: const Key('guest-login-button'),
                            label: 'Vazhdo si mysafir',
                            icon: Icons.person_outline_rounded,
                            style: AppButtonStyle.secondary,
                            isLoading: _activeMethod == 'guest',
                            tooltip: 'Hap hapësirën e përbashkët të mysafirit',
                            onPressed: _isBusy ? null : _loginAsGuest,
                          ),
                          const SizedBox(height: 13),
                          const Text(
                            'Si mysafir, kuleta dhe QR kodi ndahen me të gjithë. '
                            'Vetëm fotografia e profilit mbetet në këtë pajisje '
                            'ose shfletues.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _DemoNotice(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _initializeGoogle() async {
    try {
      await _googleSignInService.initialize();
      if (kIsWeb) {
        _googleSubscription = _googleSignInService.webCredentials.listen(
          _handleWebGoogleCredential,
          onError: _handleGoogleStreamError,
        );
      }
      if (mounted) {
        setState(() => _googleReady = true);
      }
    } catch (error) {
      _googleInitializationError = error;
      if (mounted) {
        setState(() => _googleReady = false);
      }
    }
  }

  Future<void> _login() async {
    if (!_begin('email') || !_formKey.currentState!.validate()) {
      if (_activeMethod == 'email') {
        _finish();
      }
      return;
    }
    try {
      await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (error) {
      if (mounted) {
        showAppMessage(context, authErrorInAlbanian(error), isError: true);
      }
    } finally {
      _finish();
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_googleInitializationError != null) {
      showAppMessage(
        context,
        authErrorInAlbanian(
          const RestAuthException('google-configuration-failed'),
        ),
        isError: true,
      );
      return;
    }
    if (!_googleReady) {
      showAppMessage(
        context,
        'Google po përgatitet. Provo përsëri pas pak.',
        isError: true,
      );
      return;
    }
    if (!_begin('google')) {
      return;
    }
    try {
      await _exchangeGoogleCredential(
        await _googleSignInService.authenticate(),
      );
    } catch (error) {
      _showAuthError(error);
      _finish();
    }
  }

  Future<void> _handleWebGoogleCredential(GoogleIdCredential credential) async {
    if (!_begin('google')) {
      return;
    }
    await _exchangeGoogleCredential(credential);
  }

  Future<void> _exchangeGoogleCredential(GoogleIdCredential credential) async {
    try {
      final user = await _authService.loginWithGoogleIdToken(
        credential.idToken,
      );
      await _databaseService.ensureUserData(user);
    } catch (error) {
      _showAuthError(error);
    } finally {
      _finish();
    }
  }

  void _handleGoogleStreamError(Object error) {
    _showAuthError(error);
    _finish();
  }

  Future<void> _loginAsGuest() async {
    if (!_begin('guest')) {
      return;
    }
    try {
      final user = await _authService.loginAnonymously();
      await _databaseService.ensureUserData(user);
    } catch (error) {
      _showAuthError(error);
    } finally {
      _finish();
    }
  }

  bool _begin(String method) {
    if (_activeMethod != null) {
      return false;
    }
    if (_activeMethod == null && mounted) {
      setState(() => _activeMethod = method);
    }
    return true;
  }

  void _finish() {
    if (mounted) {
      setState(() => _activeMethod = null);
    }
  }

  void _showAuthError(Object error) {
    if (mounted) {
      showAppMessage(context, authErrorInAlbanian(error), isError: true);
    }
  }

  void _openRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen()));
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.science_outlined, color: AppColors.danger),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ky është vetëm një prototip demonstrues, jo shërbim zyrtar.',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
