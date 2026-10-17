import 'package:status_ops/data/models/workflow_run.dart';

/// Quanto ainda podemos chamar a API do GitHub nesta janela de 1 hora.
///
/// Vem dos cabeçalhos `x-ratelimit-*` de toda resposta da API.
class RateLimit {
  const RateLimit({
    required this.limit,
    required this.remaining,
    required this.resetAt,
  });

  final int limit;
  final int remaining;

  /// Quando a contagem volta para [limit].
  final DateTime resetAt;

  /// `null` quando a resposta não trouxe os cabeçalhos.
  static RateLimit? fromHeaders(Map<String, String> headers) {
    final limit = int.tryParse(headers['x-ratelimit-limit'] ?? '');
    final remaining = int.tryParse(headers['x-ratelimit-remaining'] ?? '');
    final reset = int.tryParse(headers['x-ratelimit-reset'] ?? '');
    if (limit == null || remaining == null || reset == null) {
      return null;
    }
    return RateLimit(
      limit: limit,
      remaining: remaining,
      resetAt: DateTime.fromMillisecondsSinceEpoch(reset * 1000),
    );
  }
}

/// Resultado de uma consulta: as execuções + o "saldo" da API.
class RunsPage {
  const RunsPage({required this.runs, this.rateLimit});

  final List<WorkflowRun> runs;
  final RateLimit? rateLimit;
}
