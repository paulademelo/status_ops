/// Situação de uma execução (ou de um job), simplificada para o painel.
enum RunState {
  queued,
  inProgress,
  success,
  failure,
  cancelled,
  skipped,
  unknown,
}

/// Converte os campos `status` + `conclusion` da API em um [RunState].
RunState runStateOf(String status, String? conclusion) {
  if (status != 'completed') {
    return status == 'in_progress' ? RunState.inProgress : RunState.queued;
  }
  return switch (conclusion) {
    'success' => RunState.success,
    'failure' || 'timed_out' || 'startup_failure' => RunState.failure,
    'cancelled' => RunState.cancelled,
    'skipped' => RunState.skipped,
    _ => RunState.unknown,
  };
}

/// Uma execução do workflow, como vem de
/// `GET /repos/{dono}/{repo}/actions/runs`.
class WorkflowRun {
  const WorkflowRun({
    required this.id,
    required this.runNumber,
    required this.title,
    required this.headSha,
    required this.branch,
    required this.actor,
    required this.status,
    required this.conclusion,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.htmlUrl = '',
  });

  factory WorkflowRun.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;
    return WorkflowRun(
      id: json['id'] as int,
      runNumber: json['run_number'] as int,
      title: json['display_title'] as String? ?? json['name'] as String? ?? '',
      headSha: json['head_sha'] as String? ?? '',
      branch: json['head_branch'] as String? ?? '',
      actor: actor?['login'] as String? ?? '',
      status: json['status'] as String? ?? '',
      conclusion: json['conclusion'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      startedAt: DateTime.tryParse(json['run_started_at'] as String? ?? ''),
      htmlUrl: json['html_url'] as String? ?? '',
    );
  }

  final int id;
  final int runNumber;

  /// Normalmente a mensagem do commit que disparou a execução.
  final String title;
  final String headSha;
  final String branch;
  final String actor;

  /// `queued`, `in_progress`, `completed`, `waiting`...
  final String status;

  /// Só existe quando `status == completed`: `success`, `failure`...
  final String? conclusion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;

  /// Página da execução no GitHub Actions.
  final String htmlUrl;

  RunState get state => runStateOf(status, conclusion);

  /// Ainda está na fila ou rodando.
  bool get isActive => state == RunState.queued || state == RunState.inProgress;

  String get shortSha => headSha.length > 7 ? headSha.substring(0, 7) : headSha;

  /// Quanto tempo a execução levou (só para as que já terminaram).
  Duration? get duration {
    final start = startedAt;
    if (isActive || start == null) {
      return null;
    }
    return updatedAt.difference(start);
  }
}
