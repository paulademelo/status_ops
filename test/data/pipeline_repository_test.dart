import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:status_ops/data/pipeline_repository.dart';

const sampleBody = {
  'total_count': 1,
  'workflow_runs': [
    {
      'id': 1,
      'run_number': 7,
      'display_title': 'ci: fixa versão do Flutter',
      'head_sha': 'b4e41db0000000000000',
      'head_branch': 'main',
      'actor': {'login': 'paulademelo'},
      'status': 'completed',
      'conclusion': 'success',
      'created_at': '2026-10-17T12:23:50Z',
      'run_started_at': '2026-10-17T12:23:50Z',
      'updated_at': '2026-10-17T12:26:00Z',
    },
  ],
};

GitHubPipelineRepository repositoryWith(MockClientHandler handler) {
  return GitHubPipelineRepository(
    repository: 'paulademelo/status_ops',
    client: MockClient(handler),
  );
}

void main() {
  test('chama o endpoint certo e converte as execuções', () async {
    late Uri calledUri;
    final repository = repositoryWith((request) async {
      calledUri = request.url;
      return http.Response(jsonEncode(sampleBody), 200);
    });

    final runs = await repository.fetchRecentRuns();

    expect(calledUri.path, '/repos/paulademelo/status_ops/actions/runs');
    expect(calledUri.queryParameters['branch'], 'main');
    expect(runs, hasLength(1));
    expect(runs.first.runNumber, 7);
  });

  test(
    'limite da API vira RateLimitException com o horário de reset',
    () async {
      final repository = repositoryWith((_) async {
        return http.Response(
          '{"message":"API rate limit exceeded"}',
          403,
          headers: {
            'x-ratelimit-remaining': '0',
            'x-ratelimit-reset': '1792252800',
          },
        );
      });

      await expectLater(
        repository.fetchRecentRuns(),
        throwsA(
          isA<RateLimitException>().having(
            (e) => e.resetAt,
            'resetAt',
            DateTime.fromMillisecondsSinceEpoch(1792252800 * 1000),
          ),
        ),
      );
    },
  );

  test('repo inexistente ou privado gera mensagem clara', () async {
    final repository = repositoryWith(
      (_) async => http.Response('{"message":"Not Found"}', 404),
    );

    await expectLater(
      repository.fetchRecentRuns(),
      throwsA(
        isA<PipelineException>().having(
          (e) => e.message,
          'message',
          contains('não encontrado'),
        ),
      ),
    );
  });

  test('sem internet vira PipelineException', () async {
    final repository = repositoryWith(
      (_) async => throw http.ClientException('XMLHttpRequest error.'),
    );

    await expectLater(
      repository.fetchRecentRuns(),
      throwsA(isA<PipelineException>()),
    );
  });

  test('JSON inesperado não quebra o app', () async {
    final repository = repositoryWith(
      (_) async => http.Response('isso não é json', 200),
    );

    await expectLater(
      repository.fetchRecentRuns(),
      throwsA(isA<PipelineException>()),
    );
  });
}
