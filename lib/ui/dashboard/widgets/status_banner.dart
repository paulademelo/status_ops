import 'package:flutter/material.dart';

import 'package:status_ops/config.dart';
import 'package:status_ops/ui/core/formatters.dart';
import 'package:status_ops/ui/core/theme.dart';
import 'package:status_ops/ui/dashboard/dashboard_view_model.dart';
import 'package:status_ops/ui/dashboard/widgets/glow_card.dart';

/// Banner principal: ambiente ONLINE + dados do build + avisos ao vivo.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.viewModel});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final buildInfo = viewModel.buildInfo;
    return GlowCard(
      color: AppColors.green,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Status do Ambiente de Produção',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          const Text(
            'ONLINE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.commit, label: buildInfo.commitSha),
              _InfoChip(
                icon: Icons.person_outline,
                label: buildInfo.commitAuthor,
              ),
              _InfoChip(icon: Icons.schedule, label: buildInfo.buildDate),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            buildInfo.commitMessage,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          ..._liveCallout(),
        ],
      ),
    );
  }

  /// Aviso ao vivo, vindo da API do GitHub (some quando está tudo em dia).
  List<Widget> _liveCallout() {
    final status = viewModel.panelStatus;

    if (status == PanelStatus.deploying) {
      final run = viewModel.activeRun!;
      return [
        const SizedBox(height: 20),
        _Callout(
          icon: Icons.sync,
          color: AppColors.orange,
          title: 'Deploy em andamento · execução #${run.runNumber}',
          message:
              '"${run.title}" · iniciada '
              '${timeAgo(run.createdAt, viewModel.now)}',
        ),
      ];
    }

    if (status == PanelStatus.newVersionAvailable) {
      final run = viewModel.latestSuccessfulRun!;
      return [
        const SizedBox(height: 20),
        _Callout(
          icon: Icons.new_releases_outlined,
          color: AppColors.cyan,
          title: 'Nova versão publicada!',
          message: viewModel.isReloadScheduled
              ? 'O commit ${run.shortSha} já está no ar. Atualizando a '
                    'página em instantes…'
              : 'O commit ${run.shortSha} já está no ar. Recarregue a '
                    'página para ver.',
          action: TextButton.icon(
            onPressed: viewModel.reloadNow,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Recarregar página'),
            style: TextButton.styleFrom(foregroundColor: AppColors.cyan),
          ),
        ),
      ];
    }

    return const [];
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  /// Botão opcional exibido abaixo da mensagem.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (action != null) ...[const SizedBox(height: 4), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
