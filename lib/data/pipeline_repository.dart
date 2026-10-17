import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:status_ops/data/models/runs_page.dart';
import 'package:status_ops/data/models/workflow_run.dart';

abstract interface class PipelineRepository {
  Future<RunsPage> fetchRecentRuns();
}

class PipelineException implements Exception {
  const PipelineException(this.message);

  final String message;

  @override
  String toString() => 'PipelineException: $message';
}

class RateLimitException extends PipelineException {
  const RateLimitException({required this.resetAt})
    : super('Limite de requisições da API do GitHub atingido.');

  final DateTime resetAt;
}

class GitHubPipelineRepository implements PipelineRepository {
  GitHubPipelineRepository({
    required this.repository,
    this.branch = 'main',
    this.perPage = 10,
    http.Client? client,
    DateTime Function()? clock,
  }) : _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now;

  final String repository;
  final String branch;
  final int perPage;
  final http.Client _client;
  final DateTime Function() _clock;

  @override
  Future<RunsPage> fetchRecentRuns() async {
    final uri = Uri.https('api.github.com', '/repos/$repository/actions/runs', {
      'branch': branch,
      'per_page': '$perPage',
      // A API manda o navegador guardar a resposta por 60 s. Um valor
      // diferente a cada chamada ("cache buster") garante dados frescos.
      't': '${_clock().millisecondsSinceEpoch}',
    });

    final http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: const {'Accept': 'application/vnd.github+json'},
      );
    } on http.ClientException {
      throw const PipelineException('Sem conexão com a API do GitHub.');
    }

    if (response.statusCode == 200) {
      return RunsPage(
        runs: _parseRuns(response.body),
        rateLimit: RateLimit.fromHeaders(response.headers),
      );
    }
    if (_isRateLimited(response)) {
      throw RateLimitException(resetAt: _resetTime(response));
    }
    if (response.statusCode == 404) {
      throw PipelineException(
        'Repositório "$repository" não encontrado (ele é público?).',
      );
    }
    throw PipelineException(
      'A API do GitHub respondeu com erro ${response.statusCode}.',
    );
  }

  List<WorkflowRun> _parseRuns(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final runs = json['workflow_runs'] as List<dynamic>? ?? const [];
      return runs
          .whereType<Map<String, dynamic>>()
          .map(WorkflowRun.fromJson)
          .toList();
    } on FormatException {
      throw const PipelineException('Resposta inesperada da API do GitHub.');
    } on TypeError {
      throw const PipelineException('Resposta inesperada da API do GitHub.');
    }
  }

  bool _isRateLimited(http.Response response) {
    final code = response.statusCode;
    if (code != 403 && code != 429) {
      return false;
    }
    final headers = response.headers;
    return headers['x-ratelimit-remaining'] == '0' ||
        headers.containsKey('retry-after');
  }

  DateTime _resetTime(http.Response response) {
    final headers = response.headers;
    final resetEpoch = int.tryParse(headers['x-ratelimit-reset'] ?? '');
    if (resetEpoch != null) {
      return DateTime.fromMillisecondsSinceEpoch(resetEpoch * 1000);
    }
    final retryAfter = int.tryParse(headers['retry-after'] ?? '');
    return _clock().add(Duration(seconds: retryAfter ?? 60));
  }
}
