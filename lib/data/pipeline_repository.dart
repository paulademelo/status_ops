import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:status_ops/data/models/pipeline_job.dart';
import 'package:status_ops/data/models/runs_page.dart';
import 'package:status_ops/data/models/workflow_run.dart';

/// Fonte dos dados ao vivo do pipeline. Nos testes, usamos um fake.
abstract interface class PipelineRepository {
  /// Execuções mais recentes (da mais nova para a mais antiga) e o saldo
  /// de requisições da API.
  Future<RunsPage> fetchRecentRuns();

  /// Jobs (e seus passos) de uma execução.
  Future<List<PipelineJob>> fetchJobs(int runId);
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

/// Implementação real, usando a API REST do GitHub Actions.
///
/// Sem token de propósito: tudo que vai num build web é público.
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
    final response = await _get('/repos/$repository/actions/runs', {
      'branch': branch,
      'per_page': '$perPage',
    });
    final runs = _parseList(
      response.body,
      'workflow_runs',
      WorkflowRun.fromJson,
    );
    return RunsPage(
      runs: runs,
      rateLimit: RateLimit.fromHeaders(response.headers),
    );
  }

  @override
  Future<List<PipelineJob>> fetchJobs(int runId) async {
    final response = await _get('/repos/$repository/actions/runs/$runId/jobs', {
      'per_page': '30',
    });
    return _parseList(response.body, 'jobs', PipelineJob.fromJson);
  }

  /// GET na API do GitHub, transformando falhas em [PipelineException].
  Future<http.Response> _get(String path, Map<String, String> query) async {
    final uri = Uri.https('api.github.com', path, {
      ...query,
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
      return response;
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

  /// Lê a lista `json[key]` e converte cada item com [fromJson].
  List<T> _parseList<T>(
    String body,
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final items = json[key] as List<dynamic>? ?? const [];
      return items.whereType<Map<String, dynamic>>().map(fromJson).toList();
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
