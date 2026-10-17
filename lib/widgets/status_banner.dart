import 'package:flutter/material.dart';

import 'package:status_ops/build_info.dart';
import 'package:status_ops/config.dart';
import 'package:status_ops/theme.dart';
import 'package:status_ops/widgets/glow_card.dart';

/// Banner principal: ambiente ONLINE + dados do último deploy.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.buildInfo});

  final BuildInfo buildInfo;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      color: AppColors.green,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          const Text(
            'Status do Ambiente de Produção',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          const Text(
            'ONLINE',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.commit, label: buildInfo.commitSha),
              _InfoChip(
                icon: Icons.person_outline,
                label: buildInfo.commitAuthor,
              ),
              _InfoChip(icon: Icons.schedule, label: buildInfo.buildDate),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            buildInfo.commitMessage,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
