import 'package:flutter/material.dart';

/// Design Tokens de Cor - Panda IPTV
/// Oriental Brutalismo Minimalista com Destaque em Azul Elétrico
class AppColors {
  // Superfícies (Strict Palette)
  static const Color canvas = Color(0xFF0D1216);      // surface-0 (preto mineral mate)
  static const Color surfaceCard = Color(0xFF141A1F); // surface-1 (grafite escuro)
  static const Color surfaceHover = Color(0xFF1C242C);// surface-2 (interativo / foco)
  static const Color surfaceDialog = Color(0xFF11161B);// modais e menus

  // Destaques e Acentos
  static const Color accentPrimary = Color(0xFF0A84FF); // Azul Elétrico
  static const Color accentCyan = Color(0xFF00D2FF);    // Ciano Técnico (Tags, Bitrate)
  static const Color accentGlow = Color(0x330A84FF);    // Glow azul sutil

  // Tipografia
  static const Color textPrimary = Color(0xFFDEDFD7);   // Off-white nítido fosco
  static const Color textMuted = Color(0xFF7E8790);     // Cinza técnico intermediário
  static const Color textDisabled = Color(0xFF3A444C);  // Desabilitado / Placeholder

  // Bordas e Divisores
  static const Color borderHairline = Color(0x14DEDFD7);// 1px hairline bordas (8% opacity)
  static const Color borderActive = Color(0x660A84FF);  // Borda ativa / foco
  
  // Status
  static const Color statusLive = Color(0xFF00E5FF);    // Indicador AO VIVO
  static const Color statusError = Color(0xFFFF453A);   // Erro / Alerta
}
