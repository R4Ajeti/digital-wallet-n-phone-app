import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app.dart';

class QrTicketWidget extends StatefulWidget {
  const QrTicketWidget({
    required this.qrValue,
    required this.overlayImagePath,
    required this.positionX,
    required this.positionY,
    required this.onPositionSaved,
    this.maxQrSize = 270,
    super.key,
  });

  final String qrValue;
  final String overlayImagePath;
  final double positionX;
  final double positionY;
  final Future<void> Function(double x, double y) onPositionSaved;
  final double maxQrSize;

  @override
  State<QrTicketWidget> createState() => _QrTicketWidgetState();
}

class _QrTicketWidgetState extends State<QrTicketWidget> {
  static const _iconSize = 58.0;

  late double _positionX = widget.positionX.clamp(0.0, 1.0);
  late double _positionY = widget.positionY.clamp(0.0, 1.0);
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant QrTicketWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging &&
        (oldWidget.positionX != widget.positionX ||
            oldWidget.positionY != widget.positionY)) {
      _positionX = widget.positionX.clamp(0.0, 1.0);
      _positionY = widget.positionY.clamp(0.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, widget.maxQrSize);
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: widget.qrValue.trim().isEmpty
                ? _EmptyQrState(size: size)
                : _buildQr(size),
          ),
        );
      },
    );
  }

  Widget _buildQr(double size) {
    final travel = math.max(0, size - _iconSize);
    final left = _positionX * travel;
    final top = _positionY * travel;

    return Semantics(
      label: 'QR kod demonstrues',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC23B4F), Color(0xFF09080A)],
                  ).createShader(bounds),
                  child: QrImageView(
                    data: widget.qrValue,
                    version: QrVersions.auto,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.transparent,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.white,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: _iconSize,
            height: _iconSize,
            child: GestureDetector(
              onPanStart: (_) => setState(() => _dragging = true),
              onPanUpdate: (details) {
                if (travel == 0) {
                  return;
                }
                setState(() {
                  _positionX =
                      ((_positionX * travel + details.delta.dx) / travel).clamp(
                        0.0,
                        1.0,
                      );
                  _positionY =
                      ((_positionY * travel + details.delta.dy) / travel).clamp(
                        0.0,
                        1.0,
                      );
                });
              },
              onPanEnd: (_) => _savePosition(),
              child: _QrOverlayIcon(path: widget.overlayImagePath),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePosition() async {
    setState(() => _dragging = false);
    try {
      await widget.onPositionSaved(_positionX, _positionY);
    } catch (_) {}
  }
}

class _QrOverlayIcon extends StatelessWidget {
  const _QrOverlayIcon({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final hasImage = path.isNotEmpty && File(path).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _DefaultOverlayIcon(),
            )
          : const _DefaultOverlayIcon(),
    );
  }
}

class _DefaultOverlayIcon extends StatelessWidget {
  const _DefaultOverlayIcon();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC23B4F), Color(0xFF151116)],
        ),
      ),
      child: Icon(Icons.shield_outlined, color: Colors.white, size: 29),
    );
  }
}

class _EmptyQrState extends StatelessWidget {
  const _EmptyQrState({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(size * 0.07),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.primary,
                size: 46,
              ),
              const SizedBox(height: 8),
              const Text(
                'Nuk ka ende një QR kod aktiv',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Hape menynë dhe vendos një vlerë manuale ose skano një kod.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
