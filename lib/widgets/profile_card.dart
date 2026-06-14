import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app.dart';

const _ticketInk = Color(0xFF2D2D2D);
const _ticketMuted = Color(0xFF575757);
const _ticketBorder = Color(0xFFD9D9D9);

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.userTypeLabel,
    required this.imageBytes,
    this.imageScale = 1,
    super.key,
  });

  final String userTypeLabel;
  final Uint8List? imageBytes;
  final double imageScale;

  @override
  Widget build(BuildContext context) {
    final safeImageScale = imageScale.clamp(0.5, 2.0);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _ticketBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 144),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              _ProfileImage(bytes: imageBytes, scale: safeImageScale),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  userTypeLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ticketMuted,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({required this.bytes, required this.scale});

  final Uint8List? bytes;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74 * scale,
      height: 99 * scale,
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes != null
          ? Image.memory(
              bytes!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _ProfileFallback(scale: scale),
            )
          : _ProfileFallback(scale: scale),
    );
  }
}

class _ProfileFallback extends StatelessWidget {
  const _ProfileFallback({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        color: AppColors.primary,
        size: 44 * scale,
      ),
    );
  }
}

class TicketValidityCard extends StatelessWidget {
  const TicketValidityCard({required this.expirationText, super.key});

  final String expirationText;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _ticketBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Column(
          children: [
            const Text(
              'Bileta juaj është e vlefshme deri më',
              textAlign: TextAlign.center,
              style: TextStyle(color: _ticketMuted, fontSize: 15, height: 1.35),
            ),
            const SizedBox(height: 5),
            Text(
              expirationText.isEmpty ? 'Duke u përditësuar…' : expirationText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ticketInk,
                fontSize: 24,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
