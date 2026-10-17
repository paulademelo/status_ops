import 'package:flutter_test/flutter_test.dart';

import 'package:status_ops/data/models/workflow_run.dart';

Map<String, dynamic> runJson({
  String status = 'completed',
  String? conclusion = 'success',
}) => {
  'id': 99,
  'run_number': 12,
  'display_title': 'feat: painel ao vivo',
  'head_sha': '1234567890abcdef',
  'head_branch': 'main',
  'actor': {'login': 'paulademelo'},
  'status': status,
  'conclusion': conclusion,
  'created_at': '2026-10-17T12:00:00Z',
  'run_started_at': '2026-10-17T12:00:05Z',
  'updated_at': '2026-10-17T12:01:45Z',
  'html_url': 'https://github.com/paulademelo/status_ops/actions/runs/99',
};

void main() {
  test('converte o JSON da API do GitHub', () {
    final run = WorkflowRun.fromJson(runJson());

    expect(run.runNumber, 12);
    expect(run.title, 'feat: painel ao vivo');
    expect(run.actor, 'paulademelo');
    expect(run.shortSha, '1234567');
    expect(run.state, RunState.success);
    expect(run.duration, const Duration(minutes: 1, seconds: 40));
    expect(run.htmlUrl, endsWith('/actions/runs/99'));
  });

  test('mapeia status e conclusion para RunState', () {
    RunState stateOf(String status, [String? conclusion]) =>
        WorkflowRun.fromJson(
          runJson(status: status, conclusion: conclusion),
        ).state;

    expect(stateOf('queued'), RunState.queued);
    expect(stateOf('waiting'), RunState.queued);
    expect(stateOf('in_progress'), RunState.inProgress);
    expect(stateOf('completed', 'failure'), RunState.failure);
    expect(stateOf('completed', 'timed_out'), RunState.failure);
    expect(stateOf('completed', 'cancelled'), RunState.cancelled);
    expect(stateOf('completed', 'skipped'), RunState.skipped);
  });

  test('execução ativa não tem duração', () {
    final run = WorkflowRun.fromJson(runJson(status: 'in_progress'));

    expect(run.isActive, isTrue);
    expect(run.duration, isNull);
  });
}
