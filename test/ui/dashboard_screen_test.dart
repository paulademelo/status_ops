import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:status_ops/config.dart';
import 'package:status_ops/data/build_info.dart';
import 'package:status_ops/data/models/runs_page.dart';
import 'package:status_ops/data/pipeline_repository.dart';
import 'package:status_ops/main.dart';
import 'package:status_ops/ui/dashboard/dashboard_view_model.dart';

import '../fakes/fake_pipeline_repository.dart';

/// Simula a página publicada pelo pipeline (commit abc1234, execução #5).
const pipelineBuild = BuildInfo(
  commitSha: 'abc1234',
  commitMessage: 'feat: painel ao vivo',
  commitAuthor: 'Paula',
  runNumber: '5',
  buildDate: '17/10/2026 10:30',
  testsPassed: 3,
  testsTotal: 3,
);

/// Monta o app com dados falsos já carregados (sem timers, sem internet).
Future<DashboardViewModel> pumpDashboard(
  WidgetTester tester, {
  required FakePipelineRepository repository,
  BuildInfo buildInfo = pipelineBuild,
  Size size = const Size(1280, 1200),
  PageReloader? reloadPage,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final viewModel = DashboardViewModel(
    repository: repository,
    buildInfo: buildInfo,
    clock: () => fixedNow,
    reloadPage: reloadPage,
  );
  addTearDown(viewModel.dispose);
  await viewModel.load();

  await tester.pumpWidget(StatusOpsApp(viewModel: viewModel));
  return viewModel;
}

void main() {
  testWidgets('mostra projeto, versão e ambiente online', (tester) async {
    await pumpDashboard(
      tester,
      repository: FakePipelineRepository(runs: [fakeRun(runNumber: 5)]),
    );

    expect(find.textContaining(projectName), findsWidgets);
    expect(find.text(appVersion), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);
    expect(find.text(statusMessage), findsOneWidget);
    expect(find.textContaining('Deploy em andamento'), findsNothing);
  });

  testWidgets('lista as execuções ao vivo e marca a que está no ar', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      repository: FakePipelineRepository(
        runs: [
          fakeRun(runNumber: 5, title: 'feat: painel ao vivo'),
          fakeRun(runNumber: 4, conclusion: 'failure', sha: 'fff0000xxxx'),
        ],
      ),
    );

    expect(find.text('#5  feat: painel ao vivo'), findsOneWidget);
    expect(find.text('no ar'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget); // 1 sucesso em 2
    expect(find.byTooltip('Atualizar agora'), findsOneWidget);
  });

  testWidgets('avisa quando um deploy está em andamento', (tester) async {
    await pumpDashboard(
      tester,
      repository: FakePipelineRepository(
        runs: [
          fakeRun(runNumber: 6, status: 'in_progress', sha: 'def5678xxxx'),
          fakeRun(runNumber: 5),
        ],
      ),
    );

    expect(find.text('Deploy em andamento · execução #6'), findsOneWidget);
  });

  testWidgets('avisa quando existe uma versão mais nova no ar', (tester) async {
    await pumpDashboard(
      tester,
      repository: FakePipelineRepository(
        runs: [
          fakeRun(runNumber: 6, sha: 'def5678xxxx'),
          fakeRun(runNumber: 5),
        ],
      ),
    );

    expect(find.text('Nova versão publicada!'), findsOneWidget);
  });

  testWidgets('botão "Recarregar página" recarrega', (tester) async {
    var reloads = 0;
    await pumpDashboard(
      tester,
      repository: FakePipelineRepository(
        runs: [
          fakeRun(runNumber: 6, sha: 'def5678xxxx'),
          fakeRun(runNumber: 5),
        ],
      ),
      reloadPage: () async => reloads++,
    );

    await tester.tap(find.text('Recarregar página'));
    await tester.pump();

    expect(reloads, 1);
  });

  testWidgets('mostra o saldo de requisições da API', (tester) async {
    await pumpDashboard(
      tester,
      repository: FakePipelineRepository(
        runs: [fakeRun(runNumber: 5)],
        rateLimit: RateLimit(
          limit: 60,
          remaining: 43,
          resetAt: fixedNow.add(const Duration(minutes: 30)),
        ),
      ),
    );

    expect(find.textContaining('43 de 60'), findsOneWidget);
  });

  testWidgets('mostra o erro da API sem quebrar a tela', (tester) async {
    await pumpDashboard(
      tester,
      repository: FakePipelineRepository(
        error: const PipelineException('Sem conexão com a API do GitHub.'),
      ),
    );

    expect(find.text('Sem conexão com a API do GitHub.'), findsOneWidget);
    expect(find.text('Sem dados ao vivo ainda'), findsOneWidget);
    expect(find.text('ONLINE'), findsOneWidget);
  });

  testWidgets('build local avisa que está fora do pipeline', (tester) async {
    await pumpDashboard(
      tester,
      repository: FakePipelineRepository(runs: [fakeRun()]),
      buildInfo: const BuildInfo(),
    );

    expect(find.text('Rodando fora do pipeline'), findsOneWidget);
  });

  testWidgets('layout se adapta ao celular sem overflow', (tester) async {
    await pumpDashboard(
      tester,
      repository: FakePipelineRepository(
        runs: [
          fakeRun(runNumber: 6, status: 'in_progress', sha: 'def5678xxxx'),
          fakeRun(runNumber: 5),
        ],
      ),
      size: const Size(390, 844),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(appVersion), findsOneWidget);
  });
}
