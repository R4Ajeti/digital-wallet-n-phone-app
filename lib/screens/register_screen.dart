import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/messages.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/brand_mark.dart';
import '../widgets/screen_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _qrCodeController = TextEditingController();
  final _authService = AuthService();
  final _databaseService = DatabaseService();

  bool _isLoading = false;
  bool _isLoadingQrConfig = true;
  bool _requiresQrCodeId = false;
  String _defaultQrCodeId = '';

  @override
  void initState() {
    super.initState();
    _loadQrConfiguration();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _qrCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppHeader(
                title: 'Krijo llogari',
                subtitle: 'Hapi i parë për kuletën tënde demo',
                showBack: true,
              ),
              const SizedBox(height: 30),
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
                controller: _usernameController,
                label: 'Përdoruesi',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    validateRequired(value, 'Shkruaj emrin e përdoruesit.'),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _passwordController,
                label: 'Fjalëkalimi',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: validatePassword,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _confirmController,
                label: 'Konfirmo fjalëkalimin',
                prefixIcon: Icons.lock_reset_rounded,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  final baseValidation = validatePassword(value);
                  if (baseValidation != null) {
                    return baseValidation;
                  }
                  if (value != _passwordController.text) {
                    return 'Fjalëkalimet nuk përputhen.';
                  }
                  return null;
                },
                onSubmitted: (_) => _register(),
              ),
              if (_isLoadingQrConfig) ...[
                const SizedBox(height: 18),
                const Center(child: CircularProgressIndicator()),
              ] else if (_requiresQrCodeId) ...[
                const SizedBox(height: 14),
                AppTextField(
                  controller: _qrCodeController,
                  label: 'QR Code ID',
                  prefixIcon: Icons.qr_code_2_rounded,
                  textInputAction: TextInputAction.done,
                  validator: (value) =>
                      validateRequired(value, 'Shkruaj QR Code ID.'),
                  onSubmitted: (_) => _register(),
                ),
              ],
              const SizedBox(height: 22),
              AppButton(
                label: 'Krijo llogari',
                icon: Icons.person_add_alt_1_rounded,
                isLoading: _isLoading,
                onPressed: _isLoadingQrConfig ? null : _register,
              ),
              const SizedBox(height: 11),
              AppButton(
                label: 'Kthehu',
                style: AppButtonStyle.secondary,
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadQrConfiguration() async {
    try {
      final defaultQrCodeId = await _databaseService.fetchDefaultQrCodeId();
      if (mounted) {
        setState(() {
          _defaultQrCodeId = defaultQrCodeId;
          _requiresQrCodeId = defaultQrCodeId.isEmpty;
          _isLoadingQrConfig = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _requiresQrCodeId = true;
          _isLoadingQrConfig = false;
        });
      }
    }
  }

  Future<void> _register() async {
    if (_isLoading ||
        _isLoadingQrConfig ||
        !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await _authService.register(
        email: _emailController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );
      await _databaseService.createDefaultUser(
        user: user,
        username: _usernameController.text,
        qrCodeId: _defaultQrCodeId.isNotEmpty
            ? _defaultQrCodeId
            : _qrCodeController.text,
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (mounted) {
        showAppMessage(context, authErrorInAlbanian(error), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
