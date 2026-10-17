import 'package:flutter/material.dart';

import 'package:status_ops/ui/core/theme.dart';

/// Card escuro com borda colorida e brilho suave, base de todo o painel.
class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.child,
    this.color = AppColors.brand,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}
