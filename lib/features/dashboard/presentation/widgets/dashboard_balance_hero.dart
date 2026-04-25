import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';

class DashboardBalanceHero extends StatelessWidget {
  const DashboardBalanceHero({
    super.key,
    required this.outstanding,
    required this.paid,
    required this.invoices,
  });

  final String outstanding;
  final String paid;
  final String invoices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      gradient: AppColors.primaryGradient,
      shadows: const [
        BoxShadow(
          color: Color(0x336366F1),
          blurRadius: 28,
          offset: Offset(0, 16),
        ),
      ],
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderColor: Colors.white24,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -28,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Outstanding',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                outstanding,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  _MiniStat(label: 'Paid', value: paid),
                  const SizedBox(width: AppSpacing.xl),
                  _MiniStat(label: 'Invoices', value: invoices),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
