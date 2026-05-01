import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../shared/models/business_profile.dart';
import '../../../shared/models/invoice.dart';
import '../../../shared/models/quotation.dart';

/// Generates branded PDFs for invoices and quotations.
class DocumentPdfService {
  const DocumentPdfService();

  Future<Uint8List> buildInvoicePdf({
    required Invoice invoice,
    required BusinessProfile? business,
  }) async {
    final dateFmt = DateFormat.yMMMd();
    final currency = NumberFormat.simpleCurrency(name: invoice.currency);
    return _buildDocument(
      title: 'INVOICE',
      number: invoice.invoiceNumber,
      issueDate: invoice.issueDate,
      secondaryDateLabel: 'Due',
      secondaryDate: invoice.dueDate,
      customerName: invoice.customerName,
      currency: currency,
      dateFmt: dateFmt,
      items: invoice.items
          .map((i) => _Line(
                name: i.itemName,
                description: i.description,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
              ))
          .toList(),
      subtotal: invoice.subtotal,
      discount: invoice.discountAmount,
      taxLabel: invoice.taxRate > 0
          ? 'Tax (${(invoice.taxRate * 100).toStringAsFixed(2)}%)'
          : null,
      taxAmount: invoice.taxRate > 0 ? invoice.taxAmount : 0,
      total: invoice.total,
      amountPaid: invoice.amountPaid,
      balanceDue: invoice.balanceDue,
      notes: invoice.notes,
      paymentInstructions:
          invoice.paymentInstructions ?? business?.paymentInstructions,
      business: business,
      statusLabel: invoice.status.label,
    );
  }

  Future<Uint8List> buildQuotationPdf({
    required Quotation quotation,
    required BusinessProfile? business,
  }) async {
    final dateFmt = DateFormat.yMMMd();
    final currency = NumberFormat.simpleCurrency(name: quotation.currency);
    return _buildDocument(
      title: 'QUOTATION',
      number: quotation.quotationNumber,
      issueDate: quotation.issueDate,
      secondaryDateLabel: 'Valid until',
      secondaryDate: quotation.validUntil,
      customerName: quotation.customerName,
      currency: currency,
      dateFmt: dateFmt,
      items: quotation.items
          .map((i) => _Line(
                name: i.itemName,
                description: i.description,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
              ))
          .toList(),
      subtotal: quotation.subtotal,
      discount: quotation.discountAmount,
      taxLabel: quotation.taxRate > 0
          ? 'Tax (${(quotation.taxRate * 100).toStringAsFixed(2)}%)'
          : null,
      taxAmount: quotation.taxRate > 0 ? quotation.taxAmount : 0,
      total: quotation.total,
      amountPaid: 0,
      balanceDue: 0,
      notes: quotation.notes,
      paymentInstructions:
          quotation.paymentInstructions ?? business?.paymentInstructions,
      business: business,
      statusLabel: quotation.status.label,
    );
  }

  Future<Uint8List> _buildDocument({
    required String title,
    required String number,
    required DateTime issueDate,
    required String secondaryDateLabel,
    required DateTime secondaryDate,
    required String customerName,
    required NumberFormat currency,
    required DateFormat dateFmt,
    required List<_Line> items,
    required double subtotal,
    required double discount,
    required String? taxLabel,
    required double taxAmount,
    required double total,
    required double amountPaid,
    required double balanceDue,
    required String? notes,
    required String? paymentInstructions,
    required BusinessProfile? business,
    required String statusLabel,
  }) async {
    final doc = pw.Document();
    const accent = PdfColor.fromInt(0xFF6366F1);
    const grey = PdfColor.fromInt(0xFF6B7280);

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          // Header
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    business?.businessName ?? 'Your Business',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  if (business?.address != null)
                    pw.Text(business!.address!,
                        style:
                            const pw.TextStyle(color: grey, fontSize: 10)),
                  if (business?.email != null)
                    pw.Text(business!.email!,
                        style:
                            const pw.TextStyle(color: grey, fontSize: 10)),
                  if (business?.phone != null)
                    pw.Text(business!.phone!,
                        style:
                            const pw.TextStyle(color: grey, fontSize: 10)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(title,
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: accent,
                      )),
                  pw.SizedBox(height: 4),
                  pw.Text('# $number',
                      style:
                          pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(statusLabel,
                      style: const pw.TextStyle(color: grey, fontSize: 11)),
                ],
              ),
            ],
          ),
          pw.Divider(color: accent, thickness: 1.5),
          pw.SizedBox(height: 12),

          // Bill to + meta
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BILL TO',
                      style: const pw.TextStyle(color: grey, fontSize: 10)),
                  pw.SizedBox(height: 2),
                  pw.Text(customerName,
                      style:
                          pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Issue date: ${dateFmt.format(issueDate)}'),
                  pw.Text(
                      '$secondaryDateLabel: ${dateFmt.format(secondaryDate)}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),

          // Items table
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: accent),
            cellAlignments: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            headers: const ['Item', 'Qty', 'Unit price', 'Total'],
            data: items
                .map((i) => [
                      i.description == null || i.description!.isEmpty
                          ? i.name
                          : '${i.name}\n${i.description!}',
                      i.quantity.toStringAsFixed(2),
                      currency.format(i.unitPrice),
                      currency.format(i.lineTotal),
                    ])
                .toList(),
          ),

          pw.SizedBox(height: 18),

          // Totals
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.SizedBox(
                width: 240,
                child: pw.Column(
                  children: [
                    _row('Subtotal', currency.format(subtotal)),
                    if (discount > 0)
                      _row('Discount', '- ${currency.format(discount)}'),
                    if (taxLabel != null)
                      _row(taxLabel, currency.format(taxAmount)),
                    pw.Divider(),
                    _row(
                      'Total',
                      currency.format(total),
                      bold: true,
                      color: accent,
                    ),
                    if (amountPaid > 0) ...[
                      _row('Paid', currency.format(amountPaid)),
                      _row('Balance due', currency.format(balanceDue),
                          bold: true),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (notes != null && notes.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text('Notes',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(notes, style: const pw.TextStyle(fontSize: 10)),
          ],

          if (paymentInstructions != null && paymentInstructions.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Payment instructions',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(paymentInstructions,
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _row(String label, String value,
      {bool bold = false, PdfColor? color}) {
    final style = pw.TextStyle(
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}

class _Line {
  _Line({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.description,
  });

  final String name;
  final String? description;
  final double quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;
}
