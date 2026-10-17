import 'package:flutter/material.dart';

/// Paleta do painel (tema escuro com destaques "neon").
abstract final class AppColors {
  static const Color background = Color(0xFF0B1220);
  static const Color surface = Color(0xFF111B2E);
  static const Color surfaceAlt = Color(0xFF16223A);
  static const Color border = Color(0xFF22304D);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color green = Color(0xFF4ADE80);
  static const Color orange = Color(0xFFFB923C);
  static const Color blue = Color(0xFF60A5FA);
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);
}

/// Estilo usado nos títulos dos painéis.
const TextStyle panelTitleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: AppColors.textPrimary,
);

ThemeData buildAppTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.cyan,
      brightness: Brightness.dark,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
  );
}
