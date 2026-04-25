import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../shared/models/invoice.dart';
import '../../../shared/providers/invoices_provider.dart';
import '../../documents/presentation/widgets/document_header_card.dart';
import '../../documents/presentation/widgets/document_totals_card.dart';
import '../../../core/router/route_names.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final invoiceAsync = ref.watch(invoiceByIdProvider(id));
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: AsyncValueView(
        value: invoiceAsync,
        onRetry: () => ref.invalidate(invoiceByIdProvider(id)),
        data: (inv) {
          if (inv == null) {
            return const EmptyState(
                title: 'Invoice not found', icon: Icons.error_outline);
          }
          final currency = NumberFormat.simpleCurrency(name: inv.currency);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              ResponsiveContent(
                child: PremiumScreenHeader(
                  title: inv.number,
                  subtitle: 'Invoice details and payment summary',
                  icon: Icons.receipt_long_rounded,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ResponsiveContent(
                child: DocumentHeaderCard(
                  title: inv.customerName,
                  subtitle:
                      'Issued ${dateFmt.format(inv.issueDate)}  •  Due ${dateFmt.format(inv.dueDate)}',
                  statusLabel: inv.status.label,
                  statusColor: inv.status.color,
                  onTap: () => context.goNamed(
                    RouteNames.customerDetail,
                    pathParameters: {'id': inv.customerId},
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ResponsiveContent(
                child: DocumentTotalsCard.invoice(
                  invoiceItems: inv.items,
                  currency: currency,
                  subtotal: inv.subtotal,
                  tax: inv.taxRate > 0 ? inv.tax : null,
                  taxLabel: inv.taxRate > 0
                      ? 'Tax (${(inv.taxRate * 100).toStringAsFixed(2)}%)'
                      : null,
                  total: inv.total,
                ),
              ),
              if (inv.notes != null) ...[
                const SizedBox(height: AppSpacing.lg),
                ResponsiveContent(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notes', style: theme.textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(inv.notes!, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              ResponsiveContent(
                child: PrimaryButton(
                  label: 'Send reminder',
                  icon: Icons.send_rounded,
                  onPressed: () {},
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
