import 'package:flutter/material.dart';

import 'package:status_ops/config.dart';
import 'package:status_ops/ui/core/formatters.dart';
import 'package:status_ops/ui/core/theme.dart';
import 'package:status_ops/ui/dashboard/dashboard_view_model.dart';
import 'package:status_ops/ui/dashboard/widgets/glow_card.dart';

/// Banner principal: status do ambiente + dados do build + avisos ao vivo.
///
/// Em telas largas fica compacto (status à esquerda, detalhes à direita).
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.viewModel});

  final DashboardViewModel viewModel;

  static const double _wideBreakpoint = 640;

  @override
  Widget build(BuildContext context) {
    final isProduction = viewModel.buildInfo.isFromPipeline;
    return GlowCard(
      color: isProduction ? AppColors.green : AppColors.orange,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _wideBreakpoint) {
                return Column(
                  children: [
                    _Headline(isProduction: isProduction, centered: true),
                    const SizedBox(height: 16),
                    _BuildDetails(viewModel: viewModel, centered: true),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _Headline(isProduction: isProduction),
                  ),
                  const SizedBox(width: 24),
                  Expanded(flex: 3, child: _BuildDetails(viewModel: viewModel)),
                ],
              );
            },
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
        const SizedBox(height: 16),
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
      final next = viewModel.isReloadScheduled
          ? 'Atualizando a página em instantes…'
          : 'Recarregue a página para ver.';
      return [
        const SizedBox(height: 16),
        _Callout(
          icon: Icons.new_releases_outlined,
          color: AppColors.cyan,
          title: 'Nova versão publicada!',
          message: 'O commit ${run.shortSha} já está no ar. $next',
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

/// "ONLINE" (publicado pelo pipeline) ou "LOCAL" (flutter run).
class _Headline extends StatelessWidget {
  const _Headline({required this.isProduction, this.centered = false});

  final bool isProduction;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final color = isProduction ? AppColors.green : AppColors.orange;
    final align = centered ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          isProduction ? 'Ambiente de Produção' : 'Ambiente Local',
          textAlign: align,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          isProduction ? 'ONLINE' : 'LOCAL',
          textAlign: align,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isProduction
              ? statusMessage
              : 'Rodando com flutter run: os dados do build só existem '
                    'quando o pipeline publica.',
          textAlign: align,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

/// Commit, autor, data e mensagem do build aberto no navegador.
class _BuildDetails extends StatelessWidget {
  const _BuildDetails({required this.viewModel, this.centered = false});

  final DashboardViewModel viewModel;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final buildInfo = viewModel.buildInfo;
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.end,
      children: [
        Wrap(
          alignment: centered ? WrapAlignment.center : WrapAlignment.end,
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
        const SizedBox(height: 10),
        Text(
          buildInfo.commitMessage,
          textAlign: centered ? TextAlign.center : TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ],
    );
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
