import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app.dart';
import '../theme/home_palette.dart';
import 'brand_mark.dart';

class QrTicketWidget extends StatefulWidget {
  const QrTicketWidget({
    required this.qrValue,
    required this.overlayImagePath,
    required this.positionX,
    required this.positionY,
    required this.onPositionSaved,
    this.maxQrSize = 270,
    this.animateOverlay = false,
    super.key,
  });

  final String qrValue;
  final String overlayImagePath;
  final double positionX;
  final double positionY;
  final Future<void> Function(double x, double y) onPositionSaved;
  final double maxQrSize;
  final bool animateOverlay;

  @override
  State<QrTicketWidget> createState() => _QrTicketWidgetState();
}

class _QrTicketWidgetState extends State<QrTicketWidget>
    with SingleTickerProviderStateMixin {
  static const _iconHeight = 72.0;

  double get _iconWidth => BrandMark.widthForHeight(_iconHeight);
  static const _framePadding = 4.0;
  static const _overlaySpeed = 0.12;

  late double _positionX = widget.positionX.clamp(0.0, 1.0);
  late double _positionY = widget.positionY.clamp(0.0, 1.0);
  bool _dragging = false;

  Ticker? _moveTicker;
  Duration? _lastTick;
  final _random = math.Random();
  double _velocityX = 0;
  double _velocityY = 0;

  @override
  void initState() {
    super.initState();
    if (widget.animateOverlay) {
      _startOverlayMotion(initial: true);
    }
  }

  @override
  void didUpdateWidget(covariant QrTicketWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateOverlay != oldWidget.animateOverlay) {
      if (widget.animateOverlay) {
        _startOverlayMotion(initial: true);
      } else {
        _stopOverlayMotion();
      }
    }

    if (!widget.animateOverlay &&
        !_dragging &&
        (oldWidget.positionX != widget.positionX ||
            oldWidget.positionY != widget.positionY)) {
      _positionX = widget.positionX.clamp(0.0, 1.0);
      _positionY = widget.positionY.clamp(0.0, 1.0);
    }
  }

  @override
  void dispose() {
    _stopOverlayMotion();
    super.dispose();
  }

  void _startOverlayMotion({required bool initial}) {
    _stopOverlayMotion();
    if (!widget.animateOverlay) {
      return;
    }

    if (initial) {
      _positionX = _random.nextDouble().clamp(0.0, 1.0);
      _positionY = _random.nextDouble().clamp(0.0, 1.0);
    }

    _setRandomDirection();
    _lastTick = null;
    _moveTicker = createTicker(_handleOverlayTick)..start();
  }

  void _stopOverlayMotion() {
    _moveTicker?.dispose();
    _moveTicker = null;
    _lastTick = null;
  }

  void _setRandomDirection() {
    final angle = _random.nextDouble() * math.pi * 2;
    _velocityX = math.cos(angle) * _overlaySpeed;
    _velocityY = math.sin(angle) * _overlaySpeed;
  }

  void _normalizeVelocity() {
    final magnitude = math.sqrt(
      _velocityX * _velocityX + _velocityY * _velocityY,
    );
    if (magnitude == 0) {
      _setRandomDirection();
      return;
    }

    _velocityX = _velocityX / magnitude * _overlaySpeed;
    _velocityY = _velocityY / magnitude * _overlaySpeed;
  }

  void _handleOverlayTick(Duration elapsed) {
    if (!mounted || _moveTicker == null) {
      return;
    }

    if (_lastTick == null) {
      _lastTick = elapsed;
      return;
    }

    final dt = (elapsed - _lastTick!).inMicroseconds / 1000000.0;
    _lastTick = elapsed;
    if (dt <= 0) {
      return;
    }

    var nextX = _positionX + _velocityX * dt;
    var nextY = _positionY + _velocityY * dt;

    if (nextX <= 0) {
      nextX = 0;
      _velocityX = _velocityX.abs();
    } else if (nextX >= 1) {
      nextX = 1;
      _velocityX = -_velocityX.abs();
    }

    if (nextY <= 0) {
      nextY = 0;
      _velocityY = _velocityY.abs();
    } else if (nextY >= 1) {
      nextY = 1;
      _velocityY = -_velocityY.abs();
    }

    _normalizeVelocity();

    setState(() {
      _positionX = nextX;
      _positionY = nextY;
    });
  }

  double get _displayX => _positionX;

  double get _displayY => _positionY;

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
    final innerSize = size - (_framePadding * 2);
    final travelX = math.max(0, innerSize - _iconWidth);
    final travelY = math.max(0, innerSize - _iconHeight);
    final left = _framePadding + _displayX * travelX;
    final top = _framePadding + _displayY * travelY;

    return Semantics(
      label: 'QR kod demonstrues',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_framePadding),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: innerSize,
                      height: innerSize,
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [HomePalette.qrTop, HomePalette.qrBottom],
                        ).createShader(bounds),
                        child: QrImageView(
                          data: widget.qrValue,
                          version: QrVersions.auto,
                          size: innerSize,
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
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: _iconWidth,
              height: _iconHeight,
              child: widget.animateOverlay
                  ? _QrOverlayIcon(path: widget.overlayImagePath)
                  : GestureDetector(
                      onPanStart: (_) => setState(() => _dragging = true),
                      onPanUpdate: (details) {
                        setState(() {
                          if (travelX > 0) {
                            _positionX =
                                ((_positionX * travelX + details.delta.dx) /
                                        travelX)
                                    .clamp(0.0, 1.0);
                          }
                          if (travelY > 0) {
                            _positionY =
                                ((_positionY * travelY + details.delta.dy) /
                                        travelY)
                                    .clamp(0.0, 1.0);
                          }
                        });
                      },
                      onPanEnd: (_) => _savePosition(),
                      child: _QrOverlayIcon(path: widget.overlayImagePath),
                    ),
            ),
          ],
        ),
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

    if (hasImage) {
      return Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _DefaultOverlayIcon(),
      );
    }

    return const _DefaultOverlayIcon();
  }
}

class _DefaultOverlayIcon extends StatelessWidget {
  const _DefaultOverlayIcon();

  static const _height = _QrTicketWidgetState._iconHeight;

  @override
  Widget build(BuildContext context) {
    return BrandMark(size: _height);
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
