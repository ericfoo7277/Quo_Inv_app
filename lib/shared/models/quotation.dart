import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum QuotationStatus { draft, sent, accepted, declined, expired }

extension QuotationStatusX on QuotationStatus {
  String get label {
    switch (this) {
      case QuotationStatus.draft:
        return 'Draft';
      case QuotationStatus.sent:
        return 'Sent';
      case QuotationStatus.accepted:
        return 'Accepted';
      case QuotationStatus.declined:
        return 'Declined';
      case QuotationStatus.expired:
        return 'Expired';
    }
  }

  Color get color {
    switch (this) {
      case QuotationStatus.draft:
        return AppColors.lightTextSecondary;
      case QuotationStatus.sent:
        return AppColors.info;
      case QuotationStatus.accepted:
        return AppColors.success;
      case QuotationStatus.declined:
        return AppColors.error;
      case QuotationStatus.expired:
        return AppColors.warning;
    }
  }
}

class QuotationLineItem {
  const QuotationLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  final String description;
  final double quantity;
  final double unitPrice;

  double get total => quantity * unitPrice;
}

class Quotation {
  const Quotation({
    required this.id,
    required this.number,
    required this.customerId,
    required this.customerName,
    required this.issueDate,
    required this.validUntil,
    required this.items,
    required this.status,
    this.taxRate = 0,
    this.notes,
    this.currency = 'USD',
  });

  final String id;
  final String number;
  final String customerId;
  final String customerName;
  final DateTime issueDate;
  final DateTime validUntil;
  final List<QuotationLineItem> items;
  final QuotationStatus status;
  final double taxRate;
  final String? notes;
  final String currency;

  double get subtotal => items.fold(0, (s, i) => s + i.total);
  double get tax => subtotal * taxRate;
  double get total => subtotal + tax;

  Quotation copyWith({
    String? id,
    String? number,
    String? customerId,
    String? customerName,
    DateTime? issueDate,
    DateTime? validUntil,
    List<QuotationLineItem>? items,
    QuotationStatus? status,
    double? taxRate,
    String? notes,
    String? currency,
  }) {
    return Quotation(
      id: id ?? this.id,
      number: number ?? this.number,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      issueDate: issueDate ?? this.issueDate,
      validUntil: validUntil ?? this.validUntil,
      items: items ?? this.items,
      status: status ?? this.status,
      taxRate: taxRate ?? this.taxRate,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
    );
  }
}
