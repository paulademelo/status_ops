import 'package:flutter/material.dart';

import 'package:status_ops/config.dart';
import 'package:status_ops/ui/core/formatters.dart';
import 'package:status_ops/ui/core/theme.dart';
import 'package:status_ops/ui/core/theme_controller.dart';
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
  const DashboardScreen({
    super.key,
    required this.viewModel,
    required this.themeController,
  });

  final DashboardViewModel viewModel;
  final ThemeController themeController;

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
            TopBar(
              isProduction: viewModel.buildInfo.isFromPipeline,
              themeController: themeController,
            ),
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
                          context.colors,
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

  Widget _buildContent(AppPalette colors, {required bool isWide}) {
    final buildInfo = viewModel.buildInfo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        const SizedBox(height: 24),
        StatusBanner(viewModel: viewModel),
        const SizedBox(height: _gap),
        _ResponsiveRow(isWide: isWide, children: _metricCards(colors)),
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

  List<Widget> _metricCards(AppPalette colors) {
    final info = viewModel.buildInfo;
    final hasTests = info.hasTestResults;
    final successRate = viewModel.successRate;
    final averageDuration = viewModel.averageDuration;

    return [
      MetricCard(
        title: 'Saúde do Pipeline',
        icon: Icons.monitor_heart_outlined,
        color: colors.brand,
        values: [
          MetricValue(
            value: successRate == null
                ? '—'
                : '${(successRate * 100).round()}%',
            label: 'Sucesso',
            color: _successColor(successRate, colors),
          ),
          MetricValue(
            value: averageDuration == null
                ? '—'
                : formatDuration(averageDuration),
            label: 'Duração média',
            color: colors.textPrimary,
          ),
          MetricValue(
            value: viewModel.hasLoaded ? '${viewModel.runs.length}' : '—',
            label: 'Execuções',
            color: colors.textPrimary,
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
        color: colors.success,
        values: [
          MetricValue(
            value: hasTests ? '${(info.testPassRate * 100).round()}%' : '—',
            label: 'Passando',
          ),
          MetricValue(
            value: hasTests ? '${info.testsTotal}' : '—',
            label: 'Testes',
            color: colors.textPrimary,
          ),
          MetricValue(
            value: hasTests ? '${info.testsFailed}' : '—',
            label: 'Falhas',
            color: info.testsFailed > 0 ? colors.failure : colors.textMuted,
          ),
        ],
        footer: info.isFromPipeline
            ? 'Se algum teste falhar, o deploy é cancelado'
            : 'Rodando fora do pipeline',
      ),
      MetricCard(
        title: 'Versão da Aplicação',
        icon: Icons.verified_outlined,
        color: colors.accent,
        values: [
          MetricValue(
            value: appVersion,
            label: 'Em produção',
            color: colors.textPrimary,
          ),
        ],
        footer: 'Último deploy: ${info.buildDate}',
      ),
    ];
  }

  /// Cor de sucesso acima de 80%, de atenção abaixo.
  static Color _successColor(double? rate, AppPalette colors) {
    if (rate == null) {
      return colors.textMuted;
    }
    return rate >= 0.8 ? colors.success : colors.warning;
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Painel de Deploy · $projectName',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Flutter Web publicado automaticamente com GitHub Actions + '
          'GitHub Pages',
          style: TextStyle(fontSize: 15, color: context.colors.textMuted),
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
    final colors = context.colors;
    final style = TextStyle(fontSize: 13, color: colors.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(color: colors.border),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 16,
          runSpacing: 8,
          children: [
            Text('Flutter StatusOps · laboratório de CI/CD', style: style),
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
