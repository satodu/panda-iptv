import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tipografia e Hierarquia Visual - Panda IPTV
/// Oriental Brutalismo: Títulos em caixa alta com ponto final seco (.)
class AppTypography {
  /// Título primário Monolítico (Display)
  static TextStyle displayLarge({Color color = AppColors.textPrimary}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: color,
    );
  }

  /// Título de seção / Bento Card
  static TextStyle sectionTitle({Color color = AppColors.textPrimary, double? fontSize}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize ?? 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: color,
    );
  }

  /// Subtítulo ou cabeçalho secundário
  static TextStyle titleMedium({Color color = AppColors.textPrimary, double? fontSize}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize ?? 14,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  /// Texto de corpo / descrição
  static TextStyle body({Color color = AppColors.textPrimary, double? fontSize}) {
    return GoogleFonts.inter(
      fontSize: fontSize ?? 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: color,
    );
  }

  /// Texto de botão primário
  static TextStyle button({Color color = Colors.white, double? fontSize}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize ?? 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: color,
    );
  }

  /// Metadados técnicos, durações, portas, tags
  static TextStyle mono({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.textMuted,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 0.2,
      color: color,
    );
  }

  /// Caracteres decorativos orientais (Kanji / Katakana)
  static TextStyle orientalAccent({
    double fontSize = 11,
    Color color = AppColors.textMuted,
  }) {
    return GoogleFonts.notoSansJp(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      letterSpacing: 1.5,
      color: color.withValues(alpha: 0.4),
    );
  }

  /// Formata qualquer título para o padrão do guia: Caixa Alta + Ponto Final Seco
  static String formatTitle(String text) {
    final clean = text.trim().toUpperCase();
    if (clean.endsWith('.')) return clean;
    return '$clean.';
  }
}
