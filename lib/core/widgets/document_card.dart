import 'package:flutter/material.dart';

import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import 'app_card.dart';
import 'status_pill.dart';

class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.number,
    required this.customerName,
    required this.meta,
    required this.amount,
    required this.statusLabel,
    required this.statusColor,
    required this.icon,
    this.onTap,
  });

  final String number;
  final String customerName;
  final String meta;
  final String amount;
  final String statusLabel;
  final Color statusColor;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        number,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusPill(label: statusLabel, color: statusColor),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  customerName,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        meta,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(amount, style: theme.textTheme.titleMedium),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
