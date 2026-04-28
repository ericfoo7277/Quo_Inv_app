import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../shared/models/invoice.dart';
import '../../../shared/providers/invoices_provider.dart';

String _plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load invoices')),
        data: (invoices) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final overdue = invoices
              .where((i) =>
                  i.status != InvoiceStatus.paid &&
                  i.status != InvoiceStatus.cancelled &&
                  i.dueDate.isBefore(today))
              .toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

          final dueSoon = invoices
              .where((i) =>
                  i.status != InvoiceStatus.paid &&
                  i.status != InvoiceStatus.cancelled &&
                  !i.dueDate.isBefore(today) &&
                  i.dueDate.isBefore(today.add(const Duration(days: 7))))
              .toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

          if (overdue.isEmpty && dueSoon.isEmpty) {
            return const EmptyState(
              title: 'All clear!',
              message: 'No overdue or upcoming invoices. Keep it up.',
              icon: Icons.check_circle_outline_rounded,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              const ResponsiveContent(
                child: PremiumScreenHeader(
                  title: 'Reminders',
                  subtitle: 'Overdue and upcoming invoice alerts.',
                  icon: Icons.notifications_active_rounded,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (overdue.isNotEmpty) ...[
                ResponsiveContent(
                  child: SectionHeader(
                    title: 'Overdue',
                    subtitle: '${_plural(overdue.length, 'invoice')} past due',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...overdue.map((inv) => ResponsiveContent(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _ReminderCard(
                          invoice: inv,
                          today: today,
                          isOverdue: true,
                        ),
                      ),
                    )),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (dueSoon.isNotEmpty) ...[
                ResponsiveContent(
                  child: SectionHeader(
                    title: 'Due soon',
                    subtitle: '${_plural(dueSoon.length, 'invoice')} due within 7 days',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...dueSoon.map((inv) => ResponsiveContent(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _ReminderCard(
                          invoice: inv,
                          today: today,
                          isOverdue: false,
                        ),
                      ),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.invoice,
    required this.today,
    required this.isOverdue,
  });

  final Invoice invoice;
  final DateTime today;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.simpleCurrency(name: invoice.currency);
    final diff = invoice.dueDate.difference(today).inDays;
    final daysLabel = isOverdue
        ? '${_plural(diff.abs(), 'day')} overdue'
        : diff == 0
            ? 'Due today'
            : 'Due in ${_plural(diff, 'day')}';
    final color = isOverdue ? AppColors.error : AppColors.warning;

    return AppCard(
      onTap: () => context.pushNamed(
        RouteNames.invoiceDetail,
        pathParameters: {'id': invoice.id},
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.invoiceNumber, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(invoice.customerName, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    StatusPill(label: daysLabel, color: color),
                    const SizedBox(width: AppSpacing.sm),
                    StatusPill(
                      label: invoice.status.label,
                      color: invoice.status.color,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            currency.format(invoice.total),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
