import 'pdf_template.dart';

/// Business profile for a single user / workspace.
///
/// Schema: business_profiles(id, user_id, business_name, phone, email,
///   address, logo_url, currency, payment_instructions,
///   default_quotation_notes, default_invoice_notes, quotation_prefix,
///   invoice_prefix, quotation_next_number, invoice_next_number,
///   timezone, pdf_template, subscription_tier, created_at, updated_at)
class BusinessProfile {
  const BusinessProfile({
    required this.id,
    required this.businessName,
    this.userId,
    this.phone,
    this.email,
    this.address,
    this.logoUrl,
    this.currency = 'MYR',
    this.paymentInstructions,
    this.defaultQuotationNotes,
    this.defaultInvoiceNotes,
    this.quotationPrefix = 'Q-',
    this.invoicePrefix = 'INV-',
    this.quotationNextNumber = 1,
    this.invoiceNextNumber = 1,
    this.timezone = 'Asia/Kuala_Lumpur',
    this.pdfTemplate = PdfTemplate.classic,
    this.subscriptionTier = 'free',
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// Supabase auth user id. Null in mock mode.
  final String? userId;

  final String businessName;
  final String? phone;
  final String? email;
  final String? address;

  /// URL of the business logo stored in Supabase Storage.
  final String? logoUrl;

  /// ISO 4217 currency code, e.g. "USD".
  final String currency;

  /// Default payment instructions appended to invoices and quotations.
  final String? paymentInstructions;

  /// Default notes block for new quotations.
  final String? defaultQuotationNotes;

  /// Default notes block for new invoices.
  final String? defaultInvoiceNotes;

  /// Prefix for quotation numbers, e.g. "QUO".
  final String quotationPrefix;

  /// Prefix for invoice numbers, e.g. "INV".
  final String invoicePrefix;

  /// Next auto-increment value for quotation numbering.
  final int quotationNextNumber;

  /// Next auto-increment value for invoice numbering.
  final int invoiceNextNumber;

  /// IANA timezone identifier, e.g. "America/New_York".
  final String timezone;

  /// PDF layout template used when generating invoices and quotations.
  final PdfTemplate pdfTemplate;

  /// Subscription tier: 'free' or 'pro'. Set server-side only.
  final String subscriptionTier;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  BusinessProfile copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? phone,
    String? email,
    String? address,
    String? logoUrl,
    String? currency,
    String? paymentInstructions,
    String? defaultQuotationNotes,
    String? defaultInvoiceNotes,
    String? quotationPrefix,
    String? invoicePrefix,
    int? quotationNextNumber,
    int? invoiceNextNumber,
    String? timezone,
    PdfTemplate? pdfTemplate,
    String? subscriptionTier,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      logoUrl: logoUrl ?? this.logoUrl,
      currency: currency ?? this.currency,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      defaultQuotationNotes:
          defaultQuotationNotes ?? this.defaultQuotationNotes,
      defaultInvoiceNotes: defaultInvoiceNotes ?? this.defaultInvoiceNotes,
      quotationPrefix: quotationPrefix ?? this.quotationPrefix,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      quotationNextNumber: quotationNextNumber ?? this.quotationNextNumber,
      invoiceNextNumber: invoiceNextNumber ?? this.invoiceNextNumber,
      timezone: timezone ?? this.timezone,
      pdfTemplate: pdfTemplate ?? this.pdfTemplate,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
