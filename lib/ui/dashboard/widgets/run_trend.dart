import 'package:flutter/material.dart';

import 'package:status_ops/data/models/workflow_run.dart';
import 'package:status_ops/ui/core/run_state_look.dart';
import 'package:status_ops/ui/core/theme.dart';

/// Bolinhas com o resultado das últimas execuções (antiga → recente).
///
/// Mostra a tendência: "4 falhas e depois só sucesso" conta uma história
/// bem diferente de "sucesso e falha alternando", mesmo com a mesma taxa.
class RunTrend extends StatelessWidget {
  const RunTrend({super.key, required this.runs});

  /// Da mais antiga para a mais recente.
  final List<WorkflowRun> runs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Tendência',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final run in runs) _TrendDot(run: run)],
          ),
        ),
      ],
    );
  }
}

class _TrendDot extends StatelessWidget {
  const _TrendDot({required this.run});

  final WorkflowRun run;

  @override
  Widget build(BuildContext context) {
    final look = RunStateLook.of(run.state);
    return Tooltip(
      message: '#${run.runNumber} · ${look.label}',
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(shape: BoxShape.circle, color: look.color),
      ),
    );
  }
}
