import 'package:flutter/material.dart';

import '../models/app_session_user.dart';
import '../models/app_user_data.dart';
import '../services/database_service.dart';
import '../utils/messages.dart';
import '../utils/navigation.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/brand_mark.dart';
import '../widgets/screen_shell.dart';

class BalanceSettingsScreen extends StatefulWidget {
  const BalanceSettingsScreen({required this.user, super.key});

  final AppSessionUser user;

  @override
  State<BalanceSettingsScreen> createState() => _BalanceSettingsScreenState();
}

class _BalanceSettingsScreenState extends State<BalanceSettingsScreen> {
  final _databaseService = DatabaseService();
  final _controller = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserData>(
      initialData: AppUserData.demo(
        uid: widget.user.uid,
        email: widget.user.email,
        username: widget.user.displayName,
      ),
      stream: _databaseService.watchUser(widget.user),
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            AppUserData.demo(
              uid: widget.user.uid,
              email: widget.user.email,
              username: widget.user.displayName,
            );
        if (!_initialized) {
          _controller.text = data.balance.toStringAsFixed(2);
          _initialized = true;
        }

        return ScreenShell(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppHeader(
                    title: 'Ndrysho bilancin',
                    subtitle: 'Vendos shumën aktuale të kuletës',
                    showBack: true,
                  ),
                  const SizedBox(height: 30),
                  AppTextField(
                    controller: _controller,
                    label: 'Bilanci',
                    prefixIcon: Icons.euro_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    label: 'Ruaj bilancin',
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
        );
      },
    );
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    final normalized = _controller.text.trim().replaceAll(',', '.');
    final balance = double.tryParse(normalized);
    if (balance == null || balance < 0) {
      showAppMessage(context, 'Shkruaj një shumë të vlefshme.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _databaseService.saveBalance(widget.user, balance);
      if (mounted) {
        showAppMessage(context, 'Bilanci u përditësua.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
