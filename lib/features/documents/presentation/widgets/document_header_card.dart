import 'package:flutter/material.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_pill.dart';

class DocumentHeaderCard extends StatelessWidget {
  const DocumentHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          StatusPill(label: statusLabel, color: statusColor),
        ],
      ),
    );
  }
}
