import 'package:flutter/material.dart';

import 'package:status_ops/ui/core/theme.dart';
import 'package:status_ops/ui/core/theme_controller.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.isProduction,
    required this.themeController,
  });

  /// `false` quando o app roda localmente (fora do pipeline).
  final bool isProduction;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 64,
      padding: const EdgeInsets.only(left: 24, right: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.brand.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.rocket_launch, color: colors.brand, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'StatusOps',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          _EnvironmentChip(isProduction: isProduction),
          const SizedBox(width: 4),
          _ThemeMenu(controller: themeController),
        ],
      ),
    );
  }
}

class _EnvironmentChip extends StatelessWidget {
  const _EnvironmentChip({required this.isProduction});

  final bool isProduction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = isProduction ? colors.success : colors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Text(
            isProduction ? 'produção' : 'local',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão com paleta que abre a lista de temas.
class _ThemeMenu extends StatelessWidget {
  const _ThemeMenu({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopupMenuButton<AppThemeId>(
      tooltip: 'Trocar tema',
      icon: Icon(Icons.palette_outlined, color: colors.textMuted),
      initialValue: controller.current,
      onSelected: controller.select,
      itemBuilder: (context) => [
        for (final theme in AppThemeId.values)
          PopupMenuItem(
            value: theme,
            child: _ThemeOption(
              theme: theme,
              selected: theme == controller.current,
            ),
          ),
      ],
    );
  }
}

/// Uma linha do menu: amostra das cores + nome + check no tema atual.
class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.theme, required this.selected});

  final AppThemeId theme;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = theme.palette;
    return Row(
      children: [
        _Swatch(background: palette.background, accent: palette.brand),
        const SizedBox(width: 12),
        Expanded(child: Text(theme.label)),
        if (selected) ...[
          const SizedBox(width: 12),
          Icon(Icons.check, size: 18, color: context.colors.brand),
        ],
      ],
    );
  }
}

/// Bolinha com o fundo do tema e um "miolo" na cor da marca.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.background, required this.accent});

  final Color background;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.border),
      ),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      ),
    );
  }
}
