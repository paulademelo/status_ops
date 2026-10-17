import 'package:flutter/material.dart';

import 'package:status_ops/data/models/workflow_run.dart';
import 'package:status_ops/ui/core/formatters.dart';
import 'package:status_ops/ui/core/run_state_look.dart';
import 'package:status_ops/ui/core/theme.dart';
import 'package:status_ops/ui/dashboard/dashboard_view_model.dart';
import 'package:status_ops/ui/dashboard/widgets/glow_card.dart';

/// Execuções do GitHub Actions, consultadas ao vivo pela API.
class RecentRunsPanel extends StatelessWidget {
  const RecentRunsPanel({super.key, required this.viewModel});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final error = viewModel.errorMessage;
    final quota = _quota();
    return GlowCard(
      color: colors.brand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Execuções ao vivo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: panelTitleStyle,
                ),
              ),
              IconButton(
                tooltip: 'Atualizar agora',
                onPressed: viewModel.isLoading ? null : viewModel.refresh,
                icon: Icon(Icons.refresh, color: colors.textMuted),
              ),
            ],
          ),
          _MutedLine(_subtitle()),
          if (quota != null) ...[const SizedBox(height: 2), _MutedLine(quota)],
          const SizedBox(height: 12),
          if (error != null) ...[
            _ErrorBox(message: error),
            const SizedBox(height: 12),
          ],
          ..._content(colors),
        ],
      ),
    );
  }

  /// Ex.: "Branch main · atualizado às 11:23 · próxima consulta às 11:24:10".
  String _subtitle() {
    if (!viewModel.hasLoaded) {
      return viewModel.isLoading
          ? 'Consultando a API do GitHub…'
          : 'Sem dados ao vivo ainda';
    }
    final parts = ['Branch main'];
    final updated = viewModel.lastUpdated;
    if (updated != null) {
      parts.add('atualizado às ${formatClock(updated)}');
    }
    final next = viewModel.nextRefreshAt;
    if (next != null) {
      parts.add('próxima consulta às ${formatClock(next, withSeconds: true)}');
    }
    return parts.join(' · ');
  }

  /// Ex.: "API do GitHub: 43 de 60 requisições restantes nesta hora".
  String? _quota() {
    final limit = viewModel.rateLimit;
    if (limit == null) {
      return null;
    }
    return 'API do GitHub: ${limit.remaining} de ${limit.limit} '
        'requisições restantes nesta hora';
  }

  List<Widget> _content(AppPalette colors) {
    if (!viewModel.hasLoaded) {
      if (!viewModel.isLoading) {
        return const [];
      }
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ];
    }
    final runs = viewModel.runs;
    if (runs.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: _MutedLine('Nenhuma execução encontrada na main ainda.'),
        ),
      ];
    }
    return [
      for (var i = 0; i < runs.length; i++) ...[
        if (i > 0) Divider(height: 1, color: colors.border),
        _RunTile(
          run: runs[i],
          now: viewModel.now,
          isCurrentBuild: viewModel.isCurrentBuild(runs[i]),
          onTap: () => viewModel.openLink(runs[i].htmlUrl),
        ),
      ],
    ];
  }
}

class _MutedLine extends StatelessWidget {
  const _MutedLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12, color: context.colors.textMuted),
    );
  }
}

/// Uma execução. Clicar abre a página dela no GitHub Actions.
class _RunTile extends StatelessWidget {
  const _RunTile({
    required this.run,
    required this.now,
    required this.isCurrentBuild,
    required this.onTap,
  });

  final WorkflowRun run;
  final DateTime now;
  final bool isCurrentBuild;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final look = RunStateLook.of(run.state, colors);
    final duration = run.duration;
    final details = [
      look.label,
      run.shortSha,
      if (run.actor.isNotEmpty) run.actor,
      timeAgo(run.createdAt, now),
      if (duration != null) formatDuration(duration),
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              look.icon,
              color: look.color,
              size: 20,
              semanticLabel: look.label,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${run.runNumber}  ${run.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _MutedLine(details),
                ],
              ),
            ),
            if (isCurrentBuild) ...[
              const SizedBox(width: 8),
              const _CurrentBuildTag(),
            ],
            const SizedBox(width: 8),
            Icon(Icons.open_in_new, size: 16, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Marca a execução que gerou a página aberta agora.
class _CurrentBuildTag extends StatelessWidget {
  const _CurrentBuildTag();

  @override
  Widget build(BuildContext context) {
    final success = context.colors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'no ar',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: success,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final failure = context.colors.failure;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: failure.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: failure.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: failure),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
