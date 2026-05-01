import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/animated_list_item.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/customer_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../shared/providers/customers_provider.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.goNamed(RouteNames.customerForm),
          ),
        ],
      ),
      body: AsyncValueView(
        value: customers,
        onRetry: () => ref.invalidate(customersProvider),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: 'No customers yet',
              message: 'Add your first customer to start sending quotations and invoices.',
              icon: Icons.people_outline_rounded,
              action: FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add customer'),
                onPressed: () => context.goNamed(RouteNames.customerForm),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(customersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: list.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return const ResponsiveContent(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.xxl),
                      child: PremiumScreenHeader(
                        title: 'Customers',
                        subtitle: 'Your billable relationships, organized.',
                        icon: Icons.people_alt_rounded,
                      ),
                    ),
                  );
                }
                final c = list[i - 1];
                return ResponsiveContent(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AnimatedListItem(
                      index: i,
                      child: CustomerCard(
                        customer: c,
                        onTap: () => context.goNamed(
                          RouteNames.customerDetail,
                          pathParameters: {'id': c.id},
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
