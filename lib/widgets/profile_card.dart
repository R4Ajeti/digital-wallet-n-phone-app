import 'dart:io';

import 'package:flutter/material.dart';

import '../app.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.userTypeLabel,
    required this.imagePath,
    super.key,
  });

  final String userTypeLabel;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _ProfileImage(path: imagePath),
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
  const _ProfileImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final hasImage = path.isNotEmpty && File(path).existsSync();

    return Container(
      width: 78,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _ProfileFallback(),
            )
          : const _ProfileFallback(),
    );
  }
}

class _ProfileFallback extends StatelessWidget {
  const _ProfileFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.person_rounded, color: AppColors.primary, size: 44),
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
