import 'package:flutter/material.dart';

import 'package:status_ops/build_info.dart';
import 'package:status_ops/theme.dart';
import 'package:status_ops/widgets/glow_card.dart';

/// Últimos commits da `main`, gerados pelo pipeline com `git log`.
class CommitHistoryPanel extends StatelessWidget {
  const CommitHistoryPanel({super.key, required this.commits});

  final List<CommitEntry> commits;

  static const double _tableBreakpoint = 520;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      color: AppColors.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Histórico de Commits', style: panelTitleStyle),
          const SizedBox(height: 16),
          if (commits.isEmpty)
            const _EmptyHistory()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= _tableBreakpoint) {
                  return _CommitTable(commits: commits);
                }
                return _CommitList(commits: commits);
              },
            ),
        ],
      ),
    );
  }
}

class _CommitTable extends StatelessWidget {
  const _CommitTable({required this.commits});

  final List<CommitEntry> commits;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(90),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(1.5),
        3: FixedColumnWidth(140),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: const TableBorder(
        horizontalInside: BorderSide(color: AppColors.border),
      ),
      children: [
        const TableRow(
          children: [
            _Cell('Commit', isHeader: true),
            _Cell('Mensagem', isHeader: true),
            _Cell('Autor', isHeader: true),
            _Cell('Data', isHeader: true),
          ],
        ),
        for (final commit in commits)
          TableRow(
            children: [
              _Cell(commit.sha, color: AppColors.cyan),
              _Cell(commit.message),
              _Cell(commit.author),
              _Cell(commit.date, color: AppColors.textMuted),
            ],
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.isHeader = false, this.color});

  final String text;
  final bool isHeader;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
          color: color ?? AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Versão compacta para telas estreitas (celular).
class _CommitList extends StatelessWidget {
  const _CommitList({required this.commits});

  final List<CommitEntry> commits;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < commits.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Text(
                  commits[i].sha,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        commits[i].message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${commits[i].author} · ${commits[i].date}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.history, size: 32, color: AppColors.textMuted),
          SizedBox(height: 8),
          Text(
            'O histórico aparece aqui depois do primeiro deploy feito pelo '
            'pipeline.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
