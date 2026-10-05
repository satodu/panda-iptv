import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Card Bento Brutalista com suporte a hover, foco e respiro 'Ma'
class BentoCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool isSelected;
  final double borderRadius;

  const BentoCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.isSelected = false,
    this.borderRadius = 14.0,
  });

  @override
  State<BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<BentoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, active ? -2.0 : 0.0, 0),
          padding: widget.padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? (active ? AppColors.surfaceHover : AppColors.surfaceCard),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: active ? AppColors.borderActive : AppColors.borderHairline,
              width: 1.0,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.accentPrimary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
