import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_list_item.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/document_card.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_header.dart';
import '../../../shared/models/invoice.dart';
import '../../../shared/models/quotation.dart';
import '../../../shared/providers/invoices_provider.dart';
import '../../../shared/providers/payments_provider.dart';
import '../../../shared/providers/quotations_provider.dart';
import '../../../shared/providers/reminder_setting_provider.dart';
import 'widgets/dashboard_balance_hero.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final quotationsAsync = ref.watch(quotationsProvider);
    final paymentsAsync = ref.watch(paymentsProvider);
    final remindBeforeDays = ref
        .watch(reminderSettingProvider)
        .maybeWhen(data: (s) => s.remindBeforeDays, orElse: () => 7);

    final currency = NumberFormat.simpleCurrency();
    final invoices = invoicesAsync.value ?? const <Invoice>[];
    final quotations = quotationsAsync.value ?? const <Quotation>[];
    final payments = paymentsAsync.value ?? const [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    // ---- Aggregates ----
    final outstandingInvoices = invoices.where((i) =>
        i.status != InvoiceStatus.paid &&
        i.status != InvoiceStatus.cancelled);
    final outstandingTotal =
        outstandingInvoices.fold<double>(0, (s, i) => s + i.balanceDue);

    final overdue = invoices.where((i) =>
        i.status != InvoiceStatus.paid &&
        i.status != InvoiceStatus.cancelled &&
        i.dueDate.isBefore(today));
    final overdueCount = overdue.length;

    final dueSoon = invoices.where((i) =>
        i.status != InvoiceStatus.paid &&
        i.status != InvoiceStatus.cancelled &&
        !i.dueDate.isBefore(today) &&
        i.dueDate.isBefore(today.add(Duration(days: remindBeforeDays + 1))));
    final dueSoonCount = dueSoon.length;

    final paidThisMonth = payments
        .where((p) => !p.paymentDate.isBefore(monthStart))
        .fold<double>(0, (s, p) => s + p.amount);

    final draftsCount =
        invoices.where((i) => i.status == InvoiceStatus.draft).length;

    final recentInvoices = [...invoices]
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
    final recentQuotations = [...quotations]
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));

    // Top customers by outstanding balance.
    final topCustomers = _topCustomers(invoices);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuoSwift'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.goNamed(RouteNames.reminders),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(invoicesProvider);
          ref.invalidate(quotationsProvider);
          ref.invalidate(paymentsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            PremiumScreenHeader(
              title: 'Dashboard',
              subtitle: 'QuoSwift keeps your quotes and invoices moving.',
              icon: Icons.auto_graph_rounded,
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'QuoSwift',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ---- Hero outstanding balance ----
            ResponsiveContent(
              maxWidth: 900,
              child: DashboardBalanceHero(
                outstanding: currency.format(outstandingTotal),
                paid: currency.format(paidThisMonth),
                invoices: invoices.length.toString(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ---- Metric cards: overdue, due soon, paid this month, drafts ----
            ResponsiveContent(
              maxWidth: 900,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 640;
                  final overdueCard = MetricCard(
                    label: 'Overdue',
                    value: overdueCount.toString(),
                    icon: Icons.error_outline_rounded,
                    color: AppColors.error,
                    onTap: () => context.goNamed(RouteNames.reminders),
                  );
                  final dueSoonCard = MetricCard(
                    label: 'Due in $remindBeforeDays days',
                    value: dueSoonCount.toString(),
                    icon: Icons.schedule_rounded,
                    color: AppColors.warning,
                    onTap: () => context.goNamed(RouteNames.reminders),
                  );
                  final paidCard = MetricCard(
                    label: 'Paid this month',
                    value: currency.format(paidThisMonth),
                    icon: Icons.verified_rounded,
                    color: AppColors.success,
                  );
                  final draftsCard = MetricCard(
                    label: 'Drafts',
                    value: draftsCount.toString(),
                    icon: Icons.drafts_outlined,
                    color: AppColors.primary,
                    onTap: () => context.goNamed(RouteNames.invoices),
                  );

                  if (compact) {
                    return Column(
                      children: [
                        overdueCard,
                        const SizedBox(height: AppSpacing.md),
                        dueSoonCard,
                        const SizedBox(height: AppSpacing.md),
                        paidCard,
                        const SizedBox(height: AppSpacing.md),
                        draftsCard,
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: overdueCard),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: dueSoonCard),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(child: paidCard),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: draftsCard),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ---- Quick actions ----
            ResponsiveContent(
              child: SectionHeader(title: 'Quick actions'),
            ),
            const SizedBox(height: AppSpacing.md),
            ResponsiveContent(
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionTile(
                      icon: Icons.person_add_alt_1_rounded,
                      label: 'New customer',
                      color: AppColors.primary,
                      onTap: () => context.pushNamed(RouteNames.customerForm),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickActionTile(
                      icon: Icons.description_rounded,
                      label: 'New quotation',
                      color: AppColors.info,
                      onTap: () => context.pushNamed(RouteNames.quotationForm),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickActionTile(
                      icon: Icons.receipt_long_rounded,
                      label: 'New invoice',
                      color: AppColors.success,
                      onTap: () => context.pushNamed(RouteNames.invoiceForm),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ---- Recent invoices ----
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
            if (invoicesAsync.isLoading && recentInvoices.isEmpty)
              const ResponsiveContent(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (recentInvoices.isEmpty)
              const ResponsiveContent(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Text('No invoices yet.'),
                ),
              )
            else
              ...recentInvoices.take(4).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final inv = entry.value;
                final fmt = NumberFormat.simpleCurrency(name: inv.currency);
                return ResponsiveContent(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AnimatedListItem(
                      index: index,
                      child: DocumentCard(
                        number: inv.invoiceNumber,
                        customerName: inv.customerName,
                        meta: 'Due ${DateFormat.yMMMd().format(inv.dueDate)}',
                        amount: fmt.format(inv.total),
                        statusLabel: inv.status.label,
                        statusColor: inv.status.color,
                        icon: Icons.receipt_long_rounded,
                        onTap: () => context.pushNamed(
                          RouteNames.invoiceDetail,
                          pathParameters: {'id': inv.id},
                        ),
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: AppSpacing.xxl),

            // ---- Recent quotations ----
            ResponsiveContent(
              child: SectionHeader(
                title: 'Recent quotations',
                action: TextButton(
                  onPressed: () => context.goNamed(RouteNames.quotations),
                  child: const Text('View all'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (quotationsAsync.isLoading && recentQuotations.isEmpty)
              const ResponsiveContent(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (recentQuotations.isEmpty)
              const ResponsiveContent(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Text('No quotations yet.'),
                ),
              )
            else
              ...recentQuotations
                  .take(4)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final q = entry.value;
                final fmt = NumberFormat.simpleCurrency(name: q.currency);
                return ResponsiveContent(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AnimatedListItem(
                      index: index,
                      child: DocumentCard(
                        number: q.quotationNumber,
                        customerName: q.customerName,
                        meta:
                            'Valid ${DateFormat.yMMMd().format(q.validUntil)}',
                        amount: fmt.format(q.total),
                        statusLabel: q.status.label,
                        statusColor: q.status.color,
                        icon: Icons.description_rounded,
                        onTap: () => context.pushNamed(
                          RouteNames.quotationDetail,
                          pathParameters: {'id': q.id},
                        ),
                      ),
                    ),
                  ),
                );
              }),

            // ---- Top customers ----
            if (topCustomers.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxl),
              const ResponsiveContent(
                child: SectionHeader(
                  title: 'Top customers',
                  subtitle: 'Ranked by outstanding balance',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ResponsiveContent(
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < topCustomers.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _TopCustomerTile(
                          rank: i + 1,
                          customerId: topCustomers[i].id,
                          name: topCustomers[i].name,
                          outstanding:
                              currency.format(topCustomers[i].outstanding),
                          invoiceCount: topCustomers[i].invoiceCount,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  /// Returns the top 5 customers ranked by total outstanding balance.
  List<_TopCustomerStat> _topCustomers(List<Invoice> invoices) {
    final byCustomer = <String, _TopCustomerStat>{};
    for (final inv in invoices) {
      if (inv.status == InvoiceStatus.paid ||
          inv.status == InvoiceStatus.cancelled) {
        continue;
      }
      final stat = byCustomer.putIfAbsent(
        inv.customerId,
        () => _TopCustomerStat(
          id: inv.customerId,
          name: inv.customerName,
          outstanding: 0,
          invoiceCount: 0,
        ),
      );
      stat.outstanding += inv.balanceDue;
      stat.invoiceCount += 1;
    }
    final sorted = byCustomer.values.toList()
      ..sort((a, b) => b.outstanding.compareTo(a.outstanding));
    return sorted.take(5).toList();
  }
}

class _TopCustomerStat {
  _TopCustomerStat({
    required this.id,
    required this.name,
    required this.outstanding,
    required this.invoiceCount,
  });

  final String id;
  final String name;
  double outstanding;
  int invoiceCount;
}

class _TopCustomerTile extends StatelessWidget {
  const _TopCustomerTile({
    required this.rank,
    required this.customerId,
    required this.name,
    required this.outstanding,
    required this.invoiceCount,
  });

  final int rank;
  final String customerId;
  final String name;
  final String outstanding;
  final int invoiceCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: () => context.pushNamed(
        RouteNames.customerDetail,
        pathParameters: {'id': customerId},
      ),
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        foregroundColor: AppColors.primary,
        child: Text('$rank',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      title: Text(name.isEmpty ? 'Unknown customer' : name,
          style: theme.textTheme.titleSmall),
      subtitle: Text(
        '$invoiceCount open invoice${invoiceCount == 1 ? '' : 's'}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        outstanding,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
