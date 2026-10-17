import 'package:flutter/material.dart';

import 'package:status_ops/build_info.dart';
import 'package:status_ops/theme.dart';
import 'package:status_ops/widgets/glow_card.dart';

/// Uma etapa do workflow `.github/workflows/ci_cd.yml`.
class PipelineStage {
  const PipelineStage({
    required this.title,
    required this.command,
    required this.icon,
  });

  final String title;
  final String command;
  final IconData icon;
}

/// Lista as etapas do pipeline. Se o app está no ar, todas passaram!
class PipelinePanel extends StatelessWidget {
  const PipelinePanel({super.key, required this.buildInfo});

  final BuildInfo buildInfo;

  static const List<PipelineStage> stages = [
    PipelineStage(
      title: 'Checkout do código',
      command: 'actions/checkout',
      icon: Icons.download_outlined,
    ),
    PipelineStage(
      title: 'Formatação e análise',
      command: 'dart format · flutter analyze',
      icon: Icons.rule,
    ),
    PipelineStage(
      title: 'Testes automatizados',
      command: 'flutter test',
      icon: Icons.science_outlined,
    ),
    PipelineStage(
      title: 'Build de produção',
      command: 'flutter build web --release',
      icon: Icons.construction,
    ),
    PipelineStage(
      title: 'Deploy',
      command: 'GitHub Pages',
      icon: Icons.cloud_upload_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final done = buildInfo.isFromPipeline;
    return GlowCard(
      color: AppColors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Etapas do Pipeline',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: panelTitleStyle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                done ? 'run #${buildInfo.runNumber}' : 'aguardando CI',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final stage in stages)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StageTile(stage: stage, done: done),
            ),
        ],
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({required this.stage, required this.done});

  final PipelineStage stage;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.green : AppColors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(stage.icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stage.command,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            done ? Icons.check_circle : Icons.schedule,
            size: 20,
            color: color,
            semanticLabel: done ? 'Concluído' : 'Pendente',
          ),
        ],
      ),
    );
  }
}
