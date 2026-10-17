import 'package:flutter_test/flutter_test.dart';

import 'package:status_ops/data/models/pipeline_job.dart';
import 'package:status_ops/data/models/workflow_run.dart';

void main() {
  test('converte o JSON de um job com passos', () {
    final job = PipelineJob.fromJson({
      'id': 10,
      'name': '🏗️ Build web',
      'status': 'in_progress',
      'conclusion': null,
      'started_at': '2026-10-17T12:00:00Z',
      'completed_at': null,
      'html_url': 'https://github.com/x/y/actions/runs/1/job/10',
      'steps': [
        {
          'number': 1,
          'name': 'Checkout',
          'status': 'completed',
          'conclusion': 'success',
        },
        {
          'number': 2,
          'name': 'flutter build web',
          'status': 'in_progress',
          'conclusion': null,
        },
        {'number': 3, 'name': 'Upload', 'status': 'queued', 'conclusion': null},
      ],
    });

    expect(job.state, RunState.inProgress);
    expect(job.steps, hasLength(3));
    expect(job.currentStep?.name, 'flutter build web');
    expect(job.finishedSteps, 1);
    expect(job.duration, isNull);
  });

  test('job terminado tem duração e nenhum passo rodando', () {
    final job = PipelineJob.fromJson({
      'id': 11,
      'name': '🚀 Deploy',
      'status': 'completed',
      'conclusion': 'skipped',
      'started_at': '2026-10-17T12:00:00Z',
      'completed_at': '2026-10-17T12:00:30Z',
    });

    expect(job.state, RunState.skipped);
    expect(job.currentStep, isNull);
    expect(job.duration, const Duration(seconds: 30));
  });
}
