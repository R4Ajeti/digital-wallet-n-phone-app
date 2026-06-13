import 'dart:io';

import 'package:flutter/material.dart';

import '../app.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.userTypeLabel,
    required this.imagePath,
    this.imageScale = 1,
    super.key,
  });

  final String userTypeLabel;
  final String imagePath;
  final double imageScale;

  @override
  Widget build(BuildContext context) {
    final safeImageScale = imageScale.clamp(0.5, 2.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _ProfileImage(path: imagePath, scale: safeImageScale),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                userTypeLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ink,
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
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({required this.path, required this.scale});

  final String path;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final hasImage = path.isNotEmpty && File(path).existsSync();

    return Container(
      width: 78 * scale,
      height: 88 * scale,
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(18 * scale),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.file(
              File(path),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          children: [
            const Text(
              'Bileta juaj është e vlefshme deri më',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              expirationText.isEmpty ? 'Duke u përditësuar…' : expirationText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
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
