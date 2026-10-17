import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:status_ops/data/build_info.dart';
import 'package:status_ops/data/models/workflow_run.dart';
import 'package:status_ops/data/pipeline_repository.dart';
import 'package:status_ops/ui/core/formatters.dart';

/// Situação geral exibida no banner do painel.
enum PanelStatus {
  /// Tudo tranquilo: a versão aberta é a mais recente.
  online,

  /// Existe uma execução do pipeline na fila ou rodando agora.
  deploying,

  /// Um deploy mais novo terminou depois que esta página foi aberta.
  newVersionAvailable,
}

/// Estado e regras do painel.
///
/// A tela só lê os getters e chama [refresh]. Toda decisão (quando
/// atualizar, o que é "nova versão", como calcular a taxa de sucesso) mora
/// aqui, e por isso pode ser testada sem montar nenhum widget.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required this._repository,
    required this.buildInfo,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Intervalo normal entre consultas (cabe no limite de 60/h da API).
  static const Duration idleInterval = Duration(minutes: 2);

  /// Com um deploy rodando, atualiza mais rápido para acompanhar.
  static const Duration activeInterval = Duration(seconds: 30);

  /// Depois de um erro comum, tenta de novo em 1 minuto.
  static const Duration errorInterval = Duration(minutes: 1);

  final PipelineRepository _repository;
  final DateTime Function() _clock;

  /// Dados "congelados" na compilação (commit, testes, versão).
  final BuildInfo buildInfo;

  List<WorkflowRun> _runs = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  DateTime? _lastUpdated;
  DateTime? _rateLimitResetAt;
  Timer? _timer;
  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Estado
  // ---------------------------------------------------------------------------

  List<WorkflowRun> get runs => _runs;

  bool get isLoading => _isLoading;

  /// Já recebemos dados da API pelo menos uma vez.
  bool get hasLoaded => _hasLoaded;

  /// Mensagem do último erro. Os dados anteriores continuam em [runs].
  String? get errorMessage => _errorMessage;

  DateTime? get lastUpdated => _lastUpdated;

  DateTime get now => _clock();

  // ---------------------------------------------------------------------------
  // Ações
  // ---------------------------------------------------------------------------

  /// Primeira carga + atualização automática. Chame uma vez ao abrir o app.
  void start() {
    unawaited(_loadAndSchedule());
  }

  /// Atualiza agora (botão de refresh) e reinicia o relógio.
  Future<void> refresh() => _loadAndSchedule();

  /// Busca as execuções uma vez, sem agendar a próxima.
  Future<void> load() async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    _notify();

    try {
      _runs = await _repository.fetchRecentRuns();
      _hasLoaded = true;
      _errorMessage = null;
      _rateLimitResetAt = null;
      _lastUpdated = _clock();
    } on RateLimitException catch (error) {
      _rateLimitResetAt = error.resetAt;
      _errorMessage =
          'Limite da API do GitHub atingido. Nova tentativa às '
          '${formatClock(error.resetAt)}.';
    } on PipelineException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> _loadAndSchedule() async {
    _timer?.cancel();
    await load();
    if (_disposed) {
      return;
    }
    _timer = Timer(nextRefreshDelay, () => unawaited(_loadAndSchedule()));
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Regras
  // ---------------------------------------------------------------------------

  /// Quanto esperar até a próxima consulta à API.
  Duration get nextRefreshDelay {
    final resetAt = _rateLimitResetAt;
    if (resetAt != null) {
      final wait = resetAt.difference(_clock());
      return wait.isNegative
          ? errorInterval
          : wait + const Duration(seconds: 5);
    }
    if (_errorMessage != null) {
      return errorInterval;
    }
    return activeRun != null ? activeInterval : idleInterval;
  }

  /// Execução na fila ou rodando agora (a mais recente).
  WorkflowRun? get activeRun => _firstWhere((run) => run.isActive);

  /// Último deploy que terminou com sucesso.
  WorkflowRun? get latestSuccessfulRun =>
      _firstWhere((run) => run.state == RunState.success);

  /// Execuções que terminaram com sucesso ou falha. Canceladas e puladas
  /// não entram na conta: ninguém errou ali.
  List<WorkflowRun> get finishedRuns => _runs
      .where(
        (run) => run.state == RunState.success || run.state == RunState.failure,
      )
      .toList();

  /// De 0 a 1. `null` quando ainda não há execuções terminadas.
  double? get successRate {
    final finished = finishedRuns;
    if (finished.isEmpty) {
      return null;
    }
    final successes = finished.where((run) => run.state == RunState.success);
    return successes.length / finished.length;
  }

  /// Duração média das execuções com sucesso.
  Duration? get averageDuration {
    final durations = [
      for (final run in _runs)
        if (run.state == RunState.success && run.duration != null)
          run.duration!,
    ];
    if (durations.isEmpty) {
      return null;
    }
    final total = durations.fold(Duration.zero, (sum, d) => sum + d);
    return Duration(microseconds: total.inMicroseconds ~/ durations.length);
  }

  /// O último deploy com sucesso é de outro commit, diferente do que foi
  /// compilado nesta página? Então existe uma versão mais nova no ar.
  bool get hasNewerDeploy {
    final latest = latestSuccessfulRun;
    if (latest == null || !buildInfo.isFromPipeline) {
      return false;
    }
    return !latest.headSha.startsWith(buildInfo.commitSha);
  }

  /// Esta execução publicou a versão aberta no navegador?
  bool isCurrentBuild(WorkflowRun run) =>
      buildInfo.isFromPipeline &&
      run.state == RunState.success &&
      run.headSha.startsWith(buildInfo.commitSha);

  PanelStatus get panelStatus {
    if (activeRun != null) {
      return PanelStatus.deploying;
    }
    if (hasNewerDeploy) {
      return PanelStatus.newVersionAvailable;
    }
    return PanelStatus.online;
  }

  WorkflowRun? _firstWhere(bool Function(WorkflowRun run) test) {
    for (final run in _runs) {
      if (test(run)) {
        return run;
      }
    }
    return null;
  }
}
