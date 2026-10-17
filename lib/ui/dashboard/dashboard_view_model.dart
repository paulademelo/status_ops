import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:status_ops/data/build_info.dart';
import 'package:status_ops/data/models/runs_page.dart';
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

/// Função que recarrega a página (no navegador) ou não faz nada (testes).
typedef PageReloader = Future<void> Function();

Future<void> _doNothing() async {}

/// Estado e regras do painel.
///
/// A tela só lê os getters e chama as ações. Toda decisão (quando
/// atualizar, o que é "nova versão", como calcular a taxa de sucesso) mora
/// aqui, e por isso pode ser testada sem montar nenhum widget.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required this._repository,
    required this.buildInfo,
    PageReloader? reloadPage,
    this.autoReloadDelay,
    DateTime Function()? clock,
  }) : _reloadPage = reloadPage ?? _doNothing,
       _clock = clock ?? DateTime.now;

  /// Intervalo mínimo com o pipeline parado.
  static const Duration idleInterval = Duration(seconds: 45);

  /// Com um deploy rodando, consulta bem mais rápido para acompanhar.
  static const Duration activeInterval = Duration(seconds: 15);

  /// Depois de um erro comum, tenta de novo em 1 minuto.
  static const Duration errorInterval = Duration(minutes: 1);

  /// Requisições guardadas para o F5 e outras abas (o limite é por IP).
  static const int requestReserve = 5;

  final PipelineRepository _repository;
  final PageReloader _reloadPage;
  final DateTime Function() _clock;

  /// Dados "congelados" na compilação (commit, testes, versão).
  final BuildInfo buildInfo;

  /// Espera antes de recarregar sozinho quando sai uma versão nova.
  /// `null` desliga o recarregamento automático (usado nos testes).
  final Duration? autoReloadDelay;

  List<WorkflowRun> _runs = const [];
  RateLimit? _rateLimit;
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _paused = false;
  bool _reloadScheduled = false;
  String? _errorMessage;
  DateTime? _lastUpdated;
  DateTime? _rateLimitResetAt;
  Timer? _refreshTimer;
  Timer? _reloadTimer;
  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Estado
  // ---------------------------------------------------------------------------

  List<WorkflowRun> get runs => _runs;

  /// Saldo de requisições da API na última resposta.
  RateLimit? get rateLimit => _rateLimit;

  bool get isLoading => _isLoading;

  /// Já recebemos dados da API pelo menos uma vez.
  bool get hasLoaded => _hasLoaded;

  /// Mensagem do último erro. Os dados anteriores continuam em [runs].
  String? get errorMessage => _errorMessage;

  DateTime? get lastUpdated => _lastUpdated;

  /// A página vai se recarregar sozinha em instantes.
  bool get isReloadScheduled => _reloadScheduled;

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

  /// Aba foi para segundo plano: para de gastar requisições.
  void pause() {
    _paused = true;
    _refreshTimer?.cancel();
  }

  /// Aba voltou a ficar visível: atualiza na hora e retoma o ciclo.
  void resume() {
    if (!_paused) {
      return;
    }
    _paused = false;
    unawaited(_loadAndSchedule());
  }

  /// Recarrega a página agora (botão "Recarregar página").
  Future<void> reloadNow() {
    _reloadTimer?.cancel();
    return _reloadPage();
  }

  /// Busca as execuções uma vez, sem agendar a próxima.
  Future<void> load() async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    _notify();

    try {
      final page = await _repository.fetchRecentRuns();
      _runs = page.runs;
      _rateLimit = page.rateLimit;
      _hasLoaded = true;
      _errorMessage = null;
      _rateLimitResetAt = null;
      _lastUpdated = _clock();
      _scheduleReloadIfNeeded();
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
    _refreshTimer?.cancel();
    await load();
    if (_disposed || _paused) {
      return;
    }
    _refreshTimer = Timer(
      nextRefreshDelay,
      () => unawaited(_loadAndSchedule()),
    );
  }

  /// Saiu versão nova? Agenda o recarregamento (uma vez só).
  void _scheduleReloadIfNeeded() {
    final delay = autoReloadDelay;
    if (delay == null ||
        _reloadScheduled ||
        panelStatus != PanelStatus.newVersionAvailable) {
      return;
    }
    _reloadScheduled = true;
    _reloadTimer = Timer(delay, () => unawaited(reloadNow()));
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    _reloadTimer?.cancel();
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
  ///
  /// A API sem token permite 60 requisições por hora. Por isso:
  /// - durante um deploy, consulta a cada [activeInterval] (o deploy é curto);
  /// - parado, divide o saldo que sobrou pelo tempo até o reset, sem nunca
  ///   ficar abaixo de [idleInterval];
  /// - se o saldo acabou, espera o reset.
  Duration get nextRefreshDelay {
    final now = _clock();
    final blockedUntil = _rateLimitResetAt;
    if (blockedUntil != null) {
      return _untilReset(blockedUntil, now);
    }
    if (_errorMessage != null) {
      return errorInterval;
    }

    final limit = _rateLimit;
    if (limit != null && limit.remaining <= requestReserve) {
      return _untilReset(limit.resetAt, now);
    }
    if (activeRun != null) {
      return activeInterval;
    }
    final budget = _budgetInterval(now);
    return budget > idleInterval ? budget : idleInterval;
  }

  /// Saldo restante dividido igualmente até o reset.
  Duration _budgetInterval(DateTime now) {
    final limit = _rateLimit;
    if (limit == null) {
      return Duration.zero;
    }
    final window = limit.resetAt.difference(now);
    if (window.isNegative) {
      return Duration.zero;
    }
    final usable = limit.remaining - requestReserve;
    return Duration(microseconds: window.inMicroseconds ~/ usable);
  }

  Duration _untilReset(DateTime resetAt, DateTime now) {
    final wait = resetAt.difference(now);
    return wait.isNegative ? errorInterval : wait + const Duration(seconds: 5);
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
