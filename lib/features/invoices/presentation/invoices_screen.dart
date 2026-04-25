import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/animated_list_item.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/document_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../shared/models/invoice.dart';
import '../../../shared/providers/invoices_provider.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(invoicesProvider);
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed(RouteNames.invoiceForm),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New invoice'),
      ),
      body: AsyncValueView(
        value: invoices,
        onRetry: () => ref.invalidate(invoicesProvider),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              title: 'No invoices yet',
              message: 'Create your first invoice to get paid faster.',
              icon: Icons.receipt_long_outlined,
            );
          }
          final sorted = [...list]
            ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(invoicesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: sorted.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return const ResponsiveContent(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.xxl),
                      child: PremiumScreenHeader(
                        title: 'Invoices',
                        subtitle: 'Track sent, paid and overdue work.',
                        icon: Icons.receipt_long_rounded,
                      ),
                    ),
                  );
                }
                final inv = sorted[i - 1];
                final currency =
                    NumberFormat.simpleCurrency(name: inv.currency);
                return ResponsiveContent(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AnimatedListItem(
                      index: i,
                      child: DocumentCard(
                        number: inv.invoiceNumber,
                        customerName: inv.customerName,
                        meta: 'Due ${dateFmt.format(inv.dueDate)}',
                        amount: currency.format(inv.total),
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
              },
            ),
          );
        },
      ),
    );
  }
}
