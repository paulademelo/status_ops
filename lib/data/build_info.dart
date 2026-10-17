/// Metadados do build gerados pelo pipeline de CI/CD.
///
/// O job de build cria um `build_info.json` e o passa para o Flutter com
/// `--dart-define-from-file`. Fora do pipeline, os valores padrão abaixo
/// são usados e o painel indica que está rodando localmente.
///
/// Diferente dos dados ao vivo (ver `PipelineRepository`), estes valores
/// ficam "congelados" dentro do app no momento da compilação.
class BuildInfo {
  const BuildInfo({
    this.commitSha = localSha,
    this.commitMessage = 'Build local (fora do pipeline)',
    this.commitAuthor = 'você',
    this.runNumber = '—',
    this.buildDate = '—',
    this.testsPassed = 0,
    this.testsTotal = 0,
  });

  factory BuildInfo.fromEnvironment() {
    const sha = String.fromEnvironment('COMMIT_SHA');
    const message = String.fromEnvironment('COMMIT_MESSAGE');
    const author = String.fromEnvironment('COMMIT_AUTHOR');
    const runNumber = String.fromEnvironment('RUN_NUMBER');
    const buildDate = String.fromEnvironment('BUILD_DATE');
    const testsPassed = String.fromEnvironment('TESTS_PASSED');
    const testsTotal = String.fromEnvironment('TESTS_TOTAL');

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

  /// `true` quando o app foi compilado pelo GitHub Actions.
  bool get isFromPipeline => commitSha != localSha;

  bool get hasTestResults => testsTotal > 0;

  int get testsFailed => testsTotal - testsPassed;

  double get testPassRate => hasTestResults ? testsPassed / testsTotal : 0;
}
