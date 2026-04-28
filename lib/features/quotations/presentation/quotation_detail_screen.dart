import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/models/quotation.dart';
import '../../../shared/providers/quotations_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../documents/presentation/widgets/document_header_card.dart';
import '../../documents/presentation/widgets/document_totals_card.dart';

class QuotationDetailScreen extends ConsumerWidget {
  const QuotationDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(quotationByIdProvider(id));
    final dateFmt = DateFormat.yMMMd();
    final appBarTitle = quoteAsync.maybeWhen(
      data: (q) => q == null
          ? 'Quotation'
          : 'Quotation ${q.quotationNumber} • ${q.status.label}',
      orElse: () => 'Quotation',
    );

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: AsyncValueView(
        value: quoteAsync,
        onRetry: () => ref.invalidate(quotationByIdProvider(id)),
        data: (q) {
          if (q == null) {
            return const EmptyState(
                title: 'Quotation not found', icon: Icons.error_outline);
          }
          final currency = NumberFormat.simpleCurrency(name: q.currency);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              ResponsiveContent(
                child: PremiumScreenHeader(
                  title: q.quotationNumber,
                  subtitle: 'Quotation details and conversion actions',
                  icon: Icons.description_rounded,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ResponsiveContent(
                child: DocumentHeaderCard(
                  title: q.customerName,
                  subtitle: 'Valid until ${dateFmt.format(q.validUntil)}',
                  statusLabel: q.status.label,
                  statusColor: q.status.color,
                  onTap: () => context.pushNamed(
                    RouteNames.customerDetail,
                    pathParameters: {'id': q.customerId},
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ResponsiveContent(
                child: DocumentTotalsCard.quotation(
                  quotationItems: q.items,
                  currency: currency,
                  total: q.total,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ResponsiveContent(
                child: PrimaryButton(
                  label: 'Convert to invoice',
                  icon: Icons.swap_horiz_rounded,
                  onPressed: () async {
                    final repo = ref.read(quotationRepositoryProvider);
                    try {
                      final newId = await repo.convertToInvoice(q.id);
                      if (!context.mounted) return;
                      context.goNamed(
                        RouteNames.invoiceDetail,
                        pathParameters: {'id': newId},
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Conversion failed: $e')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ResponsiveContent(
                child: SecondaryButton(
                  label: 'Send to customer',
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
