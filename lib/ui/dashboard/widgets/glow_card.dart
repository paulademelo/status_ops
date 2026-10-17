import 'package:flutter/material.dart';

import 'package:status_ops/ui/core/theme.dart';

/// Card com borda colorida e brilho suave, base de todo o painel.
///
/// Em temas claros (`glow == 0`) o brilho vira uma sombra discreta.
class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;

  /// Cor da borda e do brilho. Quando nula, usa a cor da marca.
  final Color? color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = color ?? colors.brand;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [_shadow(colors, accent)],
      ),
      child: child,
    );
  }

  BoxShadow _shadow(AppPalette colors, Color accent) {
    if (colors.glow > 0) {
      return BoxShadow(
        color: accent.withValues(alpha: colors.glow),
        blurRadius: 18,
        spreadRadius: 1,
      );
    }
    return BoxShadow(
      color: colors.textPrimary.withValues(alpha: 0.06),
      blurRadius: 14,
      offset: const Offset(0, 4),
    );
  }
}
