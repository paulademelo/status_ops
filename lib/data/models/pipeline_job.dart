import 'package:status_ops/data/models/workflow_run.dart';

/// Um passo (`step`) dentro de um job do workflow.
class JobStep {
  const JobStep({
    required this.number,
    required this.name,
    required this.status,
    required this.conclusion,
  });

  factory JobStep.fromJson(Map<String, dynamic> json) {
    return JobStep(
      number: json['number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      conclusion: json['conclusion'] as String?,
    );
  }

  final int number;
  final String name;
  final String status;
  final String? conclusion;

  RunState get state => runStateOf(status, conclusion);
}

/// Um job de uma execução, como vem de
/// `GET /repos/{dono}/{repo}/actions/runs/{id}/jobs`.
class PipelineJob {
  const PipelineJob({
    required this.id,
    required this.name,
    required this.status,
    required this.conclusion,
    this.startedAt,
    this.completedAt,
    this.htmlUrl = '',
    this.steps = const [],
  });

  factory PipelineJob.fromJson(Map<String, dynamic> json) {
    final steps = json['steps'] as List<dynamic>? ?? const [];
    return PipelineJob(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      conclusion: json['conclusion'] as String?,
      startedAt: DateTime.tryParse(json['started_at'] as String? ?? ''),
      completedAt: DateTime.tryParse(json['completed_at'] as String? ?? ''),
      htmlUrl: json['html_url'] as String? ?? '',
      steps: steps
          .whereType<Map<String, dynamic>>()
          .map(JobStep.fromJson)
          .toList(),
    );
  }

  final int id;

  /// O `name:` do job no workflow (ex.: "🧪 CI - Qualidade e testes").
  final String name;
  final String status;
  final String? conclusion;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String htmlUrl;
  final List<JobStep> steps;

  RunState get state => runStateOf(status, conclusion);

  /// O passo rodando agora, se houver.
  JobStep? get currentStep {
    for (final step in steps) {
      if (step.state == RunState.inProgress) {
        return step;
      }
    }
    return null;
  }

  /// Quantos passos já terminaram (com qualquer resultado).
  int get finishedSteps =>
      steps.where((step) => step.status == 'completed').length;

  /// Quanto tempo o job levou (só para os que já terminaram).
  Duration? get duration {
    final start = startedAt;
    final end = completedAt;
    if (start == null || end == null) {
      return null;
    }
    return end.difference(start);
  }
}
