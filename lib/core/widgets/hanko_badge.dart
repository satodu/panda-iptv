import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Selo Hanko estilizado e badges técnicas
/// Suporta animação de pulso rítmico para badges ativas ([ LIVE ]).
class HankoBadge extends StatefulWidget {
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
  State<HankoBadge> createState() => _HankoBadgeState();
}

class _HankoBadgeState extends State<HankoBadge> with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.isLive) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
      _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = widget.isLive
        ? AppColors.statusLive
        : (widget.borderColor ?? AppColors.accentPrimary);
    final effectiveText = widget.isLive
        ? AppColors.statusLive
        : (widget.textColor ?? AppColors.textPrimary);
    final effectiveBg = widget.backgroundColor ?? effectiveBorder.withValues(alpha: 0.08);

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
          if (widget.isLive && _pulseAnimation != null) ...[
            AnimatedBuilder(
              animation: _pulseAnimation!,
              builder: (context, child) {
                return Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppColors.statusLive.withValues(alpha: _pulseAnimation!.value),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.statusLive.withValues(alpha: _pulseAnimation!.value * 0.7),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else if (widget.isLive) ...[
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                color: AppColors.statusLive,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Text(
            widget.text.toUpperCase(),
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
