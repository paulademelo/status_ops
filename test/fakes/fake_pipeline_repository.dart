import 'package:status_ops/data/models/pipeline_job.dart';
import 'package:status_ops/data/models/runs_page.dart';
import 'package:status_ops/data/models/workflow_run.dart';
import 'package:status_ops/data/pipeline_repository.dart';

/// Repositório de mentira: devolve o que o teste mandar, sem internet.
class FakePipelineRepository implements PipelineRepository {
  FakePipelineRepository({
    this.runs = const [],
    this.jobs = const [],
    this.rateLimit,
    this.error,
  });

  List<WorkflowRun> runs;

  /// Jobs devolvidos para qualquer execução pedida.
  List<PipelineJob> jobs;

  /// Saldo da API devolvido junto com as execuções.
  RateLimit? rateLimit;

  /// Se preenchido, é lançado em vez de devolver os dados.
  PipelineException? error;

  /// Quantas vezes cada método foi chamado.
  int calls = 0;
  int jobCalls = 0;

  /// IDs das execuções cujos jobs foram pedidos.
  final List<int> requestedJobRuns = [];

  @override
  Future<RunsPage> fetchRecentRuns() async {
    calls++;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return RunsPage(runs: runs, rateLimit: rateLimit);
  }

  @override
  Future<List<PipelineJob>> fetchJobs(int runId) {
    jobCalls++;
    requestedJobRuns.add(runId);
    return Future.value(jobs);
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
    htmlUrl:
        'https://github.com/paulademelo/status_ops/actions/runs/$runNumber',
  );
}

/// Cria um job com passos. [doneSteps] passos terminados e, se
/// [status] for `in_progress`, o seguinte está rodando.
PipelineJob fakeJob({
  int id = 1,
  String name = '🧪 CI - Qualidade e testes',
  String status = 'completed',
  String? conclusion = 'success',
  List<String> stepNames = const ['Checkout', 'Rodar testes', 'Resumo'],
  int doneSteps = 3,
}) {
  final steps = [
    for (var i = 0; i < stepNames.length; i++)
      JobStep(
        number: i + 1,
        name: stepNames[i],
        status: _stepStatus(i, doneSteps, status),
        conclusion: i < doneSteps ? 'success' : null,
      ),
  ];
  return PipelineJob(
    id: id,
    name: name,
    status: status,
    conclusion: status == 'completed' ? conclusion : null,
    startedAt: fixedNow.subtract(const Duration(minutes: 3)),
    completedAt: status == 'completed'
        ? fixedNow.subtract(const Duration(minutes: 1))
        : null,
    htmlUrl: 'https://github.com/paulademelo/status_ops/actions/runs/1/job/$id',
    steps: steps,
  );
}

String _stepStatus(int index, int doneSteps, String jobStatus) {
  if (index < doneSteps) {
    return 'completed';
  }
  if (index == doneSteps && jobStatus == 'in_progress') {
    return 'in_progress';
  }
  return 'queued';
}
