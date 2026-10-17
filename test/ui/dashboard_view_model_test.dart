import 'package:flutter_test/flutter_test.dart';

import 'package:status_ops/data/build_info.dart';
import 'package:status_ops/data/models/runs_page.dart';
import 'package:status_ops/data/pipeline_repository.dart';
import 'package:status_ops/ui/dashboard/dashboard_view_model.dart';

import '../fakes/fake_pipeline_repository.dart';

/// Simula a página que foi publicada pelo commit abc1234.
const deployedBuild = BuildInfo(
  commitSha: 'abc1234',
  runNumber: '5',
  testsPassed: 3,
  testsTotal: 3,
);

DashboardViewModel buildViewModel(
  FakePipelineRepository repository, {
  BuildInfo buildInfo = deployedBuild,
}) {
  return DashboardViewModel(
    repository: repository,
    buildInfo: buildInfo,
    clock: () => fixedNow,
  );
}

void main() {
  group('Carregamento', () {
    test('carrega as execuções e avisa a tela', () async {
      final repository = FakePipelineRepository(runs: [fakeRun()]);
      final viewModel = buildViewModel(repository);
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.load();

      expect(viewModel.hasLoaded, isTrue);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.runs, hasLength(1));
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.lastUpdated, fixedNow);
      expect(notifications, 2); // começou a carregar + terminou
    });

    test('um erro mantém os dados anteriores na tela', () async {
      final repository = FakePipelineRepository(runs: [fakeRun()]);
      final viewModel = buildViewModel(repository);
      await viewModel.load();

      repository.error = const PipelineException('Sem conexão.');
      await viewModel.load();

      expect(viewModel.errorMessage, 'Sem conexão.');
      expect(viewModel.runs, hasLength(1));
      expect(viewModel.lastUpdated, fixedNow);
    });

    test('refresh busca de novo e dispose cancela o agendamento', () async {
      final repository = FakePipelineRepository(runs: [fakeRun()]);
      final viewModel = buildViewModel(repository);

      await viewModel.refresh();
      expect(repository.calls, 1);

      viewModel.dispose();
    });
  });

  group('Métricas', () {
    test('taxa de sucesso ignora execuções canceladas', () async {
      final repository = FakePipelineRepository(
        runs: [
          fakeRun(runNumber: 4),
          fakeRun(runNumber: 3, conclusion: 'failure'),
          fakeRun(runNumber: 2, conclusion: 'cancelled'),
          fakeRun(runNumber: 1),
        ],
      );
      final viewModel = buildViewModel(repository);
      await viewModel.load();

      expect(viewModel.successRate, closeTo(2 / 3, 0.0001));
    });

    test('sem execuções terminadas não existe taxa de sucesso', () async {
      final repository = FakePipelineRepository(
        runs: [fakeRun(status: 'in_progress')],
      );
      final viewModel = buildViewModel(repository);
      await viewModel.load();

      expect(viewModel.successRate, isNull);
      expect(viewModel.averageDuration, isNull);
    });

    test('duração média considera só os deploys com sucesso', () async {
      final repository = FakePipelineRepository(
        runs: [
          fakeRun(runNumber: 3, runTime: const Duration(minutes: 2)),
          fakeRun(
            runNumber: 2,
            conclusion: 'failure',
            runTime: const Duration(minutes: 10),
          ),
          fakeRun(runNumber: 1, runTime: const Duration(minutes: 4)),
        ],
      );
      final viewModel = buildViewModel(repository);
      await viewModel.load();

      expect(viewModel.averageDuration, const Duration(minutes: 3));
    });
  });

  group('Status do painel', () {
    test('com execução rodando, mostra deploy em andamento', () async {
      final repository = FakePipelineRepository(
        runs: [
          fakeRun(runNumber: 6, status: 'in_progress', sha: 'def5678xxxxx'),
          fakeRun(runNumber: 5),
        ],
      );
      final viewModel = buildViewModel(repository);
      await viewModel.load();

      expect(viewModel.panelStatus, PanelStatus.deploying);
      expect(viewModel.activeRun?.runNumber, 6);
    });

    test('deploy mais novo terminado avisa que há nova versão', () async {
      final repository = FakePipelineRepository(
        runs: [
          fakeRun(runNumber: 6, sha: 'def5678xxxxx'),
          fakeRun(runNumber: 5),
        ],
      );
      final viewModel = buildViewModel(repository);
      await viewModel.load();

      expect(viewModel.panelStatus, PanelStatus.newVersionAvailable);
      expect(viewModel.isCurrentBuild(viewModel.runs[1]), isTrue);
      expect(viewModel.isCurrentBuild(viewModel.runs[0]), isFalse);
    });

    test('versão aberta é a mais recente: painel online', () async {
      final repository = FakePipelineRepository(runs: [fakeRun(runNumber: 5)]);
      final viewModel = buildViewModel(repository);
      await viewModel.load();

      expect(viewModel.panelStatus, PanelStatus.online);
    });

    test('build local nunca mostra "nova versão"', () async {
      final repository = FakePipelineRepository(
        runs: [fakeRun(sha: 'def5678xxxxx')],
      );
      final viewModel = buildViewModel(
        repository,
        buildInfo: const BuildInfo(),
      );
      await viewModel.load();

      expect(viewModel.hasNewerDeploy, isFalse);
      expect(viewModel.panelStatus, PanelStatus.online);
    });
  });

  group('Próxima atualização', () {
    RateLimit limit(int remaining, Duration resetIn) => RateLimit(
      limit: 60,
      remaining: remaining,
      resetAt: fixedNow.add(resetIn),
    );

    test('parado, sem info da API: intervalo mínimo', () async {
      final viewModel = buildViewModel(
        FakePipelineRepository(runs: [fakeRun()]),
      );
      await viewModel.load();

      expect(viewModel.nextRefreshDelay, DashboardViewModel.idleInterval);
    });

    test('parado com saldo folgado: intervalo mínimo', () async {
      final viewModel = buildViewModel(
        FakePipelineRepository(
          runs: [fakeRun()],
          rateLimit: limit(59, const Duration(minutes: 10)),
        ),
      );
      await viewModel.load();

      expect(viewModel.nextRefreshDelay, DashboardViewModel.idleInterval);
    });

    test('parado com saldo curto: divide o que sobrou até o reset', () async {
      // 15 restantes - 5 de reserva = 10 consultas em 20 min → 1 a cada 2 min.
      final viewModel = buildViewModel(
        FakePipelineRepository(
          runs: [fakeRun()],
          rateLimit: limit(15, const Duration(minutes: 20)),
        ),
      );
      await viewModel.load();

      expect(viewModel.nextRefreshDelay, const Duration(minutes: 2));
    });

    test('durante um deploy consulta a cada 15 s', () async {
      final viewModel = buildViewModel(
        FakePipelineRepository(
          runs: [fakeRun(status: 'queued')],
          rateLimit: limit(30, const Duration(minutes: 20)),
        ),
      );
      await viewModel.load();

      expect(viewModel.nextRefreshDelay, DashboardViewModel.activeInterval);
    });

    test('saldo acabando: espera o reset, mesmo com deploy rodando', () async {
      final viewModel = buildViewModel(
        FakePipelineRepository(
          runs: [fakeRun(status: 'in_progress')],
          rateLimit: limit(5, const Duration(minutes: 10)),
        ),
      );
      await viewModel.load();

      expect(
        viewModel.nextRefreshDelay,
        const Duration(minutes: 10, seconds: 5),
      );
    });

    test('1 min depois de um erro comum', () async {
      final viewModel = buildViewModel(
        FakePipelineRepository(error: const PipelineException('Falhou.')),
      );
      await viewModel.load();

      expect(viewModel.nextRefreshDelay, DashboardViewModel.errorInterval);
    });

    test('no limite da API, espera até o reset', () async {
      final resetAt = fixedNow.add(const Duration(minutes: 10));
      final viewModel = buildViewModel(
        FakePipelineRepository(error: RateLimitException(resetAt: resetAt)),
      );
      await viewModel.load();

      expect(viewModel.errorMessage, contains('Limite da API'));
      expect(
        viewModel.nextRefreshDelay,
        const Duration(minutes: 10, seconds: 5),
      );
    });
  });

  group('Segundo plano', () {
    test('ao voltar para a aba, atualiza na hora', () async {
      final repository = FakePipelineRepository(runs: [fakeRun()]);
      final viewModel = buildViewModel(repository);

      viewModel.pause();
      viewModel.resume();
      await Future<void>.delayed(Duration.zero);

      expect(repository.calls, 1);
      viewModel.dispose();
    });

    test('resume sem pause não faz nada', () async {
      final repository = FakePipelineRepository(runs: [fakeRun()]);
      final viewModel = buildViewModel(repository);

      viewModel.resume();
      await Future<void>.delayed(Duration.zero);

      expect(repository.calls, 0);
      viewModel.dispose();
    });
  });

  group('Recarregamento automático', () {
    final newerDeploy = [
      fakeRun(runNumber: 6, sha: 'def5678xxxxx'),
      fakeRun(runNumber: 5),
    ];

    DashboardViewModel buildReloading(
      FakePipelineRepository repository,
      void Function() onReload, {
      Duration? delay = const Duration(milliseconds: 10),
    }) {
      return DashboardViewModel(
        repository: repository,
        buildInfo: deployedBuild,
        clock: () => fixedNow,
        reloadPage: () async => onReload(),
        autoReloadDelay: delay,
      );
    }

    test('recarrega sozinho quando sai uma versão nova', () async {
      var reloads = 0;
      final viewModel = buildReloading(
        FakePipelineRepository(runs: newerDeploy),
        () => reloads++,
      );

      await viewModel.load();
      expect(viewModel.isReloadScheduled, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(reloads, 1);
      viewModel.dispose();
    });

    test('agenda o recarregamento uma vez só', () async {
      var reloads = 0;
      final viewModel = buildReloading(
        FakePipelineRepository(runs: newerDeploy),
        () => reloads++,
      );

      await viewModel.load();
      await viewModel.load();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(reloads, 1);
      viewModel.dispose();
    });

    test('não recarrega se a página já é a versão mais recente', () async {
      var reloads = 0;
      final viewModel = buildReloading(
        FakePipelineRepository(runs: [fakeRun(runNumber: 5)]),
        () => reloads++,
      );

      await viewModel.load();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(viewModel.isReloadScheduled, isFalse);
      expect(reloads, 0);
      viewModel.dispose();
    });

    test('sem autoReloadDelay, só recarrega pelo botão', () async {
      var reloads = 0;
      final viewModel = buildReloading(
        FakePipelineRepository(runs: newerDeploy),
        () => reloads++,
        delay: null,
      );

      await viewModel.load();
      expect(viewModel.isReloadScheduled, isFalse);

      await viewModel.reloadNow();
      expect(reloads, 1);
      viewModel.dispose();
    });
  });
}
