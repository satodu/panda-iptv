import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Um selo Hanko tradicional animado com efeito de preenchimento de tinta ("sendo pintado").
/// Segue a estética Oriental Brutalismo Minimalista com Azul Elétrico (#0A84FF).
class HankoLoader extends StatefulWidget {
  final String label;
  final String kanji;
  final bool isCompact;
  final bool isMini;
  final double miniSize;
  final Color primaryColor;

  const HankoLoader({
    super.key,
    this.label = 'CARREGANDO.',
    this.kanji = '読込中',
    this.isCompact = false,
    this.primaryColor = AppColors.accentPrimary,
  })  : isMini = false,
        miniSize = 20.0;

  const HankoLoader.compact({
    super.key,
    this.label = 'CARREGANDO.',
    this.kanji = '読込中',
    this.primaryColor = AppColors.accentPrimary,
  })  : isCompact = true,
        isMini = false,
        miniSize = 20.0;

  const HankoLoader.mini({
    super.key,
    this.primaryColor = AppColors.accentPrimary,
    this.miniSize = 20.0,
    this.kanji = '中',
  })  : isCompact = false,
        isMini = true,
        label = '';

  @override
  State<HankoLoader> createState() => _HankoLoaderState();
}

class _HankoLoaderState extends State<HankoLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;
  late Animation<double> _stampPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();

    _fillAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.85, curve: Curves.easeInOutCubic),
    );

    _stampPulse = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 85),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.04).chain(CurveTween(curve: Curves.easeOut)), weight: 7),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 8),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMini) {
      final size = widget.miniSize;
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _fillAnimation.value;
          final scale = _stampPulse.value;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: widget.primaryColor.withValues(alpha: 0.7),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.25 * progress),
                    blurRadius: 6 * progress,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  children: [
                    // Camada de Tinta
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: size * progress,
                      child: Container(
                        color: widget.primaryColor,
                      ),
                    ),
                    // Pincel brilhante
                    if (progress > 0.05 && progress < 0.95)
                      Positioned(
                        left: (size * progress) - 1,
                        top: 0,
                        bottom: 0,
                        width: 2,
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    // Kanji de Fundo
                    Center(
                      child: Text(
                        widget.kanji,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: size * 0.55,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Kanji Iluminado Pintado
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: size * progress,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.centerLeft,
                          minWidth: size,
                          maxWidth: size,
                          minHeight: size,
                          maxHeight: size,
                          child: Center(
                            child: Text(
                              widget.kanji,
                              style: TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: size * 0.55,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    final height = widget.isCompact ? 30.0 : 42.0;
    final width = widget.isCompact ? 160.0 : 210.0;
    final fontSize = widget.isCompact ? 9.5 : 11.5;
    final kanjiSize = widget.isCompact ? 8.5 : 10.5;

    final formattedLabel = widget.label.toUpperCase().endsWith('.')
        ? widget.label.toUpperCase()
        : '${widget.label.toUpperCase()}.';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _fillAnimation.value;
        final scale = _stampPulse.value;

        return Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Caixa do Selo Hanko Brutalista
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: widget.primaryColor.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withValues(alpha: 0.15 * progress),
                      blurRadius: 12 * progress,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    children: [
                      // Camada 1: Grade de fundo brutalista sutil
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _HankoGridPainter(
                            color: widget.primaryColor.withValues(alpha: 0.05),
                          ),
                        ),
                      ),

                      // Camada 2: Tinta azul sendo pintada da esquerda para a direita
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: width * progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.primaryColor.withValues(alpha: 0.85),
                                widget.primaryColor,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),

                      // Camada 3: Pincelada brilhante na ponta da tinta
                      if (progress > 0.02 && progress < 0.98)
                        Positioned(
                          left: (width * progress) - 2,
                          top: 0,
                          bottom: 0,
                          width: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Camada 4: Conteúdo do Selo (Texto Não Pintado de Fundo)
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: widget.isCompact ? 8 : 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  formattedLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.mono(
                                    fontSize: fontSize,
                                    color: AppColors.textMuted,
                                  ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.textMuted.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  widget.kanji,
                                  style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: kanjiSize,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Camada 5: Conteúdo do Selo (Texto Iluminado Pintado na Frente)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: width * progress,
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.centerLeft,
                            minWidth: width,
                            maxWidth: width,
                            minHeight: height,
                            maxHeight: height,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: widget.isCompact ? 8 : 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      formattedLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.mono(
                                        fontSize: fontSize,
                                        color: Colors.white,
                                      ).copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      widget.kanji,
                                      style: TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: kanjiSize,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Detalhe sutil abaixo do selo (apenas modo normal)
              if (!widget.isCompact) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+ + + [ PANDA STREAM ENGINE ] + + +',
                      style: AppTypography.mono(
                        fontSize: 8.5,
                        color: widget.primaryColor.withValues(alpha: 0.7),
                      ).copyWith(letterSpacing: 1.5),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HankoGridPainter extends CustomPainter {
  final Color color;

  _HankoGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const step = 8.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HankoGridPainter oldDelegate) => oldDelegate.color != color;
}
