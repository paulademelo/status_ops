import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:status_ops/ui/core/theme.dart';
import 'package:status_ops/ui/core/theme_controller.dart';

void main() {
  group('ThemeController', _controllerTests);
  group('AppPalette', _paletteTests);
}

void _controllerTests() {
  test('sem nada salvo, usa o tema padrão', () {
    final controller = ThemeController(read: () => null);

    expect(controller.current, AppThemeId.grafiteAmbar);
  });

  test('abre com o tema salvo no navegador', () {
    final controller = ThemeController(read: () => 'zincoCoral');

    expect(controller.current, AppThemeId.zincoCoral);
    expect(controller.palette.brand, AppPalette.zincoCoral.brand);
  });

  test('ignora um valor salvo que não existe mais', () {
    final controller = ThemeController(read: () => 'temaAntigo');

    expect(controller.current, AppThemeId.grafiteAmbar);
  });

  test('escolher um tema salva e avisa a tela', () {
    final saved = <String>[];
    var notifications = 0;
    final controller = ThemeController(write: saved.add)
      ..addListener(() => notifications++);

    controller.select(AppThemeId.papelTerracota);

    expect(controller.current, AppThemeId.papelTerracota);
    expect(saved, ['papelTerracota']);
    expect(notifications, 1);
  });

  test('escolher o mesmo tema não faz nada', () {
    final saved = <String>[];
    final controller = ThemeController(write: saved.add);

    controller.select(AppThemeId.grafiteAmbar);

    expect(saved, isEmpty);
  });
}

void _paletteTests() {
  test('lerp nas pontas devolve as cores de cada tema', () {
    const from = AppPalette.grafiteAmbar;
    const to = AppPalette.zincoCoral;

    expect(from.lerp(to, 0).brand, from.brand);
    expect(from.lerp(to, 1).brand, to.brand);
    expect(from.lerp(to, 1).brightness, to.brightness);
  });

  test('todos os temas têm nome e brilho coerente', () {
    for (final theme in AppThemeId.values) {
      expect(theme.label, isNotEmpty);
      final isLight = theme.palette.brightness == Brightness.light;
      expect(theme.palette.glow == 0, isLight);
    }
  });
}
