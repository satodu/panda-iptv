import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Chip de Categoria Brutalista com suporte completo a Controle Remoto (D-Pad TV),
/// Mouse e Teclado.
class FocusableCategoryChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FocusableCategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<FocusableCategoryChip> createState() => _FocusableCategoryChipState();
}

class _FocusableCategoryChipState extends State<FocusableCategoryChip> {
  bool _isFocused = false;
  bool _isHovered = false;

  void _onFocusChanged(bool focused) {
    setState(() => _isFocused = focused);
    if (focused && mounted) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _isFocused ? 1.05 : (_isHovered ? 1.02 : 1.0);

    return FocusableActionDetector(
      onShowFocusHighlight: _onFocusChanged,
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      mouseCursor: SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onTap(),
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.diagonal3Values(scale, scale, 1.0),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.accentPrimary
                : (_isFocused ? AppColors.surfaceHover : AppColors.surfaceCard),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused
                  ? AppColors.accentCyan
                  : (widget.isSelected ? AppColors.accentPrimary : AppColors.borderHairline),
              width: _isFocused ? 2.0 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.accentCyan.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: AppTypography.mono(
              fontSize: 11,
              color: widget.isSelected
                  ? Colors.white
                  : (_isFocused ? AppColors.accentCyan : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
