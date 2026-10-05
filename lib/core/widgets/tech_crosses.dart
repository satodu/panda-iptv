import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Elemento decorativo técnico de alinhamento (+ + +)
/// Conforme especificado no Guia Oriental Brutalismo
class TechCrosses extends StatelessWidget {
  final int count;
  final double spacing;
  final double opacity;

  const TechCrosses({
    super.key,
    this.count = 4,
    this.spacing = 8.0,
    this.opacity = 0.25,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: Text(
            '+',
            style: AppTypography.mono(
              fontSize: 11,
              color: AppColors.textPrimary.withValues(alpha: opacity),
            ),
          ),
        );
      }),
    );
  }
}
