import 'package:flutter/material.dart';

import '../../shared/models/customer.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import 'app_card.dart';

class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    this.onTap,
  });

  final Customer customer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.16),
                  theme.colorScheme.secondary.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              customer.initials,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  customer.companyName ?? customer.email ?? '',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}
