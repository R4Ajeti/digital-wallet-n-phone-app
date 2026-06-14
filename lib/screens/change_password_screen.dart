import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/messages.dart';
import '../utils/navigation.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/brand_mark.dart';
import '../widgets/screen_shell.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  bool _isSaving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppHeader(
                  title: 'Ndrysho fjalëkalimin',
                  subtitle: 'Konfirmo identitetin para ndryshimit',
                  showBack: true,
                ),
                const SizedBox(height: 30),
                AppTextField(
                  controller: _currentController,
                  label: 'Fjalëkalimi aktual',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      validateRequired(value, 'Shkruaj fjalëkalimin aktual.'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _newController,
                  label: 'Fjalëkalimi i ri',
                  prefixIcon: Icons.password_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: validatePassword,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _confirmController,
                  label: 'Konfirmo fjalëkalimin e ri',
                  prefixIcon: Icons.lock_reset_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return 'Konfirmo fjalëkalimin e ri.';
                    }
                    if (value != _newController.text) {
                      return 'Fjalëkalimet e reja nuk përputhen.';
                    }
                    return null;
                  },
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: 'Ruaj',
                  icon: Icons.check_rounded,
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Kthehu',
                  style: AppButtonStyle.secondary,
                  onPressed: () => maybePopRoute(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _authService.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (mounted) {
        showAppMessage(context, 'Fjalëkalimi u ndryshua me sukses.');
        _currentController.clear();
        _newController.clear();
        _confirmController.clear();
      }
    } catch (error) {
      if (mounted) {
        showAppMessage(context, authErrorInAlbanian(error), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
