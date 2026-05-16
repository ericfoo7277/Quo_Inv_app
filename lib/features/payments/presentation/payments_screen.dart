import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../shared/models/payment.dart';
import '../../../shared/providers/business_profile_provider.dart';
import '../../../shared/providers/payments_provider.dart';
import '../../../shared/utils/currency_format.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final payments = ref.watch(paymentsProvider);
    final businessCurrency = ref.watch(businessProfileProvider).value?.currency;
    final currency = AppCurrencyFormat.formatter(businessCurrency);
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: AsyncValueView(
        value: payments,
        onRetry: () => ref.invalidate(paymentsProvider),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              title: 'No payments yet',
              message: 'Payments you record against invoices will appear here.',
              icon: Icons.payments_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: list.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return const ResponsiveContent(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.xxl),
                    child: PremiumScreenHeader(
                      title: 'Payments',
                      subtitle: 'A clean ledger of money received.',
                      icon: Icons.payments_rounded,
                    ),
                  ),
                );
              }
              final p = list[i - 1];
              return ResponsiveContent(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    child: Row(
                      children: [
                        Icon(_iconFor(p.paymentMethod),
                            color: theme.colorScheme.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.invoiceNumber ?? p.invoiceId,
                                  style: theme.textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Text(
                              '${p.customerName ?? ''}  •  ${dateFmt.format(p.paymentDate)}',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Text(currency.format(p.amount),
                            style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.bank:
        return Icons.account_balance_rounded;
      case PaymentMethod.cash:
        return Icons.payments_rounded;
      case PaymentMethod.other:
        return Icons.attach_money_rounded;
    }
  }
}
