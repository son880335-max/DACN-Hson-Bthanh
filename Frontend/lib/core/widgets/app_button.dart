import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AppButtonType { primary, secondary, outlined, danger }

typedef AppButtonVariant = AppButtonType;

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double minHeight;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    AppButtonType? type,
    AppButtonVariant? variant,
    this.icon,
    this.isLoading = false,
    this.minHeight = 56.0,
  }) : type = variant ?? type ?? AppButtonType.primary;

  @override
  Widget build(BuildContext context) {
    final double height = (type == AppButtonType.primary) ? 56.0 : (minHeight >= 48 ? minHeight : 48.0);

    Color bg;
    Color fg;
    BorderSide? border;

    switch (type) {
      case AppButtonType.primary:
        bg = AppColors.primary;
        fg = AppColors.onPrimary;
        border = null;
        break;
      case AppButtonType.secondary:
        bg = AppColors.primaryContainer;
        fg = AppColors.primary;
        border = null;
        break;
      case AppButtonType.outlined:
        bg = Colors.transparent;
        fg = AppColors.primary;
        border = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
      case AppButtonType.danger:
        bg = AppColors.dangerContainer;
        fg = AppColors.danger;
        border = const BorderSide(color: AppColors.danger, width: 1.5);
        break;
    }

    if (onPressed == null) {
      bg = AppColors.borderSubtle;
      fg = AppColors.textMuted;
      border = null;
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: border ?? BorderSide.none,
        ),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
                  ),
                  const SizedBox(width: 12),
                ] else if (icon != null) ...[
                  Icon(icon, color: fg, size: 22),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    text,
                    style: AppTypography.button.copyWith(color: fg),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
