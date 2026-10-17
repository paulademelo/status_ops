import 'package:flutter/material.dart';

import 'package:status_ops/build_info.dart';
import 'package:status_ops/config.dart';
import 'package:status_ops/theme.dart';
import 'package:status_ops/widgets/commit_history_panel.dart';
import 'package:status_ops/widgets/metric_card.dart';
import 'package:status_ops/widgets/pipeline_panel.dart';
import 'package:status_ops/widgets/status_banner.dart';
import 'package:status_ops/widgets/top_bar.dart';

const double _gap = 20;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.buildInfo});

  final BuildInfo buildInfo;

  /// A partir desta largura os cards ficam lado a lado.
  static const double wideBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= wideBreakpoint;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _Header(),
                            const SizedBox(height: 24),
                            StatusBanner(buildInfo: buildInfo),
                            const SizedBox(height: _gap),
                            _ResponsiveRow(
                              isWide: isWide,
                              children: _metricCards(),
                            ),
                            const SizedBox(height: _gap),
                            _ResponsiveRow(
                              isWide: isWide,
                              flexes: const [2, 3],
                              children: [
                                PipelinePanel(buildInfo: buildInfo),
                                CommitHistoryPanel(
                                  commits: buildInfo.recentCommits,
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            _Footer(buildInfo: buildInfo),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _metricCards() {
    final info = buildInfo;
    final fromPipeline = info.isFromPipeline;
    final hasTests = info.hasTestResults;

    return [
      MetricCard(
        title: 'Status da Build',
        icon: Icons.rocket_launch_outlined,
        color: AppColors.cyan,
        values: [
          MetricValue(
            value: fromPipeline ? 'Sucesso' : 'Local',
            label: 'Resultado',
            color: fromPipeline ? AppColors.green : AppColors.orange,
          ),
          MetricValue(
            value: fromPipeline ? '#${info.runNumber}' : '—',
            label: 'Execução',
            color: AppColors.textPrimary,
          ),
        ],
        footer: fromPipeline
            ? 'Publicado pelo GitHub Actions'
            : 'Rodando fora do pipeline',
      ),
      MetricCard(
        title: 'Testes Automatizados',
        icon: Icons.fact_check_outlined,
        color: AppColors.green,
        values: [
          MetricValue(
            value: hasTests ? '${(info.testPassRate * 100).round()}%' : '—',
            label: 'Passando',
          ),
          MetricValue(
            value: hasTests ? '${info.testsTotal}' : '—',
            label: 'Testes',
            color: AppColors.textPrimary,
          ),
          MetricValue(
            value: hasTests ? '${info.testsFailed}' : '—',
            label: 'Falhas',
            color: info.testsFailed > 0
                ? AppColors.orange
                : AppColors.textMuted,
          ),
        ],
        footer: 'Se algum teste falhar, o deploy é cancelado',
      ),
      MetricCard(
        title: 'Versão da Aplicação',
        icon: Icons.verified_outlined,
        color: AppColors.orange,
        values: const [
          MetricValue(
            value: appVersion,
            label: 'Em produção',
            color: AppColors.textPrimary,
          ),
        ],
        footer: 'Último deploy: ${info.buildDate}',
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Painel de Deploy · $projectName',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Flutter Web publicado automaticamente com GitHub Actions + '
          'GitHub Pages',
          style: TextStyle(fontSize: 15, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// Coloca os filhos lado a lado em telas largas e empilhados no celular.
class _ResponsiveRow extends StatelessWidget {
  const _ResponsiveRow({
    required this.isWide,
    required this.children,
    this.flexes,
  });

  final bool isWide;
  final List<Widget> children;
  final List<int>? flexes;

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: _gap),
            children[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          Expanded(flex: flexes?[i] ?? 1, child: children[i]),
        ],
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.buildInfo});

  final BuildInfo buildInfo;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 13, color: AppColors.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(color: AppColors.border),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 16,
          runSpacing: 8,
          children: [
            const Text('Flutter StatusOps · laboratório de CI/CD', style: style),
            Text(
              'build ${buildInfo.runNumber} · commit ${buildInfo.commitSha}',
              style: style,
            ),
          ],
        ),
      ],
    );
  }
}
