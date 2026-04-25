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

/// A single line item within a quotation.
///
/// Schema: quotation_items(id, quotation_id, user_id, item_name, description,
///   quantity, unit_price, line_total, sort_order, created_at)
class QuotationLineItem {
  const QuotationLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.id,
    this.itemName,
    this.sortOrder = 0,
    this.createdAt,
  });

  /// Supabase row id. Null for unsaved / locally-created items.
  final String? id;

  /// Short display name / title for the line item (maps to item_name).
  final String? itemName;

  final String description;
  final double quantity;
  final double unitPrice;
  final int sortOrder;
  final DateTime? createdAt;

  double get lineTotal => quantity * unitPrice;

  /// Alias kept for backward compatibility with code that uses [total].
  double get total => lineTotal;
}

/// Quotation domain entity.
///
/// Schema: quotations(id, user_id, customer_id, quotation_number, issue_date,
///   valid_until, currency, subtotal, discount_amount, total_amount, notes,
///   payment_instructions, status, converted_invoice_id, created_at, updated_at)
class Quotation {
  const Quotation({
    required this.id,
    required this.quotationNumber,
    required this.customerId,
    required this.customerName,
    required this.issueDate,
    required this.validUntil,
    required this.items,
    required this.status,
    this.userId,
    this.taxRate = 0,
    this.discountAmount = 0,
    this.notes,
    this.paymentInstructions,
    this.convertedInvoiceId,
    this.currency = 'USD',
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// Supabase auth user id. Null in mock mode.
  final String? userId;

  /// Human-readable document number, e.g. "QUO-2026-001".
  final String quotationNumber;

  final String customerId;

  /// Denormalised customer display name for quick rendering.
  final String customerName;

  final DateTime issueDate;
  final DateTime validUntil;
  final List<QuotationLineItem> items;
  final QuotationStatus status;

  /// Tax rate as a fraction (e.g. 0.19 for 19 %). Not stored in schema but
  /// drives [taxAmount] computation.
  final double taxRate;

  /// Flat discount applied before tax.
  final double discountAmount;

  final String? notes;
  final String? paymentInstructions;

  /// Set once this quotation has been converted to an invoice.
  final String? convertedInvoiceId;

  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get subtotal => items.fold(0, (s, i) => s + i.lineTotal);
  double get taxAmount => (subtotal - discountAmount) * taxRate;
  double get totalAmount => subtotal - discountAmount + taxAmount;

  /// Alias kept for backward compatibility.
  double get total => totalAmount;

  Quotation copyWith({
    String? id,
    String? userId,
    String? quotationNumber,
    String? customerId,
    String? customerName,
    DateTime? issueDate,
    DateTime? validUntil,
    List<QuotationLineItem>? items,
    QuotationStatus? status,
    double? taxRate,
    double? discountAmount,
    String? notes,
    String? paymentInstructions,
    String? convertedInvoiceId,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quotation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      quotationNumber: quotationNumber ?? this.quotationNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      issueDate: issueDate ?? this.issueDate,
      validUntil: validUntil ?? this.validUntil,
      items: items ?? this.items,
      status: status ?? this.status,
      taxRate: taxRate ?? this.taxRate,
      discountAmount: discountAmount ?? this.discountAmount,
      notes: notes ?? this.notes,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      convertedInvoiceId: convertedInvoiceId ?? this.convertedInvoiceId,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
