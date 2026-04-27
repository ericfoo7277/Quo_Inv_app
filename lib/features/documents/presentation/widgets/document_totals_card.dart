import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/models/invoice.dart';
import '../../../../shared/models/quotation.dart';

class DocumentTotalsCard extends StatelessWidget {
  const DocumentTotalsCard.invoice({
    super.key,
    required this.invoiceItems,
    required this.currency,
    required this.subtotal,
    required this.total,
    this.tax,
    this.taxLabel,
  }) : quotationItems = null;

  const DocumentTotalsCard.quotation({
    super.key,
    required this.quotationItems,
    required this.currency,
    required this.total,
  })  : invoiceItems = null,
        subtotal = null,
        tax = null,
        taxLabel = null;

  final List<InvoiceLineItem>? invoiceItems;
  final List<QuotationLineItem>? quotationItems;
  final NumberFormat currency;
  final double? subtotal;
  final double? tax;
  final String? taxLabel;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = invoiceItems != null
        ? invoiceItems!
            .map((item) => _LineRow(
                  description: item.itemName,
                  meta:
                      '${_qty(item.quantity)} × ${currency.format(item.unitPrice)}',
                  amount: currency.format(item.total),
                ))
            .toList(growable: false)
        : quotationItems!
            .map((item) => _LineRow(
                  description: item.itemName,
                  meta:
                      '${_qty(item.quantity)} × ${currency.format(item.unitPrice)}',
                  amount: currency.format(item.total),
                ))
            .toList(growable: false);

    return AppCard(
      child: Column(
        children: [
          for (final row in rows) ...[
            row,
            const Divider(height: AppSpacing.xxl),
          ],
          if (subtotal != null) ...[
            _SummaryRow(label: 'Subtotal', value: currency.format(subtotal!)),
            if (tax != null && taxLabel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _SummaryRow(label: taxLabel!, value: currency.format(tax!)),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: theme.textTheme.titleLarge),
              Text(currency.format(total), style: theme.textTheme.titleLarge),
            ],
          ),
        ],
      ),
    );
  }

  String _qty(double quantity) {
    return quantity.truncateToDouble() == quantity
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(2);
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.description,
    required this.meta,
    required this.amount,
  });

  final String description;
  final String meta;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(meta, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        Text(amount, style: theme.textTheme.titleSmall),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(value)],
    );
  }
}
