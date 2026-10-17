import 'package:flutter_test/flutter_test.dart';

import 'package:status_ops/config.dart';
import 'package:status_ops/data/build_info.dart';

void main() {
  group('Configuração', () {
    test('a versão segue o padrão vX.Y.Z', () {
      expect(appVersion, matches(RegExp(r'^v\d+\.\d+\.\d+$')));
    });

    test('o projeto tem nome, mensagem e repositório', () {
      expect(projectName, isNotEmpty);
      expect(statusMessage, isNotEmpty);
      expect(githubRepository, matches(RegExp(r'^[\w.-]+/[\w.-]+$')));
    });
  });

  group('BuildInfo', () {
    test('sem dart-define, usa os valores de build local', () {
      final info = BuildInfo.fromEnvironment();
      expect(info.isFromPipeline, isFalse);
      expect(info.hasTestResults, isFalse);
    });

    test('calcula a taxa de testes passando', () {
      const info = BuildInfo(testsPassed: 9, testsTotal: 10);
      expect(info.testPassRate, closeTo(0.9, 0.0001));
      expect(info.testsFailed, 1);
    });
  });
}
