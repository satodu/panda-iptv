import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tema Principal do Panda IPTV
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
      cardColor: AppColors.surfaceCard,
      primaryColor: AppColors.accentPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentPrimary,
        secondary: AppColors.accentCyan,
        surface: AppColors.surfaceCard,
        error: AppColors.statusError,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderHairline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderHairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accentPrimary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 13),
      ),
    );
  }
}
