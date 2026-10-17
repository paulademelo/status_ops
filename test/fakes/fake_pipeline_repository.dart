import 'package:status_ops/data/models/runs_page.dart';
import 'package:status_ops/data/models/workflow_run.dart';
import 'package:status_ops/data/pipeline_repository.dart';

/// Repositório de mentira: devolve o que o teste mandar, sem internet.
class FakePipelineRepository implements PipelineRepository {
  FakePipelineRepository({this.runs = const [], this.rateLimit, this.error});

  List<WorkflowRun> runs;

  /// Saldo da API devolvido junto com as execuções.
  RateLimit? rateLimit;

  /// Se preenchido, é lançado em vez de devolver [runs].
  PipelineException? error;

  int calls = 0;

  @override
  Future<RunsPage> fetchRecentRuns() async {
    calls++;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return RunsPage(runs: runs, rateLimit: rateLimit);
  }
}

/// Relógio fixo para os testes não dependerem da hora real.
final DateTime fixedNow = DateTime.utc(2026, 10, 17, 15);

/// Cria uma execução com valores padrão, alterando só o que importa.
WorkflowRun fakeRun({
  int runNumber = 1,
  String sha = 'abc1234aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  String status = 'completed',
  String? conclusion = 'success',
  String title = 'feat: nova versão',
  Duration age = const Duration(minutes: 10),
  Duration runTime = const Duration(minutes: 2),
}) {
  final created = fixedNow.subtract(age);
  return WorkflowRun(
    id: runNumber,
    runNumber: runNumber,
    title: title,
    headSha: sha,
    branch: 'main',
    actor: 'paulademelo',
    status: status,
    conclusion: status == 'completed' ? conclusion : null,
    createdAt: created,
    startedAt: created,
    updatedAt: created.add(runTime),
  );
}
