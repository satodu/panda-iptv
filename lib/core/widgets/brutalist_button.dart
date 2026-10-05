import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Botão Primário no estilo Oriental Brutalismo
class BrutalistButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isSecondary;

  const BrutalistButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSecondary ? AppColors.surfaceHover : AppColors.accentPrimary;
    final fgColor = isSecondary ? AppColors.textPrimary : Colors.white;

    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSecondary ? AppColors.borderHairline : AppColors.accentPrimary,
            width: 1,
          ),
          boxShadow: isSecondary
              ? null
              : [
                  BoxShadow(
                    color: AppColors.accentPrimary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: fgColor),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      AppTypography.formatTitle(label),
                      style: AppTypography.mono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: fgColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
