import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_list_item.dart';
import '../../../core/widgets/document_card.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_header.dart';
import '../../../shared/models/invoice.dart';
import '../../../shared/providers/invoices_provider.dart';
import '../../../shared/providers/payments_provider.dart';
import 'widgets/dashboard_balance_hero.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final paymentsAsync = ref.watch(paymentsProvider);
    final currency = NumberFormat.simpleCurrency();

    final invoices = invoicesAsync.value ?? const <Invoice>[];
    final payments = paymentsAsync.value ?? const [];

    final outstanding = invoices
        .where((i) =>
            i.status == InvoiceStatus.sent || i.status == InvoiceStatus.overdue)
        .fold<double>(0, (s, i) => s + i.total);
    final paidThisMonth = payments.fold<double>(0, (s, p) => s + p.amount);

    final recent = [...invoices]
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hello 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(invoicesProvider);
          ref.invalidate(paymentsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const PremiumScreenHeader(
              title: 'Dashboard',
              subtitle: 'A calm view of your cash flow.',
              icon: Icons.auto_graph_rounded,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ResponsiveContent(
              maxWidth: 900,
              child: DashboardBalanceHero(
                outstanding: currency.format(outstanding),
                paid: currency.format(paidThisMonth),
                invoices: invoices.length.toString(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ResponsiveContent(
              maxWidth: 900,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 640;
                  final children = [
                    Expanded(
                      child: MetricCard(
                        label: 'Paid',
                        value: currency.format(paidThisMonth),
                        icon: Icons.verified_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    if (!compact) const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: MetricCard(
                        label: 'Active',
                        value: invoices
                            .where((i) =>
                                i.status == InvoiceStatus.sent ||
                                i.status == InvoiceStatus.overdue)
                            .length
                            .toString(),
                        icon: Icons.schedule_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                  ];

                  return compact
                      ? Column(
                          children: [
                            children.first,
                            const SizedBox(height: AppSpacing.md),
                            children.last,
                          ],
                        )
                      : Row(children: children);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ResponsiveContent(
              child: SectionHeader(
                title: 'Recent invoices',
                action: TextButton(
                  onPressed: () => context.goNamed(RouteNames.invoices),
                  child: const Text('View all'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (invoicesAsync.isLoading && recent.isEmpty)
              const ResponsiveContent(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else
              ...recent.take(4).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final inv = entry.value;
                final fmt = NumberFormat.simpleCurrency(name: inv.currency);
                return ResponsiveContent(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AnimatedListItem(
                      index: index,
                      child: DocumentCard(
                        number: inv.number,
                        customerName: inv.customerName,
                        meta: DateFormat.yMMMd().format(inv.dueDate),
                        amount: fmt.format(inv.total),
                        statusLabel: inv.status.label,
                        statusColor: inv.status.color,
                        icon: Icons.receipt_long_rounded,
                        onTap: () => context.goNamed(
                          RouteNames.invoiceDetail,
                          pathParameters: {'id': inv.id},
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
