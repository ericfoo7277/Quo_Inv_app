import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../shared/models/customer.dart';

class CustomerProfileCard extends StatelessWidget {
  const CustomerProfileCard({
    super.key,
    required this.customer,
  });

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(customer.name, style: theme.textTheme.titleLarge),
          if (customer.company != null) ...[
            const SizedBox(height: 4),
            Text(customer.company!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.lg),
          InfoRow(icon: Icons.mail_outline_rounded, text: customer.email),
          if (customer.phone != null) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoRow(icon: Icons.phone_outlined, text: customer.phone!),
          ],
          if (customer.address != null) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoRow(icon: Icons.location_on_outlined, text: customer.address!),
          ],
          if (customer.taxId != null) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoRow(icon: Icons.badge_outlined, text: customer.taxId!),
          ],
        ],
      ),
    );
  }
}
