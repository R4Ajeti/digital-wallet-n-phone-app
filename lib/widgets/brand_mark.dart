import 'package:flutter/material.dart';

import '../utils/navigation.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 48, super.key});

  /// Target height of the emblem. Width follows the PNG aspect ratio.
  final double size;

  static const assetPath =
      'experimental-resource/icon/stema-komunes-prishtines.png';
  static const assetWidth = 609.0;
  static const assetHeight = 781.0;
  static const aspectRatio = assetWidth / assetHeight;

  static double widthForHeight(double height) => height * aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: size,
      width: widthForHeight(size),
      fit: BoxFit.contain,
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBack = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack) ...[
          IconButton.filledTonal(
            tooltip: 'Kthehu',
            onPressed: () => maybePopRoute(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 10),
        ] else ...[
          const BrandMark(size: 46),
          const SizedBox(width: 13),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
