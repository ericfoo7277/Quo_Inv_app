import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum InvoiceStatus { draft, sent, paid, overdue, cancelled }

extension InvoiceStatusX on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case InvoiceStatus.draft:
        return AppColors.lightTextSecondary;
      case InvoiceStatus.sent:
        return AppColors.info;
      case InvoiceStatus.paid:
        return AppColors.success;
      case InvoiceStatus.overdue:
        return AppColors.error;
      case InvoiceStatus.cancelled:
        return AppColors.lightTextSecondary;
    }
  }
}

class InvoiceLineItem {
  const InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  final String description;
  final double quantity;
  final double unitPrice;

  double get total => quantity * unitPrice;
}

class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.customerId,
    required this.customerName,
    required this.issueDate,
    required this.dueDate,
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
  final DateTime dueDate;
  final List<InvoiceLineItem> items;
  final InvoiceStatus status;
  final double taxRate;
  final String? notes;
  final String currency;

  double get subtotal => items.fold(0, (s, i) => s + i.total);
  double get tax => subtotal * taxRate;
  double get total => subtotal + tax;

  Invoice copyWith({
    String? id,
    String? number,
    String? customerId,
    String? customerName,
    DateTime? issueDate,
    DateTime? dueDate,
    List<InvoiceLineItem>? items,
    InvoiceStatus? status,
    double? taxRate,
    String? notes,
    String? currency,
  }) {
    return Invoice(
      id: id ?? this.id,
      number: number ?? this.number,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      status: status ?? this.status,
      taxRate: taxRate ?? this.taxRate,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
    );
  }
}
