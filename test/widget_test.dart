import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:status_ops/build_info.dart';
import 'package:status_ops/config.dart';
import 'package:status_ops/main.dart';

/// Simula o que o pipeline injeta via --dart-define-from-file.
const pipelineInfo = BuildInfo(
  commitSha: 'abc1234',
  commitMessage: 'feat: pipeline de deploy configurado',
  commitAuthor: 'Paula',
  runNumber: '42',
  buildDate: '17/10/2026 10:30',
  testsPassed: 8,
  testsTotal: 8,
  recentCommits: [
    CommitEntry(
      sha: 'abc1234',
      message: 'feat: pipeline de deploy configurado',
      author: 'Paula',
      date: '17/10/2026 10:30',
    ),
    CommitEntry(
      sha: 'e5f6a7b',
      message: 'fix: corrige typo na tela inicial',
      author: 'Ana',
      date: '16/10/2026 18:02',
    ),
  ],
);

Future<void> pumpDashboard(
  WidgetTester tester, {
  BuildInfo info = const BuildInfo(),
  Size size = const Size(1280, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(StatusOpsApp(buildInfo: info));
}

void main() {
  group('Configuração', () {
    test('a versão segue o padrão vX.Y.Z', () {
      expect(appVersion, matches(RegExp(r'^v\d+\.\d+\.\d+$')));
    });

    test('o projeto tem nome e mensagem de status', () {
      expect(projectName, isNotEmpty);
      expect(statusMessage, isNotEmpty);
    });
  });

  group('BuildInfo', () {
    test('sem dart-define, usa os valores de build local', () {
      final info = BuildInfo.fromEnvironment();
      expect(info.isFromPipeline, isFalse);
      expect(info.recentCommits, isEmpty);
    });

    test('converte o JSON de commits gerado pelo pipeline', () {
      final commits = BuildInfo.parseCommits(
        '[{"sha":"a1b2c3d","message":"fix: typo","author":"Ana",'
        '"date":"17/10/2026 09:00"}]',
      );
      expect(commits, hasLength(1));
      expect(commits.first.sha, 'a1b2c3d');
      expect(commits.first.message, 'fix: typo');
      expect(commits.first.author, 'Ana');
    });

    test('JSON inválido não quebra o app', () {
      expect(BuildInfo.parseCommits('isso não é json'), isEmpty);
      expect(BuildInfo.parseCommits('{"sha":"abc"}'), isEmpty);
    });

    test('calcula a taxa de testes passando', () {
      const info = BuildInfo(testsPassed: 9, testsTotal: 10);
      expect(info.testPassRate, closeTo(0.9, 0.0001));
      expect(info.testsFailed, 1);
    });
  });

  group('Dashboard', () {
    testWidgets('mostra projeto, versão e ambiente online', (tester) async {
      await pumpDashboard(tester, info: pipelineInfo);

      expect(find.textContaining(projectName), findsWidgets);
      expect(find.text(appVersion), findsOneWidget);
      expect(find.text('ONLINE'), findsOneWidget);
      expect(find.text(statusMessage), findsOneWidget);
    });

    testWidgets('mostra os dados vindos do pipeline', (tester) async {
      await pumpDashboard(tester, info: pipelineInfo);

      expect(find.text('Sucesso'), findsOneWidget);
      expect(find.text('#42'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('fix: corrige typo na tela inicial'), findsOneWidget);
    });

    testWidgets('build local avisa que está fora do pipeline', (tester) async {
      await pumpDashboard(tester);

      expect(find.text('Rodando fora do pipeline'), findsOneWidget);
      expect(find.textContaining('primeiro deploy'), findsOneWidget);
    });

    testWidgets('layout se adapta ao celular sem overflow', (tester) async {
      await pumpDashboard(
        tester,
        info: pipelineInfo,
        size: const Size(390, 844),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(appVersion), findsOneWidget);
    });
  });
}
