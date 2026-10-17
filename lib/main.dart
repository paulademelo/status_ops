import 'package:flutter/material.dart';

import 'package:status_ops/config.dart';
import 'package:status_ops/data/build_info.dart';
import 'package:status_ops/data/pipeline_repository.dart';
import 'package:status_ops/ui/core/page_reloader.dart';
import 'package:status_ops/ui/core/theme.dart';
import 'package:status_ops/ui/core/theme_controller.dart';
import 'package:status_ops/ui/core/theme_storage.dart';
import 'package:status_ops/ui/core/url_opener.dart';
import 'package:status_ops/ui/dashboard/dashboard_screen.dart';
import 'package:status_ops/ui/dashboard/dashboard_view_model.dart';

void main() {
  // Monta as dependências uma vez, de fora para dentro:
  // repositório (dados) → ViewModel (regras) → tela (UI).
  final viewModel = DashboardViewModel(
    repository: GitHubPipelineRepository(repository: githubRepository),
    // No CI os metadados chegam via --dart-define-from-file=build_info.json.
    buildInfo: BuildInfo.fromEnvironment(),
    // Quando sai uma versão nova, mostra o aviso e recarrega sozinho.
    reloadPage: reloadPage,
    // Clicar numa execução abre a página dela no GitHub Actions.
    openUrl: openUrl,
    autoReloadDelay: const Duration(seconds: 8),
  )..start();

  // O tema escolhido fica salvo no navegador.
  final themeController = ThemeController(
    read: readSavedTheme,
    write: saveTheme,
  );

  runApp(StatusOpsApp(viewModel: viewModel, themeController: themeController));
}

class StatusOpsApp extends StatelessWidget {
  const StatusOpsApp({
    super.key,
    required this.viewModel,
    required this.themeController,
  });

  final DashboardViewModel viewModel;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    // Quando o tema muda, só o MaterialApp precisa saber: ele entrega a
    // nova paleta para a árvore inteira (com uma transição animada).
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) => MaterialApp(
        title: 'Flutter StatusOps',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(themeController.palette),
        home: DashboardScreen(
          viewModel: viewModel,
          themeController: themeController,
        ),
      ),
    );
  }
}
