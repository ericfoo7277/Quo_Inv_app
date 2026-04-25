import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../shared/providers/customers_provider.dart';
import '../../../shared/providers/invoices_provider.dart';
import '../../../shared/providers/quotations_provider.dart';
import 'widgets/customer_document_section.dart';
import 'widgets/customer_profile_card.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(customerByIdProvider(id));
    final invoices = ref.watch(invoicesByCustomerProvider(id));
    final quotations = ref.watch(quotationsByCustomerProvider(id));

    return Scaffold(
      appBar: AppBar(),
      body: AsyncValueView(
        value: customer,
        onRetry: () => ref.invalidate(customerByIdProvider(id)),
        data: (c) {
          if (c == null) {
            return const EmptyState(
                title: 'Customer not found', icon: Icons.error_outline);
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              ResponsiveContent(
                child: PremiumScreenHeader(
                  title: c.name,
                  subtitle: c.companyName ?? c.email,
                  icon: Icons.people_alt_rounded,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ResponsiveContent(child: CustomerProfileCard(customer: c)),
              const SizedBox(height: AppSpacing.xxl),
              ResponsiveContent(
                child: AsyncValueView(
                  value: invoices,
                  data: (list) =>
                      CustomerDocumentSection.invoices(invoices: list),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ResponsiveContent(
                child: AsyncValueView(
                  value: quotations,
                  data: (list) =>
                      CustomerDocumentSection.quotations(quotations: list),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
