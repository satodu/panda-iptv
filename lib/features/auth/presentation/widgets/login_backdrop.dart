import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Fundo decorativo da tela de login: Grade técnica, marcas de corte
/// e a marca d'água tradicional Hanko (熊猫).
/// Estética 100% brutalista minimalista nítida, sem sombras difusas nem blocos com blur.
class LoginBackdrop extends StatelessWidget {
  const LoginBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _LoginBackdropPainter(),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _LoginBackdropPainter extends CustomPainter {
  const _LoginBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final isWide = w > h;

    // Fundo base canvas (#0D1216)
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.canvas);

    // 1. Grade técnica nítida de 1px a cada 80px (sem blur)
    final gridPaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    for (double x = 0; x <= w; x += 80) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y <= h; y += 80) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 2. Marcas de corte técnicas nos 4 cantos
    const m = 24.0;
    const len = 18.0;
    final cropPaint = Paint()
      ..color = AppColors.accentCyan.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    for (final corner in [
      const Offset(m, m),
      Offset(w - m, m),
      Offset(m, h - m),
      Offset(w - m, h - m),
    ]) {
      final dx = corner.dx < w / 2 ? 1.0 : -1.0;
      final dy = corner.dy < h / 2 ? 1.0 : -1.0;
      canvas.drawLine(corner, corner.translate(len * dx, 0), cropPaint);
      canvas.drawLine(corner, corner.translate(0, len * dy), cropPaint);
    }

    // 3. Tag técnica vertical (modo paisagem)
    if (isWide) {
      final tagPainter = TextPainter(
        text: TextSpan(
          text: '[ BROADCAST // 4K ]',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            letterSpacing: 3,
            color: AppColors.accentCyan.withValues(alpha: 0.4),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(w - 34, 120);
      canvas.rotate(math.pi / 2);
      tagPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // 4. Marca d'água Hanko tradicional (熊猫) com traço elegante e limpo
    final kanjiSize = isWide ? h * 0.45 : w * 0.55;
    final kanjiPainter = TextPainter(
      text: TextSpan(
        text: '熊猫',
        style: TextStyle(
          fontSize: kanjiSize,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary.withValues(alpha: 0.045),
          fontFamilyFallback: const [
            'Noto Sans CJK SC',
            'Noto Sans SC',
            'Noto Sans CJK JP',
            'sans-serif',
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final kanjiOffset = isWide
        ? Offset(w - kanjiPainter.width - 40, h - kanjiPainter.height - 16)
        : Offset(w - kanjiPainter.width - 20, h - kanjiPainter.height - 40);

    kanjiPainter.paint(canvas, kanjiOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
