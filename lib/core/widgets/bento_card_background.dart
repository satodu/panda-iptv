import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

/// Padrão de Fundo e Enfeite Ornamental para Cards Bento
/// Direção de Arte: Oriental Brutalismo Minimalista
/// Incorpora:
/// - Gradiente radial atmosférico na cor de destaque
/// - Malha sutil de micro-pontos (Dot Matrix Grid)
/// - Anéis arquitetônicos finos de wireframe (1px hairline)
/// - Grande marca d'água tipográfica oriental (Kanji / Katakana)
/// - Tags técnicas de micro-coordenadas em monospace
/// - Suporte opcional a imagem raster (Asset/Network) com máscara escura
class BentoCardBackground extends StatelessWidget {
  final Color accentColor;
  final String? watermarkKanji;
  final String? technicalTag;
  final IconData? watermarkIcon;
  final ImageProvider? image;
  final double imageOpacity;
  final bool showGrid;
  final bool showRings;

  const BentoCardBackground({
    super.key,
    required this.accentColor,
    this.watermarkKanji,
    this.technicalTag,
    this.watermarkIcon,
    this.image,
    this.imageOpacity = 0.12,
    this.showGrid = true,
    this.showRings = true,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Imagem de fundo opcional com máscara fosca
          if (image != null)
            ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Opacity(
                opacity: imageOpacity,
                child: Image(
                  image: image!,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // 2. Gradiente radial atmosférico no canto inferior direito
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.15, 1.15),
                radius: 1.4,
                colors: [
                  accentColor.withValues(alpha: 0.13),
                  accentColor.withValues(alpha: 0.04),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // 3. Pintura procedural de Dot Matrix e Anéis Wireframe
          if (showGrid || showRings)
            CustomPaint(
              painter: _BentoArchitecturalPainter(
                color: accentColor,
                showGrid: showGrid,
                showRings: showRings,
              ),
            ),

          // 4. Marca d'água Kanji monumental ou Ícone desconstruído
          if (watermarkKanji != null && watermarkKanji!.isNotEmpty)
            Positioned(
              bottom: -20,
              right: -10,
              child: Text(
                watermarkKanji!,
                style: AppTypography.orientalAccent(
                  fontSize: 108,
                ).copyWith(
                  color: accentColor.withValues(alpha: 0.055),
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: -6,
                ),
              ),
            )
          else if (watermarkIcon != null)
            Positioned(
              bottom: -15,
              right: -10,
              child: Icon(
                watermarkIcon,
                size: 96,
                color: accentColor.withValues(alpha: 0.045),
              ),
            ),

          // 5. Micro-coordenadas técnicas no rodapé direito
          if (technicalTag != null && technicalTag!.isNotEmpty)
            Positioned(
              bottom: 8,
              right: 12,
              child: Text(
                technicalTag!,
                style: AppTypography.mono(
                  fontSize: 9,
                  color: accentColor.withValues(alpha: 0.22),
                ).copyWith(
                  letterSpacing: 1.1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Painter procedural para Dot Matrix Grid e Anéis de Wireframe Arquitetônicos
class _BentoArchitecturalPainter extends CustomPainter {
  final Color color;
  final bool showGrid;
  final bool showRings;

  _BentoArchitecturalPainter({
    required this.color,
    required this.showGrid,
    required this.showRings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid sutil de micro-pontos (Dot Matrix)
    if (showGrid) {
      final dotPaint = Paint()
        ..color = color.withValues(alpha: 0.045)
        ..style = PaintingStyle.fill;

      const spacing = 18.0;
      final startX = size.width * 0.35; // Apenas no lado direito para não poluir os textos
      for (double x = startX; x < size.width; x += spacing) {
        for (double y = 8.0; y < size.height - 8.0; y += spacing) {
          canvas.drawCircle(Offset(x, y), 0.8, dotPaint);
        }
      }
    }

    // 2. Anéis circulares finos de contraste (1px hairline) no canto inferior
    if (showRings) {
      final ringPaint = Paint()
        ..color = color.withValues(alpha: 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final center = Offset(size.width + 10, size.height + 10);
      canvas.drawCircle(center, 70, ringPaint);
      canvas.drawCircle(center, 120, ringPaint);

      // Marca em cruz fina de mira (+)
      final crosshairPaint = Paint()
        ..color = color.withValues(alpha: 0.08)
        ..strokeWidth = 1.0;

      const chSize = 4.0;
      final chCenter = Offset(size.width - 24, 24);
      canvas.drawLine(
        Offset(chCenter.dx - chSize, chCenter.dy),
        Offset(chCenter.dx + chSize, chCenter.dy),
        crosshairPaint,
      );
      canvas.drawLine(
        Offset(chCenter.dx, chCenter.dy - chSize),
        Offset(chCenter.dx, chCenter.dy + chSize),
        crosshairPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BentoArchitecturalPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showRings != showRings;
  }
}
