import 'package:flutter/material.dart';

/// Design system do StatusOps.
///
/// As cores têm nome pelo **significado** (sucesso, falha, rodando...), não
/// pelo tom. Cada tema é uma instância de [AppPalette], e os widgets leem a
/// paleta atual com `context.colors`. Trocar de tema é só entregar outra
/// paleta para o `MaterialApp`, e o app inteiro se redesenha.
///
/// [AppPalette] é um `ThemeExtension`: o jeito do Flutter de pendurar cores
/// próprias no `ThemeData`, inclusive com animação entre um tema e outro.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.brand,
    required this.accent,
    required this.success,
    required this.failure,
    required this.running,
    required this.warning,
    required this.queued,
    required this.glow,
  });

  /// Escuro quente com âmbar.
  static const grafiteAmbar = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF131211),
    surface: Color(0xFF1C1A18),
    surfaceAlt: Color(0xFF25221F),
    border: Color(0xFF36312B),
    textPrimary: Color(0xFFEDE7DF),
    textMuted: Color(0xFFA39A8F),
    brand: Color(0xFFF2B544),
    accent: Color(0xFFD9BC93),
    success: Color(0xFF5DD879),
    failure: Color(0xFFB794F6),
    running: Color(0xFFF2B544),
    warning: Color(0xFFFF8A5B),
    queued: Color(0xFF8C8378),
    glow: 0.22,
  );

  /// Claro, cor de papel, com terracota. Sem brilho: usa sombra suave.
  static const papelTerracota = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF4F1EC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF8F6F2),
    border: Color(0xFFE2DBD0),
    textPrimary: Color(0xFF1F1B16),
    textMuted: Color(0xFF6F675D),
    brand: Color(0xFFC2502E),
    accent: Color(0xFF9C7F5F),
    success: Color(0xFF1E9E5A),
    failure: Color(0xFF7C3AED),
    running: Color(0xFFC2502E),
    warning: Color(0xFFB7791F),
    queued: Color(0xFF8A8278),
    glow: 0,
  );

  /// Escuro neutro com coral.
  static const zincoCoral = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0F0F11),
    surface: Color(0xFF18181B),
    surfaceAlt: Color(0xFF202024),
    border: Color(0xFF2E2E33),
    textPrimary: Color(0xFFF4F4F5),
    textMuted: Color(0xFFA1A1AA),
    brand: Color(0xFFFF6B4A),
    accent: Color(0xFFD4D4D8),
    success: Color(0xFF4ADE80),
    failure: Color(0xFFA855F7),
    running: Color(0xFFFF6B4A),
    warning: Color(0xFFFACC15),
    queued: Color(0xFF71717A),
    glow: 0.22,
  );

  final Brightness brightness;

  // Superfícies (do fundo para a frente).
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;

  // Texto.
  final Color textPrimary;
  final Color textMuted;

  /// Cor da marca.
  final Color brand;

  /// Destaque secundário, discreto, para cards informativos.
  final Color accent;

  /// Deu certo: build verde, testes passando, ambiente online.
  final Color success;

  /// Deu errado: execução que falhou, erro da API.
  final Color failure;

  /// Rodando agora (deploy em andamento, job executando).
  final Color running;

  /// Pede atenção sem ser erro: build local, taxa de sucesso baixa.
  final Color warning;

  /// Na fila, cancelado ou sem informação.
  final Color queued;

  /// Intensidade do brilho dos cards (0 = sem brilho, usa sombra).
  final double glow;

  /// Cria uma variação do tema mudando a identidade (marca, destaque e
  /// brilho). O Flutter exige este método em todo `ThemeExtension`; aqui ele
  /// expõe só o que faz sentido ajustar, mantendo as cores de estado.
  @override
  AppPalette copyWith({Color? brand, Color? accent, double? glow}) {
    return AppPalette(
      brightness: brightness,
      background: background,
      surface: surface,
      surfaceAlt: surfaceAlt,
      border: border,
      textPrimary: textPrimary,
      textMuted: textMuted,
      brand: brand ?? this.brand,
      accent: accent ?? this.accent,
      success: success,
      failure: failure,
      running: brand ?? running,
      warning: warning,
      queued: queued,
      glow: glow ?? this.glow,
    );
  }

  /// Mistura duas paletas: é o que faz a troca de tema ser animada.
  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      border: mix(border, other.border),
      textPrimary: mix(textPrimary, other.textPrimary),
      textMuted: mix(textMuted, other.textMuted),
      brand: mix(brand, other.brand),
      accent: mix(accent, other.accent),
      success: mix(success, other.success),
      failure: mix(failure, other.failure),
      running: mix(running, other.running),
      warning: mix(warning, other.warning),
      queued: mix(queued, other.queued),
      glow: glow + (other.glow - glow) * t,
    );
  }
}

/// Os temas disponíveis no seletor.
enum AppThemeId {
  grafiteAmbar('Grafite & Âmbar', AppPalette.grafiteAmbar),
  papelTerracota('Papel & Terracota', AppPalette.papelTerracota),
  zincoCoral('Zinco & Coral', AppPalette.zincoCoral);

  const AppThemeId(this.label, this.palette);

  final String label;
  final AppPalette palette;

  /// O tema salvo com esse nome, ou `null` se não existir.
  static AppThemeId? fromName(String? name) {
    for (final id in values) {
      if (id.name == name) {
        return id;
      }
    }
    return null;
  }
}

/// Atalho: `context.colors.success` em vez de
/// `Theme.of(context).extension<AppPalette>()!.success`.
extension AppPaletteContext on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.grafiteAmbar;
}

/// Estilo dos títulos dos painéis. Sem cor: herda o texto do tema.
const TextStyle panelTitleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
);

ThemeData buildAppTheme(AppPalette palette) {
  final base = ThemeData(
    brightness: palette.brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.brand,
      brightness: palette.brightness,
      surface: palette.surface,
    ),
    scaffoldBackgroundColor: palette.background,
    popupMenuTheme: PopupMenuThemeData(color: palette.surface),
    extensions: [palette],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    ),
  );
}
