import 'package:flutter/material.dart';

import 'package:status_ops/data/models/workflow_run.dart';
import 'package:status_ops/ui/core/theme.dart';

/// Ícone, cor e texto de cada [RunState] (usado em execuções e jobs).
///
/// A cor vem da paleta do tema atual, por isso recebe [AppPalette].
class RunStateLook {
  const RunStateLook(this.icon, this.color, this.label);

  factory RunStateLook.of(RunState state, AppPalette colors) {
    return switch (state) {
      RunState.success => RunStateLook(
        Icons.check_circle,
        colors.success,
        'Sucesso',
      ),
      RunState.failure => RunStateLook(Icons.cancel, colors.failure, 'Falhou'),
      RunState.inProgress => RunStateLook(
        Icons.sync,
        colors.running,
        'Rodando',
      ),
      RunState.queued => RunStateLook(Icons.schedule, colors.queued, 'Na fila'),
      RunState.cancelled => RunStateLook(
        Icons.block,
        colors.queued,
        'Cancelada',
      ),
      RunState.skipped => RunStateLook(
        Icons.skip_next,
        colors.queued,
        'Pulado',
      ),
      RunState.unknown => RunStateLook(
        Icons.help_outline,
        colors.queued,
        'Desconhecido',
      ),
    };
  }

  final IconData icon;
  final Color color;
  final String label;
}
