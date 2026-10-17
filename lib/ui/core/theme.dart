import 'package:flutter/material.dart';

/// Design system do StatusOps: paleta "Grafite & Âmbar".
///
/// As cores têm nome pelo **significado** (sucesso, falha, rodando...), não
/// pelo tom (verde, roxo...). Assim, trocar a paleta inteira é mudar só este
/// arquivo, e o resto do código continua dizendo o que quer comunicar.
abstract final class AppColors {
  // Superfícies (do fundo para a frente) ---------------------------------
  /// Fundo da página: grafite quente, quase preto.
  static const Color background = Color(0xFF131211);

  /// Cards e barra do topo.
  static const Color surface = Color(0xFF1C1A18);

  /// Itens dentro dos cards (tiles, chips).
  static const Color surfaceAlt = Color(0xFF25221F);

  /// Bordas e divisórias.
  static const Color border = Color(0xFF36312B);

  // Texto ------------------------------------------------------------------
  static const Color textPrimary = Color(0xFFEDE7DF);
  static const Color textMuted = Color(0xFFA39A8F);

  // Identidade ---------------------------------------------------------------
  /// Cor da marca (âmbar). Também marca o que está acontecendo agora.
  static const Color brand = Color(0xFFF2B544);

  /// Destaque secundário, discreto (areia), para cards informativos.
  static const Color accent = Color(0xFFD9BC93);

  // Estados ------------------------------------------------------------------
  /// Deu certo: build verde, testes passando, ambiente online.
  static const Color success = Color(0xFF5DD879);

  /// Deu errado: execução que falhou, erro da API.
  static const Color failure = Color(0xFFB794F6);

  /// Rodando agora (deploy em andamento, job executando).
  static const Color running = brand;

  /// Pede atenção sem ser erro: build local, taxa de sucesso baixa.
  static const Color warning = Color(0xFFFF8A5B);

  /// Na fila, cancelado ou sem informação.
  static const Color queued = Color(0xFF8C8378);
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
      seedColor: AppColors.brand,
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
