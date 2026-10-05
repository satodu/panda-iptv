import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Selo Hanko estilizado e badges técnicas
class HankoBadge extends StatelessWidget {
  final String text;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLive;

  const HankoBadge({
    super.key,
    required this.text,
    this.borderColor,
    this.backgroundColor,
    this.textColor,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = isLive ? AppColors.statusLive : (borderColor ?? AppColors.accentPrimary);
    final effectiveText = isLive ? AppColors.statusLive : (textColor ?? AppColors.textPrimary);
    final effectiveBg = backgroundColor ?? effectiveBorder.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: effectiveBg,
        border: Border.all(color: effectiveBorder.withValues(alpha: 0.6), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                color: AppColors.statusLive,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Text(
            text.toUpperCase(),
            style: AppTypography.mono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: effectiveText,
            ),
          ),
        ],
      ),
    );
  }
}
