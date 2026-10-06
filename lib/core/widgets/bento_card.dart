import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Card Bento Oriental Brutalista
/// Totalmente otimizado para Controle Remoto (D-Pad TV), Teclado e Mouse.
class BentoCard extends StatefulWidget {
  final Widget? background;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool isSelected;
  final double borderRadius;
  final FocusNode? focusNode;
  final bool autofocus;

  const BentoCard({
    super.key,
    required this.child,
    this.background,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.isSelected = false,
    this.borderRadius = 14.0,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<BentoCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChanged(bool focused) {
    setState(() => _isFocused = focused);
    if (focused && mounted) {
      // Garante que o card focado pelo controle remoto fique visível no centro da tela
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onTap != null;
    final active = widget.isSelected || _isHovered || _isFocused;

    // Efeito de escala e translação mais nítido para TV (10-foot experience)
    final scale = _isFocused ? 1.035 : (_isHovered ? 1.015 : 1.0);
    final translateY = _isFocused ? -4.0 : (_isHovered ? -2.5 : 0.0);

    return FocusableActionDetector(
      focusNode: isInteractive ? _effectiveFocusNode : null,
      autofocus: widget.autofocus,
      enabled: isInteractive,
      mouseCursor: isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: _onFocusChanged,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onTap?.call(),
        ),
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(scale, scale, 1.0)
          ..setTranslationRaw(0.0, translateY, 0.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.backgroundColor ??
              (_isFocused
                  ? AppColors.surfaceHover
                  : (active ? AppColors.surfaceHover : AppColors.surfaceCard)),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: _isFocused
                ? AppColors.accentPrimary
                : (active ? AppColors.borderActive : AppColors.borderHairline),
            width: _isFocused ? 2.0 : 1.0,
          ),
          boxShadow: _isFocused
              ? [
                  // Glow neon intenso para foco do controle remoto
                  BoxShadow(
                    color: AppColors.accentPrimary.withValues(alpha: 0.45),
                    blurRadius: 22,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: AppColors.accentCyan.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : (_isHovered
                  ? [
                      BoxShadow(
                        color: AppColors.accentPrimary.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              if (widget.background != null)
                Positioned.fill(child: widget.background!),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  splashColor: AppColors.accentPrimary.withValues(alpha: 0.15),
                  highlightColor: AppColors.accentPrimary.withValues(alpha: 0.05),
                  child: Padding(
                    padding: widget.padding ?? const EdgeInsets.all(20),
                    child: widget.child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
