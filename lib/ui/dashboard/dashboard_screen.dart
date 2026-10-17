import 'package:flutter/material.dart';

import 'package:status_ops/config.dart';
import 'package:status_ops/ui/core/formatters.dart';
import 'package:status_ops/ui/core/theme.dart';
import 'package:status_ops/ui/dashboard/dashboard_view_model.dart';
import 'package:status_ops/ui/dashboard/widgets/metric_card.dart';
import 'package:status_ops/ui/dashboard/widgets/pipeline_panel.dart';
import 'package:status_ops/ui/dashboard/widgets/recent_runs_panel.dart';
import 'package:status_ops/ui/dashboard/widgets/run_trend.dart';
import 'package:status_ops/ui/dashboard/widgets/status_banner.dart';
import 'package:status_ops/ui/dashboard/widgets/top_bar.dart';

const double _gap = 20;

/// Tela do painel. Não guarda estado nem regras: só desenha o que o
/// [DashboardViewModel] expõe e se redesenha quando ele avisa que mudou.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.viewModel});

  final DashboardViewModel viewModel;

  /// A partir desta largura os cards ficam lado a lado.
  static const double wideBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return _PauseWhenHidden(viewModel: viewModel, child: _buildScaffold());
  }

  Widget _buildScaffold() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(isProduction: viewModel.buildInfo.isFromPipeline),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    // ListenableBuilder reconstrói o conteúdo a cada
                    // notifyListeners() do ViewModel.
                    child: ListenableBuilder(
                      listenable: viewModel,
                      builder: (context, _) => LayoutBuilder(
                        builder: (context, constraints) => _buildContent(
                          isWide: constraints.maxWidth >= wideBreakpoint,
                        ),
                      ),
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

  Widget _buildContent({required bool isWide}) {
    final buildInfo = viewModel.buildInfo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        const SizedBox(height: 24),
        StatusBanner(viewModel: viewModel),
        const SizedBox(height: _gap),
        _ResponsiveRow(isWide: isWide, children: _metricCards()),
        const SizedBox(height: _gap),
        _ResponsiveRow(
          isWide: isWide,
          flexes: const [2, 3],
          children: [
            PipelinePanel(viewModel: viewModel),
            RecentRunsPanel(viewModel: viewModel),
          ],
        ),
        const SizedBox(height: 32),
        _Footer(runNumber: buildInfo.runNumber, commitSha: buildInfo.commitSha),
      ],
    );
  }

  List<Widget> _metricCards() {
    final info = viewModel.buildInfo;
    final hasTests = info.hasTestResults;
    final successRate = viewModel.successRate;
    final averageDuration = viewModel.averageDuration;

    return [
      MetricCard(
        title: 'Saúde do Pipeline',
        icon: Icons.monitor_heart_outlined,
        color: AppColors.brand,
        values: [
          MetricValue(
            value: successRate == null
                ? '—'
                : '${(successRate * 100).round()}%',
            label: 'Sucesso',
            color: _successColor(successRate),
          ),
          MetricValue(
            value: averageDuration == null
                ? '—'
                : formatDuration(averageDuration),
            label: 'Duração média',
            color: AppColors.textPrimary,
          ),
          MetricValue(
            value: viewModel.hasLoaded ? '${viewModel.runs.length}' : '—',
            label: 'Execuções',
            color: AppColors.textPrimary,
          ),
        ],
        extra: viewModel.runs.isEmpty ? null : RunTrend(runs: viewModel.trend),
        footer: viewModel.hasLoaded
            ? 'Ao vivo · últimas execuções na main'
            : 'Aguardando dados da API do GitHub',
      ),
      MetricCard(
        title: 'Testes Automatizados',
        icon: Icons.fact_check_outlined,
        color: AppColors.success,
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
                ? AppColors.failure
                : AppColors.textMuted,
          ),
        ],
        footer: info.isFromPipeline
            ? 'Se algum teste falhar, o deploy é cancelado'
            : 'Rodando fora do pipeline',
      ),
      MetricCard(
        title: 'Versão da Aplicação',
        icon: Icons.verified_outlined,
        color: AppColors.accent,
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

  /// Verde acima de 80%, laranja abaixo.
  static Color _successColor(double? rate) {
    if (rate == null) {
      return AppColors.textMuted;
    }
    return rate >= 0.8 ? AppColors.success : AppColors.warning;
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
  const _Footer({required this.runNumber, required this.commitSha});

  final String runNumber;
  final String commitSha;

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
            const Text(
              'Flutter StatusOps · laboratório de CI/CD',
              style: style,
            ),
            Text('build $runNumber · commit $commitSha', style: style),
          ],
        ),
      ],
    );
  }
}

/// Pausa as consultas quando a aba vai para segundo plano e retoma (já
/// atualizando) quando ela volta. Economiza o limite da API.
class _PauseWhenHidden extends StatefulWidget {
  const _PauseWhenHidden({required this.viewModel, required this.child});

  final DashboardViewModel viewModel;
  final Widget child;

  @override
  State<_PauseWhenHidden> createState() => _PauseWhenHiddenState();
}

class _PauseWhenHiddenState extends State<_PauseWhenHidden> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onHide: widget.viewModel.pause,
      onShow: widget.viewModel.resume,
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
