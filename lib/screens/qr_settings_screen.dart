import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app.dart';
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

  final User user;

  @override
  State<QrSettingsScreen> createState() => _QrSettingsScreenState();
}

class _QrSettingsScreenState extends State<QrSettingsScreen> {
  final _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserData>(
      stream: _databaseService.watchUser(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Cilësimet nuk mund të ngarkohen.')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _QrSettingsForm(
          user: widget.user,
          data: snapshot.data!,
          databaseService: _databaseService,
        );
      },
    );
  }
}

class _QrSettingsForm extends StatefulWidget {
  const _QrSettingsForm({
    required this.user,
    required this.data,
    required this.databaseService,
  });

  final User user;
  final AppUserData data;
  final DatabaseService databaseService;

  @override
  State<_QrSettingsForm> createState() => _QrSettingsFormState();
}

class _QrSettingsFormState extends State<_QrSettingsForm> {
  late final TextEditingController _manualController;
  late String _activeSource;
  bool _manualEdited = false;
  bool _isSavingManual = false;
  bool _isSavingActive = false;

  @override
  void initState() {
    super.initState();
    _manualController = TextEditingController(text: widget.data.manualQrValue);
    _manualController.addListener(() => _manualEdited = true);
    _activeSource = widget.data.activeQrSource == 'scanned'
        ? 'scanned'
        : 'manual';
  }

  @override
  void didUpdateWidget(covariant _QrSettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_manualEdited &&
        oldWidget.data.manualQrValue != widget.data.manualQrValue) {
      _manualController.text = widget.data.manualQrValue;
    }
    if (oldWidget.data.activeQrSource != widget.data.activeQrSource) {
      _activeSource = widget.data.activeQrSource == 'scanned'
          ? 'scanned'
          : 'manual';
    }
  }

  @override
  void dispose() {
    _manualController.dispose();
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
              const AppHeader(
                title: 'Cilësimet e QR Kodit',
                subtitle: 'Zgjidh çfarë paraqet bileta demo',
                showBack: true,
              ),
              const SizedBox(height: 26),
              _SectionCard(
                title: 'Kodi manual',
                subtitle: 'Shkruaj ose ngjit tekstin që do të kodosh.',
                icon: Icons.edit_note_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _manualController,
                      label: 'Vlera e QR kodit',
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Ruaj',
                            isLoading: _isSavingManual,
                            onPressed: _saveManual,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            label: 'Fshij',
                            style: AppButtonStyle.secondary,
                            onPressed: widget.data.manualQrValue.isEmpty
                                ? null
                                : () => _clear('manual'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Kodi i skanuar',
                subtitle: widget.data.scannedQrValue.isEmpty
                    ? 'Nuk është skanuar ende asnjë kod.'
                    : widget.data.scannedQrValue,
                icon: Icons.qr_code_scanner_rounded,
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Skano QR Kod',
                        icon: Icons.center_focus_strong_rounded,
                        onPressed: _openScanner,
                      ),
                    ),
                    if (widget.data.scannedQrValue.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      AppButton(
                        label: 'Fshij',
                        expand: false,
                        style: AppButtonStyle.secondary,
                        onPressed: () => _clear('scanned'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Burimi aktiv',
                subtitle: 'Vetëm njëra vlerë shfaqet në biletën demo.',
                icon: Icons.tune_rounded,
                child: Column(
                  children: [
                    RadioGroup<String>(
                      groupValue: _activeSource,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _activeSource = value);
                        }
                      },
                      child: const Column(
                        children: [
                          RadioListTile<String>(
                            value: 'manual',
                            title: Text('Përdor kodin manual'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          RadioListTile<String>(
                            value: 'scanned',
                            title: Text('Përdor kodin e skanuar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Ruaj',
                      icon: Icons.check_rounded,
                      isLoading: _isSavingActive,
                      onPressed: _saveActive,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: 'Kthehu',
                style: AppButtonStyle.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveManual() async {
    final value = _manualController.text.trim();
    if (value.isEmpty) {
      showAppMessage(
        context,
        'Shkruaj një vlerë para se ta ruash.',
        isError: true,
      );
      return;
    }
    setState(() => _isSavingManual = true);
    try {
      await widget.databaseService.saveManualValue(widget.user.uid, value);
      _manualEdited = false;
      if (mounted) {
        showAppMessage(context, 'Kodi manual u ruajt.');
      }
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'Kodi nuk u ruajt.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingManual = false);
      }
    }
  }

  Future<void> _saveActive() async {
    final value = _activeSource == 'manual'
        ? _manualController.text.trim()
        : widget.data.scannedQrValue.trim();
    if (value.isEmpty) {
      showAppMessage(
        context,
        _activeSource == 'manual'
            ? 'Ruaj fillimisht kodin manual.'
            : 'Skano fillimisht një QR kod.',
        isError: true,
      );
      return;
    }

    setState(() => _isSavingActive = true);
    try {
      if (_activeSource == 'manual' && value != widget.data.manualQrValue) {
        await widget.databaseService.saveManualValue(widget.user.uid, value);
      }
      await widget.databaseService.setActiveQr(
        uid: widget.user.uid,
        source: _activeSource,
        value: value,
      );
      if (mounted) {
        showAppMessage(context, 'Burimi aktiv u përditësua.');
      }
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'Burimi aktiv nuk u ruajt.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingActive = false);
      }
    }
  }

  Future<void> _clear(String source) async {
    try {
      await widget.databaseService.clearQrValue(
        uid: widget.user.uid,
        source: source,
        isActive: widget.data.activeQrSource == source,
      );
      if (source == 'manual') {
        _manualController.clear();
        _manualEdited = false;
      }
      if (mounted) {
        showAppMessage(context, 'Vlera u fshi.');
      }
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'Vlera nuk u fshi.', isError: true);
      }
    }
  }

  Future<void> _openScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QrScannerScreen(user: widget.user),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.lavender,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
