import 'package:flutter/material.dart';

import 'package:status_ops/build_info.dart';
import 'package:status_ops/dashboard_screen.dart';
import 'package:status_ops/theme.dart';

void main() {
  // No CI os metadados chegam via --dart-define-from-file=build_info.json.
  // Rodando localmente (flutter run), os valores padrão são usados.
  runApp(StatusOpsApp(buildInfo: BuildInfo.fromEnvironment()));
}

class StatusOpsApp extends StatelessWidget {
  const StatusOpsApp({super.key, this.buildInfo = const BuildInfo()});

  final BuildInfo buildInfo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter StatusOps',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: DashboardScreen(buildInfo: buildInfo),
    );
  }
}
