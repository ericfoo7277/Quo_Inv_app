import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../../../../core/widgets/document_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../shared/models/invoice.dart';
import '../../../../shared/models/quotation.dart';

class CustomerDocumentSection extends StatelessWidget {
  const CustomerDocumentSection.invoices({
    super.key,
    required this.invoices,
  })  : quotations = null,
        title = 'Invoices';

  const CustomerDocumentSection.quotations({
    super.key,
    required this.quotations,
  })  : invoices = null,
        title = 'Quotations';

  final List<Invoice>? invoices;
  final List<Quotation>? quotations;
  final String title;

  @override
  Widget build(BuildContext context) {
    final invoiceList = invoices;
    final quotationList = quotations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.md),
        if ((invoiceList?.isEmpty ?? false) ||
            (quotationList?.isEmpty ?? false))
          Text(
            'No ${title.toLowerCase()} for this customer.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else if (invoiceList != null)
          ...invoiceList.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AnimatedListItem(
                    index: entry.key,
                    child: DocumentCard(
                      number: entry.value.invoiceNumber,
                      customerName: entry.value.customerName,
                      meta: 'Due ${_date(entry.value.dueDate)}',
                      amount: _currency(
                          context, entry.value.currency, entry.value.total),
                      statusLabel: entry.value.status.label,
                      statusColor: entry.value.status.color,
                      icon: Icons.receipt_long_rounded,
                      onTap: () => context.pushNamed(
                        RouteNames.invoiceDetail,
                        pathParameters: {'id': entry.value.id},
                      ),
                    ),
                  ),
                ),
              )
        else if (quotationList != null)
          ...quotationList.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AnimatedListItem(
                    index: entry.key,
                    child: DocumentCard(
                      number: entry.value.quotationNumber,
                      customerName: entry.value.customerName,
                      meta: 'Valid until ${_date(entry.value.validUntil)}',
                      amount: _currency(
                          context, entry.value.currency, entry.value.total),
                      statusLabel: entry.value.status.label,
                      statusColor: entry.value.status.color,
                      icon: Icons.description_rounded,
                      onTap: () => context.pushNamed(
                        RouteNames.quotationDetail,
                        pathParameters: {'id': entry.value.id},
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  String _date(DateTime value) {
    return '${value.day}/${value.month}/${value.year}';
  }

  String _currency(BuildContext context, String code, double amount) {
    return MaterialLocalizations.of(context).formatDecimal(amount.round()) ==
            amount.round().toString()
        ? '$code ${amount.toStringAsFixed(0)}'
        : '$code ${amount.toStringAsFixed(2)}';
  }
}
