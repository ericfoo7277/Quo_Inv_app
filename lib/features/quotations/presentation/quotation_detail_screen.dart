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
import '../../../core/widgets/secondary_button.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/models/quotation.dart';
import '../../../shared/providers/business_profile_provider.dart';
import '../../../shared/providers/quotations_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/utils/currency_format.dart';
import '../../documents/presentation/widgets/document_actions_menu.dart';
import '../../documents/presentation/widgets/document_header_card.dart';
import '../../documents/presentation/widgets/document_totals_card.dart';

class QuotationDetailScreen extends ConsumerWidget {
  const QuotationDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final quoteAsync = ref.watch(quotationByIdProvider(id));
    final business = ref.watch(businessProfileProvider).value;
    final dateFmt = DateFormat.yMMMd();
    final appBarTitle = quoteAsync.maybeWhen(
      data: (q) => q == null
          ? 'Quotation'
          : 'Quotation ${q.quotationNumber} • ${q.status.label}',
      orElse: () => 'Quotation',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          if (quoteAsync.value != null)
            DocumentActionsMenu.quotation(
              quotation: quoteAsync.value!,
              business: business,
              onDuplicate: () => _duplicate(context, ref, quoteAsync.value!),
            ),
        ],
      ),
      body: AsyncValueView(
        value: quoteAsync,
        onRetry: () => ref.invalidate(quotationByIdProvider(id)),
        data: (q) {
          if (q == null) {
            return const EmptyState(
                title: 'Quotation not found', icon: Icons.error_outline);
          }
          final currency = AppCurrencyFormat.formatter(
            business?.currency ?? q.currency,
          );
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
              if (q.notes != null || q.paymentInstructions != null) ...[
                const SizedBox(height: AppSpacing.lg),
                ResponsiveContent(
                  child: SizedBox(
                    width: double.infinity,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (q.notes != null) ...[
                            Text('Notes', style: theme.textTheme.titleSmall),
                            const SizedBox(height: AppSpacing.xs),
                            Text(q.notes!, style: theme.textTheme.bodyMedium),
                          ],
                          if (q.notes != null &&
                              q.paymentInstructions != null)
                            const SizedBox(height: AppSpacing.lg),
                          if (q.paymentInstructions != null) ...[
                            Text('Payment instructions',
                                style: theme.textTheme.titleSmall),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              q.paymentInstructions!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
                  onPressed: () => DocumentActionsMenu.showSendSheet(
                    context,
                    ref,
                    quotation: q,
                    business: business,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _duplicate(
    BuildContext context,
    WidgetRef ref,
    Quotation source,
  ) async {
    try {
      final today = DateTime.now();
      final validity = source.validUntil
          .difference(source.issueDate)
          .inDays
          .abs();
      final copy = source.copyWith(
        id: '',
        quotationNumber: '', // triggers backend auto-numbering
        status: QuotationStatus.draft,
        convertedInvoiceId: null,
        issueDate: today,
        validUntil: today.add(Duration(days: validity)),
        createdAt: null,
        updatedAt: null,
      );
      final created =
          await ref.read(quotationRepositoryProvider).create(copy);
      if (!context.mounted) return;
      context.pushReplacementNamed(
        RouteNames.quotationDetail,
        pathParameters: {'id': created.id},
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Duplicate failed: $e')),
      );
    }
  }
}
