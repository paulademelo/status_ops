import 'package:flutter/material.dart';

import 'package:status_ops/config.dart';
import 'package:status_ops/data/build_info.dart';
import 'package:status_ops/data/pipeline_repository.dart';
import 'package:status_ops/ui/core/theme.dart';
import 'package:status_ops/ui/dashboard/dashboard_screen.dart';
import 'package:status_ops/ui/dashboard/dashboard_view_model.dart';

void main() {
  // Monta as dependências uma vez, de fora para dentro:
  // repositório (dados) → ViewModel (regras) → tela (UI).
  final viewModel = DashboardViewModel(
    repository: GitHubPipelineRepository(repository: githubRepository),
    // No CI os metadados chegam via --dart-define-from-file=build_info.json.
    buildInfo: BuildInfo.fromEnvironment(),
  )..start();

  runApp(StatusOpsApp(viewModel: viewModel));
}

class StatusOpsApp extends StatelessWidget {
  const StatusOpsApp({super.key, required this.viewModel});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter StatusOps',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: DashboardScreen(viewModel: viewModel),
    );
  }
}
