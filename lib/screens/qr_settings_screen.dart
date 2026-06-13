import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/app_session_user.dart';
import '../models/app_user_data.dart';
import '../services/database_service.dart';
import '../utils/messages.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/brand_mark.dart';
import '../widgets/screen_shell.dart';
import 'qr_scanner_screen.dart';

class QrSettingsScreen extends StatefulWidget {
  const QrSettingsScreen({required this.user, super.key});

  final AppSessionUser user;

  @override
  State<QrSettingsScreen> createState() => _QrSettingsScreenState();
}

class _QrSettingsScreenState extends State<QrSettingsScreen> {
  final _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final fallback = AppUserData.demo(
      uid: widget.user.uid,
      email: widget.user.email,
      username: widget.user.displayName,
    );

    return StreamBuilder<AppUserData>(
      initialData: fallback,
      stream: _databaseService.watchUser(widget.user.uid),
      builder: (context, snapshot) {
        return QrSettingsContent(
          qrCodeId: (snapshot.data ?? fallback).qrCodeId,
          onSave: _saveQrCodeId,
          onScan: _openScanner,
        );
      },
    );
  }

  Future<void> _saveQrCodeId(String value) {
    return _databaseService.saveQrCodeId(widget.user.uid, value);
  }

  Future<void> _openScanner() async {
    final currentStatus = await Permission.camera.status;
    if (!mounted) {
      return;
    }

    if (currentStatus.isRestricted || currentStatus.isPermanentlyDenied) {
      await _showCameraSettingsDialog(restricted: currentStatus.isRestricted);
      return;
    }

    final status = currentStatus.isGranted
        ? currentStatus
        : await Permission.camera.request();
    if (!mounted) {
      return;
    }

    if (status.isGranted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QrScannerScreen(user: widget.user),
        ),
      );
      return;
    }

    if (status.isRestricted || status.isPermanentlyDenied) {
      await _showCameraSettingsDialog(restricted: status.isRestricted);
      return;
    }

    showAppMessage(
      context,
      'Qasja në kamerë nevojitet për të skanuar QR kodin.',
      isError: true,
    );
  }

  Future<void> _showCameraSettingsDialog({required bool restricted}) async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lejo përdorimin e kamerës'),
        content: Text(
          restricted
              ? 'Qasja në kamerë është e kufizuar në këtë pajisje. '
                    'Kontrollo cilësimet e pajisjes.'
              : 'Qasja në kamerë është çaktivizuar. Hape cilësimet e '
                    'aplikacionit për ta lejuar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anulo'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hap cilësimet'),
          ),
        ],
      ),
    );
    if (openSettings == true) {
      await openAppSettings();
    }
  }
}

class QrSettingsContent extends StatefulWidget {
  const QrSettingsContent({
    required this.qrCodeId,
    required this.onSave,
    required this.onScan,
    super.key,
  });

  final String qrCodeId;
  final Future<void> Function(String value) onSave;
  final Future<void> Function() onScan;

  @override
  State<QrSettingsContent> createState() => _QrSettingsContentState();
}

class _QrSettingsContentState extends State<QrSettingsContent> {
  late final TextEditingController _controller;
  late String _lastSavedValue;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.qrCodeId);
    _lastSavedValue = widget.qrCodeId;
  }

  @override
  void didUpdateWidget(covariant QrSettingsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.qrCodeId != oldWidget.qrCodeId) {
      _controller.text = widget.qrCodeId;
      _lastSavedValue = widget.qrCodeId;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppHeader(title: 'Cilësimet e QR Code-it', showBack: true),
              const SizedBox(height: 28),
              Focus(
                onFocusChange: (hasFocus) {
                  _isEditing = hasFocus;
                  if (!hasFocus) {
                    _saveManualValue();
                  }
                },
                child: AppTextField(
                  controller: _controller,
                  label: 'QR Code ID',
                  prefixIcon: Icons.qr_code_2_rounded,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveManualValue(),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Skano QR Code',
                icon: Icons.qr_code_scanner_rounded,
                isLoading: _isSaving,
                onPressed: _scan,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scan() async {
    await _saveManualValue();
    if (mounted) {
      await widget.onScan();
    }
  }

  Future<void> _saveManualValue() async {
    if (_isSaving) {
      return;
    }
    final value = _controller.text.trim();
    if (value.isEmpty || value == _lastSavedValue) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(value);
      _lastSavedValue = value;
      if (mounted) {
        showAppMessage(context, 'QR Code ID u ruajt.');
      }
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'QR Code ID nuk u ruajt.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
