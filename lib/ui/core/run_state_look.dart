import 'package:flutter/material.dart';

import 'package:status_ops/data/models/workflow_run.dart';
import 'package:status_ops/ui/core/theme.dart';

/// Ícone, cor e texto de cada [RunState] (usado em execuções e jobs).
class RunStateLook {
  const RunStateLook(this.icon, this.color, this.label);

  factory RunStateLook.of(RunState state) {
    return switch (state) {
      RunState.success => const RunStateLook(
        Icons.check_circle,
        AppColors.green,
        'Sucesso',
      ),
      RunState.failure => const RunStateLook(
        Icons.cancel,
        AppColors.orange,
        'Falhou',
      ),
      RunState.inProgress => const RunStateLook(
        Icons.sync,
        AppColors.cyan,
        'Rodando',
      ),
      RunState.queued => const RunStateLook(
        Icons.schedule,
        AppColors.blue,
        'Na fila',
      ),
      RunState.cancelled => const RunStateLook(
        Icons.block,
        AppColors.textMuted,
        'Cancelada',
      ),
      RunState.skipped => const RunStateLook(
        Icons.skip_next,
        AppColors.textMuted,
        'Pulado',
      ),
      RunState.unknown => const RunStateLook(
        Icons.help_outline,
        AppColors.textMuted,
        'Desconhecido',
      ),
    };
  }

  final IconData icon;
  final Color color;
  final String label;
}
