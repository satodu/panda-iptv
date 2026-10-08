import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'hanko_loader.dart';

/// Botão Primário no estilo Oriental Brutalismo
/// Suporta controle remoto TV (D-pad), hover e teclado.
class BrutalistButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isSecondary;
  final bool autofocus;
  final bool autoScrollOnFocus;
  final FocusNode? focusNode;

  const BrutalistButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isSecondary = false,
    this.autofocus = false,
    this.autoScrollOnFocus = false,
    this.focusNode,
  });

  @override
  State<BrutalistButton> createState() => _BrutalistButtonState();
}

class _BrutalistButtonState extends State<BrutalistButton> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || _isHovered;
    final isInteractive = !widget.isLoading && widget.onPressed != null;

    final bgColor = widget.isSecondary
        ? (active ? AppColors.surfaceHover : AppColors.surfaceCard)
        : (active ? const Color(0xFF1E8DFF) : AppColors.accentPrimary);

    final fgColor = widget.isSecondary
        ? (_isFocused ? AppColors.accentCyan : AppColors.textPrimary)
        : Colors.white;

    final borderColor = _isFocused
        ? AppColors.accentCyan
        : (widget.isSecondary
            ? (active ? AppColors.borderActive : AppColors.borderHairline)
            : AppColors.accentPrimary);

    final scale = _isFocused ? 1.04 : (_isHovered ? 1.02 : 1.0);

    return FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: isInteractive,
      mouseCursor: isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowFocusHighlight: (focused) {
        setState(() => _isFocused = focused);
        if (focused && mounted && widget.autoScrollOnFocus) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      },
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (isInteractive) {
              widget.onPressed?.call();
            }
            return null;
          },
        ),
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(scale, scale, 1.0),
        transformAlignment: Alignment.center,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: _isFocused ? 2.0 : 1.0,
          ),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: AppColors.accentPrimary.withValues(alpha: 0.5),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: AppColors.accentCyan.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 1),
                  ),
                ]
              : (widget.isSecondary
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.accentPrimary.withValues(alpha: active ? 0.4 : 0.25),
                        blurRadius: active ? 16 : 10,
                        offset: const Offset(0, 2),
                      ),
                    ]),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            canRequestFocus: false,
            onTap: isInteractive ? widget.onPressed : null,
            borderRadius: BorderRadius.circular(10),
            splashColor: Colors.white.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: widget.isLoading
                    ? HankoLoader.mini(
                        miniSize: 20,
                        primaryColor: fgColor,
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 18, color: fgColor),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              AppTypography.formatTitle(widget.label),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.mono(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: fgColor,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
