import 'package:flutter/material.dart';

import '../app.dart';

enum AppButtonStyle { primary, secondary, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.style = AppButtonStyle.primary,
    this.expand = true,
    this.tooltip,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppButtonStyle style;
  final bool expand;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final foreground = style == AppButtonStyle.secondary
        ? AppColors.primary
        : Colors.white;
    final background = switch (style) {
      AppButtonStyle.primary => AppColors.primary,
      AppButtonStyle.secondary => Colors.white,
      AppButtonStyle.danger => AppColors.danger,
    };
    final side = style == AppButtonStyle.secondary
        ? const BorderSide(color: AppColors.outline)
        : BorderSide.none;

    Widget button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: background,
        disabledBackgroundColor: background.withValues(alpha: 0.55),
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: side,
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: foreground,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 9),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
    );
    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
