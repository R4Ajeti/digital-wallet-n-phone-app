import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 48, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC23B4F), Color(0xFF151116)],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC23B4F).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.shield_outlined,
        color: Colors.white,
        size: size * 0.54,
      ),
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
            onPressed: () => Navigator.of(context).pop(),
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
