import 'package:flutter/material.dart';

import 'package:status_ops/data/models/pipeline_job.dart';
import 'package:status_ops/data/models/workflow_run.dart';
import 'package:status_ops/ui/core/formatters.dart';
import 'package:status_ops/ui/core/run_state_look.dart';
import 'package:status_ops/ui/core/theme.dart';
import 'package:status_ops/ui/dashboard/dashboard_view_model.dart';
import 'package:status_ops/ui/dashboard/widgets/glow_card.dart';

/// Etapas (jobs) da execução em foco, ao vivo: durante um deploy dá para
/// ver cada job acendendo e qual passo está rodando agora.
class PipelinePanel extends StatelessWidget {
  const PipelinePanel({super.key, required this.viewModel});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final run = viewModel.focusRun;
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
              if (run != null) ...[
                const SizedBox(width: 8),
                Text(
                  'execução #${run.runNumber}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle(run),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          ..._content(run),
        ],
      ),
    );
  }

  String _subtitle(WorkflowRun? run) {
    if (run == null) {
      return 'Aguardando dados da API do GitHub';
    }
    final look = RunStateLook.of(run.state);
    return '${look.label} · ${run.title}';
  }

  List<Widget> _content(WorkflowRun? run) {
    if (run == null) {
      return const [
        _EmptyMessage('As etapas aparecem quando houver uma execução.'),
      ];
    }
    final jobs = viewModel.jobs;
    if (jobs.isEmpty) {
      return [
        _EmptyMessage(
          run.isActive
              ? 'Na fila: aguardando uma máquina do GitHub…'
              : 'Nenhum job encontrado nesta execução.',
        ),
      ];
    }
    return [
      for (final job in jobs)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _JobTile(
            job: job,
            onTap: () => viewModel.openLink(job.htmlUrl),
          ),
        ),
    ];
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job, required this.onTap});

  final PipelineJob job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final look = RunStateLook.of(job.state);
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: look.color.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: look.color.withValues(alpha: 0.15),
                ),
                child: Icon(
                  look.icon,
                  size: 18,
                  color: look.color,
                  semanticLabel: look.label,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.name,
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
                      _detail(look),
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
              const Icon(
                Icons.open_in_new,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ex.: "Rodando: 🧪 Rodar testes · passo 6 de 9" ou "Sucesso · 1m 40s".
  String _detail(RunStateLook look) {
    if (job.state == RunState.inProgress) {
      final step = job.currentStep?.name ?? 'preparando';
      final position = job.finishedSteps + 1;
      return 'Rodando: $step · passo $position de ${job.steps.length}';
    }
    final duration = job.duration;
    if (duration == null) {
      return look.label;
    }
    return '${look.label} · ${formatDuration(duration)}';
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
      ),
    );
  }
}
