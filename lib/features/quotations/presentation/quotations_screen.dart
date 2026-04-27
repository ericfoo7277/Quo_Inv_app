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
import '../../../shared/models/quotation.dart';
import '../../../shared/providers/quotations_provider.dart';

class QuotationsScreen extends ConsumerWidget {
  const QuotationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotations = ref.watch(quotationsProvider);
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Quotations')),
      body: AsyncValueView(
        value: quotations,
        onRetry: () => ref.invalidate(quotationsProvider),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              title: 'No quotations yet',
              message: 'Build a polished quote in minutes.',
              icon: Icons.description_outlined,
            );
          }
          final sorted = [...list]
            ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(quotationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: sorted.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return const ResponsiveContent(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.xxl),
                      child: PremiumScreenHeader(
                        title: 'Quotations',
                        subtitle: 'Build polished proposals and convert wins.',
                        icon: Icons.description_rounded,
                      ),
                    ),
                  );
                }
                final q = sorted[i - 1];
                final currency = NumberFormat.simpleCurrency(name: q.currency);
                return ResponsiveContent(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AnimatedListItem(
                      index: i,
                      child: DocumentCard(
                        number: q.quotationNumber,
                        customerName: q.customerName,
                        meta: 'Valid until ${dateFmt.format(q.validUntil)}',
                        amount: currency.format(q.total),
                        statusLabel: q.status.label,
                        statusColor: q.status.color,
                        icon: Icons.description_rounded,
                        onTap: () => context.goNamed(
                          RouteNames.quotationDetail,
                          pathParameters: {'id': q.id},
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
