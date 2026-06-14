import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app.dart';
import '../models/app_session_user.dart';
import '../services/database_service.dart';
import '../utils/messages.dart';
import '../widgets/app_button.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({required this.user, super.key});

  final AppSessionUser user;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _databaseService = DatabaseService();
  final _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
    returnImage: false,
    autoZoom: false,
  );

  PermissionStatus? _permissionStatus;
  String _decodedValue = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _permissionStatus = PermissionStatus.granted;
    } else {
      _requestPermission();
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) {
      setState(() => _permissionStatus = PermissionStatus.granted);
      return;
    }
    final currentStatus = await Permission.camera.status;
    final status = currentStatus.isDenied
        ? await Permission.camera.request()
        : currentStatus;
    if (mounted) {
      setState(() => _permissionStatus = status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13111D),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_permissionStatus == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (!_permissionStatus!.isGranted) {
      return _PermissionDenied(
        requiresSettings:
            _permissionStatus!.isPermanentlyDenied ||
            _permissionStatus!.isRestricted,
        restricted: _permissionStatus!.isRestricted,
        onRetry: _requestPermission,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: Row(
            children: [
              IconButton.filled(
                tooltip: 'Anulo',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skano QR Kod',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Përpunimi bëhet vetëm në pajisje.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (!kIsWeb)
                IconButton(
                  tooltip: 'Drita',
                  onPressed: _scannerController.toggleTorch,
                  icon: const Icon(
                    Icons.flashlight_on_rounded,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _handleCapture,
                    errorBuilder: (_, error) =>
                        _ScannerError(message: error.errorDetails?.message),
                  ),
                  const _ScanFrame(),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Vlera e lexuar',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _decodedValue.isEmpty
                      ? 'Drejtoje kamerën nga një QR kod.'
                      : _decodedValue,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _decodedValue.isEmpty
                        ? AppColors.muted
                        : AppColors.ink,
                    fontWeight: _decodedValue.isEmpty
                        ? FontWeight.w400
                        : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Anulo',
                        style: AppButtonStyle.secondary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Duke u ruajtur',
                        isLoading: _isSaving,
                        onPressed: null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_decodedValue.isNotEmpty) {
      return;
    }
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim() ?? '';
      if (value.isNotEmpty) {
        await _scannerController.stop();
        if (mounted) {
          setState(() => _decodedValue = value);
        }
        await _saveScannedValue(value);
        return;
      }
    }
  }

  Future<void> _saveScannedValue(String value) async {
    setState(() => _isSaving = true);
    try {
      await _databaseService.saveQrCodeId(widget.user.uid, value);
      if (mounted) {
        showAppMessage(context, 'QR Code ID i skanuar u ruajt.');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        showAppMessage(context, 'Kodi i skanuar nuk u ruajt.', isError: true);
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.55),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({
    required this.requiresSettings,
    required this.restricted,
    required this.onRetry,
  });

  final bool requiresSettings;
  final bool restricted;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white,
              size: 58,
            ),
            const SizedBox(height: 18),
            const Text(
              'Lejo përdorimin e kamerës',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              kIsWeb
                  ? 'Lejo kamerën nga kontrolli i lejeve të shfletuesit dhe '
                        'provo përsëri. PWA-ja duhet të hapet me HTTPS.'
                  : restricted
                  ? 'Qasja në kamerë është e kufizuar në këtë pajisje. '
                        'Kontrollo cilësimet e pajisjes.'
                  : 'Kamera përdoret vetëm për ta lexuar QR kodin. '
                        'Asnjë imazh nuk ruhet ose ngarkohet.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
            const SizedBox(height: 22),
            AppButton(
              label: requiresSettings && !kIsWeb
                  ? 'Hap cilësimet'
                  : 'Provo përsëri',
              onPressed: requiresSettings && !kIsWeb
                  ? openAppSettings
                  : onRetry,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Anulo',
              style: AppButtonStyle.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF201D2C),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message?.isNotEmpty == true
                ? 'Kamera nuk u hap: $message'
                : kIsWeb
                ? 'Kamera nuk mund të hapej. Kontrollo lejen e kamerës në '
                      'shfletues dhe sigurohu që faqja përdor HTTPS.'
                : 'Kamera nuk mund të hapej.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
