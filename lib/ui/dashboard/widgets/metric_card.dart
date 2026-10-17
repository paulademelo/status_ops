import 'package:flutter/material.dart';

import 'package:status_ops/ui/core/theme.dart';
import 'package:status_ops/ui/dashboard/widgets/glow_card.dart';

/// Um número de destaque dentro de um [MetricCard].
class MetricValue {
  const MetricValue({required this.value, required this.label, this.color});

  final String value;
  final String label;

  /// Cor do número. Quando nula, usa a cor do card.
  final Color? color;
}

/// Card de métrica no estilo "KPI": título, ícone e até 3 valores.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.values,
    required this.footer,
    this.extra,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<MetricValue> values;
  final String footer;

  /// Widget opcional exibido entre os valores e o rodapé.
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: panelTitleStyle,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final metric in values)
                Expanded(
                  child: _MetricValueView(metric: metric, color: color),
                ),
            ],
          ),
          if (extra != null) ...[const SizedBox(height: 16), extra!],
          const SizedBox(height: 16),
          Text(
            footer,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: context.colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _MetricValueView extends StatelessWidget {
  const _MetricValueView({required this.metric, required this.color});

  final MetricValue metric;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            metric.value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: metric.color ?? color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: context.colors.textMuted),
        ),
      ],
    );
  }
}
