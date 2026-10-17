import 'dart:convert';

/// Um commit exibido no histórico do painel.
class CommitEntry {
  const CommitEntry({
    required this.sha,
    required this.message,
    required this.author,
    required this.date,
  });

  factory CommitEntry.fromJson(Map<String, dynamic> json) {
    return CommitEntry(
      sha: json['sha'] as String? ?? '',
      message: json['message'] as String? ?? '',
      author: json['author'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }

  final String sha;
  final String message;
  final String author;
  final String date;
}

/// Metadados do build gerados pelo pipeline de CI/CD.
///
/// O job de build cria um `build_info.json` e o passa para o Flutter com
/// `--dart-define-from-file`. Fora do pipeline, os valores padrão abaixo
/// são usados e o painel indica que está rodando localmente.
class BuildInfo {
  const BuildInfo({
    this.commitSha = localSha,
    this.commitMessage = 'Build local (fora do pipeline)',
    this.commitAuthor = 'você',
    this.runNumber = '—',
    this.buildDate = '—',
    this.testsPassed = 0,
    this.testsTotal = 0,
    this.recentCommits = const [],
  });

  factory BuildInfo.fromEnvironment() {
    const sha = String.fromEnvironment('COMMIT_SHA');
    const message = String.fromEnvironment('COMMIT_MESSAGE');
    const author = String.fromEnvironment('COMMIT_AUTHOR');
    const runNumber = String.fromEnvironment('RUN_NUMBER');
    const buildDate = String.fromEnvironment('BUILD_DATE');
    const testsPassed = String.fromEnvironment('TESTS_PASSED');
    const testsTotal = String.fromEnvironment('TESTS_TOTAL');
    const commits = String.fromEnvironment('RECENT_COMMITS');

    if (sha.isEmpty) {
      return const BuildInfo();
    }

    return BuildInfo(
      commitSha: sha,
      commitMessage: message,
      commitAuthor: author,
      runNumber: runNumber,
      buildDate: buildDate,
      testsPassed: int.tryParse(testsPassed) ?? 0,
      testsTotal: int.tryParse(testsTotal) ?? 0,
      recentCommits: parseCommits(commits),
    );
  }

  static const String localSha = 'local';

  final String commitSha;
  final String commitMessage;
  final String commitAuthor;
  final String runNumber;
  final String buildDate;
  final int testsPassed;
  final int testsTotal;
  final List<CommitEntry> recentCommits;

  /// `true` quando o app foi compilado pelo GitHub Actions.
  bool get isFromPipeline => commitSha != localSha;

  bool get hasTestResults => testsTotal > 0;

  int get testsFailed => testsTotal - testsPassed;

  double get testPassRate => hasTestResults ? testsPassed / testsTotal : 0;

  /// Converte o JSON de commits gerado no workflow (`git log` + `jq`).
  static List<CommitEntry> parseCommits(String raw) {
    if (raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CommitEntry.fromJson)
          .toList();
    } on FormatException {
      return const [];
    }
  }
}
