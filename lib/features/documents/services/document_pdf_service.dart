import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../shared/models/business_profile.dart';
import '../../../shared/models/invoice.dart';
import '../../../shared/models/pdf_template.dart';
import '../../../shared/models/quotation.dart';
import '../../../shared/utils/currency_format.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared colours used across templates
// ─────────────────────────────────────────────────────────────────────────────
const _kAccent = PdfColor.fromInt(0xFF6366F1); // indigo
const _kGrey = PdfColor.fromInt(0xFF6B7280);
const _kLightGrey = PdfColor.fromInt(0xFFF3F4F6);
const _kDarkGrey = PdfColor.fromInt(0xFF374151);

/// Generates branded PDFs for invoices and quotations.
///
/// The active template is read from [BusinessProfile.pdfTemplate]. Defaults to
/// [PdfTemplate.classic] when no business profile is available.
class DocumentPdfService {
  const DocumentPdfService();

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<Uint8List> buildInvoicePdf({
    required Invoice invoice,
    required BusinessProfile? business,
  }) async {
    final dateFmt = DateFormat.yMMMd();
    final currency = AppCurrencyFormat.formatter(
      business?.currency ?? invoice.currency,
    );
    final params = _DocParams(
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
      showWatermark: (business?.subscriptionTier ?? 'free') != 'pro',
    );
    return _dispatch(params, business?.pdfTemplate ?? PdfTemplate.classic);
  }

  Future<Uint8List> buildQuotationPdf({
    required Quotation quotation,
    required BusinessProfile? business,
  }) async {
    final dateFmt = DateFormat.yMMMd();
    final currency = AppCurrencyFormat.formatter(
      business?.currency ?? quotation.currency,
    );
    final params = _DocParams(
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
      showWatermark: (business?.subscriptionTier ?? 'free') != 'pro',
    );
    return _dispatch(params, business?.pdfTemplate ?? PdfTemplate.classic);
  }

  // ── Dispatcher ─────────────────────────────────────────────────────────────

  Future<Uint8List> _dispatch(_DocParams p, PdfTemplate template) =>
      switch (template) {
        PdfTemplate.classic => _buildClassic(p),
        PdfTemplate.modern => _buildModern(p),
        PdfTemplate.minimal => _buildMinimal(p),
      };

  // ── CLASSIC TEMPLATE ───────────────────────────────────────────────────────
  //
  // Left: business name + contact (black)
  // Right: INVOICE/QUOTATION title in BLACK (per user request), number, status
  // Indigo divider · indigo table header · indigo "Total" label
  // ──────────────────────────────────────────────────────────────────────────

  Future<Uint8List> _buildClassic(_DocParams p) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(36),
        footer: p.showWatermark
            ? (ctx) => pw.Center(
                  child: pw.Text(
                    'Generated by QuoSwift · quoswift.app',
                    style: const pw.TextStyle(color: _kGrey, fontSize: 8),
                  ),
                )
            : null,
        build: (context) => [
          // ── Header ────────────────────────────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    p.business?.businessName ?? 'Your Business',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  if (p.business?.address != null)
                    pw.Text(p.business!.address!,
                        style:
                            const pw.TextStyle(color: _kGrey, fontSize: 10)),
                  if (p.business?.email != null)
                    pw.Text(p.business!.email!,
                        style:
                            const pw.TextStyle(color: _kGrey, fontSize: 10)),
                  if (p.business?.phone != null)
                    pw.Text(p.business!.phone!,
                        style:
                            const pw.TextStyle(color: _kGrey, fontSize: 10)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    p.title,
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('# ${p.number}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(p.statusLabel,
                      style:
                          const pw.TextStyle(color: _kGrey, fontSize: 11)),
                ],
              ),
            ],
          ),

          pw.Divider(color: _kAccent, thickness: 1.5),
          pw.SizedBox(height: 12),

          // ── Bill-to + dates ───────────────────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BILL TO',
                      style:
                          const pw.TextStyle(color: _kGrey, fontSize: 10)),
                  pw.SizedBox(height: 2),
                  pw.Text(p.customerName,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Issue date: ${p.dateFmt.format(p.issueDate)}'),
                  pw.Text(
                      '${p.secondaryDateLabel}: ${p.dateFmt.format(p.secondaryDate)}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),

          // ── Items table ───────────────────────────────────────────────────
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: _kAccent),
            cellAlignments: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            headers: const ['Item', 'Qty', 'Unit price', 'Total'],
            data: p.items
                .map((i) => [
                      (i.description == null || i.description!.isEmpty)
                          ? i.name
                          : '${i.name}\n${i.description!}',
                      i.quantity.toStringAsFixed(2),
                      p.currency.format(i.unitPrice),
                      p.currency.format(i.lineTotal),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 18),

          // ── Totals ────────────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.SizedBox(
                width: 240,
                child: pw.Column(
                  children: [
                    _row('Subtotal', p.currency.format(p.subtotal)),
                    if (p.discount > 0)
                      _row('Discount',
                          '- ${p.currency.format(p.discount)}'),
                    if (p.taxLabel != null)
                      _row(p.taxLabel!, p.currency.format(p.taxAmount)),
                    pw.Divider(),
                    _row('Total', p.currency.format(p.total),
                        bold: true, color: _kAccent),
                    if (p.amountPaid > 0) ...[
                      _row('Paid', p.currency.format(p.amountPaid)),
                      _row('Balance due', p.currency.format(p.balanceDue),
                          bold: true),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ── Notes ─────────────────────────────────────────────────────────
          if (p.notes != null && p.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Text('Notes',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(p.notes!, style: const pw.TextStyle(fontSize: 10)),
          ],

          // ── Payment instructions ──────────────────────────────────────────
          if (p.paymentInstructions != null &&
              p.paymentInstructions!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Payment instructions',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(p.paymentInstructions!,
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );

    return doc.save();
  }

  // ── MODERN TEMPLATE ────────────────────────────────────────────────────────
  //
  // Full-width indigo header band: business name (left, white),
  // document title + number (right, white). Body uses a light-grey table
  // header and a light-grey background for the "Total" row.
  // ──────────────────────────────────────────────────────────────────────────

  Future<Uint8List> _buildModern(_DocParams p) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        // Zero outer margin so the header band bleeds to the page edges.
        margin: pw.EdgeInsets.zero,
        footer: p.showWatermark
            ? (ctx) => pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Text(
                      'Generated by QuoSwift · quoswift.app',
                      style: const pw.TextStyle(color: _kGrey, fontSize: 8),
                    ),
                  ),
                )
            : null,
        build: (context) => [
          // ── Full-width indigo header band ─────────────────────────────────
          pw.Container(
            color: _kAccent,
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 36, vertical: 24),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      p.business?.businessName ?? 'Your Business',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    if (p.business?.address != null)
                      pw.Text(p.business!.address!,
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 10)),
                    if (p.business?.email != null)
                      pw.Text(p.business!.email!,
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 10)),
                    if (p.business?.phone != null)
                      pw.Text(p.business!.phone!,
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      p.title,
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('# ${p.number}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          fontSize: 12,
                        )),
                    pw.Text(p.statusLabel,
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // ── Bill-to + dates ───────────────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.only(
                left: 36, right: 36, top: 20, bottom: 20),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('BILL TO',
                        style: const pw.TextStyle(
                            color: _kGrey, fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Text(p.customerName,
                        style:
                            pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                        'Issue date: ${p.dateFmt.format(p.issueDate)}'),
                    pw.Text(
                        '${p.secondaryDateLabel}: ${p.dateFmt.format(p.secondaryDate)}'),
                  ],
                ),
              ],
            ),
          ),

          // ── Items table ───────────────────────────────────────────────────
          pw.Padding(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 36),
            child: pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              headerDecoration:
                  const pw.BoxDecoration(color: _kLightGrey),
              cellAlignments: const {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              headers: const ['Item', 'Qty', 'Unit price', 'Total'],
              data: p.items
                  .map((i) => [
                        (i.description == null || i.description!.isEmpty)
                            ? i.name
                            : '${i.name}\n${i.description!}',
                        i.quantity.toStringAsFixed(2),
                        p.currency.format(i.unitPrice),
                        p.currency.format(i.lineTotal),
                      ])
                  .toList(),
            ),
          ),
          pw.SizedBox(height: 18),

          // ── Totals ────────────────────────────────────────────────────────
          pw.Padding(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 36),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(
                  width: 240,
                  child: pw.Column(
                    children: [
                      _row('Subtotal', p.currency.format(p.subtotal)),
                      if (p.discount > 0)
                        _row('Discount',
                            '- ${p.currency.format(p.discount)}'),
                      if (p.taxLabel != null)
                        _row(p.taxLabel!,
                            p.currency.format(p.taxAmount)),
                      pw.Divider(),
                      pw.Container(
                        color: _kLightGrey,
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 5, horizontal: 4),
                        child: pw.Row(
                          mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text(p.currency.format(p.total),
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                      if (p.amountPaid > 0) ...[
                        _row('Paid', p.currency.format(p.amountPaid)),
                        _row('Balance due',
                            p.currency.format(p.balanceDue),
                            bold: true),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Notes ─────────────────────────────────────────────────────────
          if (p.notes != null && p.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 36),
              child: pw.Text('Notes',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 2),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 36),
              child: pw.Text(p.notes!,
                  style: const pw.TextStyle(fontSize: 10)),
            ),
          ],

          // ── Payment instructions ──────────────────────────────────────────
          if (p.paymentInstructions != null &&
              p.paymentInstructions!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 36),
              child: pw.Text('Payment instructions',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 2),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 36),
              child: pw.Text(p.paymentInstructions!,
                  style: const pw.TextStyle(fontSize: 10)),
            ),
          ],

          pw.SizedBox(height: 36),
        ],
      ),
    );

    return doc.save();
  }

  // ── MINIMAL TEMPLATE ───────────────────────────────────────────────────────
  //
  // All black & white. Large bold title (left), business name (right).
  // Thin grey dividers instead of coloured accents. Table: no background —
  // only grey dividers above/below to frame it. Totals right-aligned with a
  // thin divider before the total row.
  // ──────────────────────────────────────────────────────────────────────────

  Future<Uint8List> _buildMinimal(_DocParams p) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(48),
        footer: p.showWatermark
            ? (ctx) => pw.Center(
                  child: pw.Text(
                    'Generated by QuoSwift · quoswift.app',
                    style: const pw.TextStyle(color: _kGrey, fontSize: 8),
                  ),
                )
            : null,
        build: (context) => [
          // ── Header ────────────────────────────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    p.title,
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('# ${p.number}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: _kDarkGrey,
                        fontSize: 11,
                      )),
                  pw.Text(p.statusLabel,
                      style:
                          const pw.TextStyle(color: _kGrey, fontSize: 10)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    p.business?.businessName ?? 'Your Business',
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                  if (p.business?.address != null)
                    pw.Text(p.business!.address!,
                        style: const pw.TextStyle(
                            color: _kGrey, fontSize: 10)),
                  if (p.business?.email != null)
                    pw.Text(p.business!.email!,
                        style: const pw.TextStyle(
                            color: _kGrey, fontSize: 10)),
                  if (p.business?.phone != null)
                    pw.Text(p.business!.phone!,
                        style: const pw.TextStyle(
                            color: _kGrey, fontSize: 10)),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 24),
          pw.Divider(color: _kGrey, thickness: 0.5),
          pw.SizedBox(height: 16),

          // ── Bill-to + dates ───────────────────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BILL TO',
                      style:
                          const pw.TextStyle(color: _kGrey, fontSize: 9)),
                  pw.SizedBox(height: 2),
                  pw.Text(p.customerName,
                      style:
                          pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                      'Issue date: ${p.dateFmt.format(p.issueDate)}',
                      style: const pw.TextStyle(
                          color: _kGrey, fontSize: 10)),
                  pw.Text(
                      '${p.secondaryDateLabel}: ${p.dateFmt.format(p.secondaryDate)}',
                      style: const pw.TextStyle(
                          color: _kGrey, fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // ── Items table (grey dividers frame, no background) ──────────────
          pw.Divider(color: _kGrey, thickness: 0.5),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(),
            cellAlignments: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            cellStyle: const pw.TextStyle(fontSize: 10),
            headers: const ['Item', 'Qty', 'Unit price', 'Total'],
            data: p.items
                .map((i) => [
                      (i.description == null || i.description!.isEmpty)
                          ? i.name
                          : '${i.name}\n${i.description!}',
                      i.quantity.toStringAsFixed(2),
                      p.currency.format(i.unitPrice),
                      p.currency.format(i.lineTotal),
                    ])
                .toList(),
          ),
          pw.Divider(color: _kGrey, thickness: 0.5),
          pw.SizedBox(height: 18),

          // ── Totals ────────────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.SizedBox(
                width: 220,
                child: pw.Column(
                  children: [
                    _row('Subtotal', p.currency.format(p.subtotal),
                        color: _kGrey),
                    if (p.discount > 0)
                      _row('Discount',
                          '- ${p.currency.format(p.discount)}',
                          color: _kGrey),
                    if (p.taxLabel != null)
                      _row(p.taxLabel!, p.currency.format(p.taxAmount),
                          color: _kGrey),
                    pw.Divider(color: _kGrey, thickness: 0.5),
                    _row('TOTAL', p.currency.format(p.total), bold: true),
                    if (p.amountPaid > 0) ...[
                      _row('Paid', p.currency.format(p.amountPaid),
                          color: _kGrey),
                      _row('Balance due',
                          p.currency.format(p.balanceDue),
                          bold: true),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ── Notes ─────────────────────────────────────────────────────────
          if (p.notes != null && p.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Divider(color: _kGrey, thickness: 0.5),
            pw.SizedBox(height: 8),
            pw.Text('Notes',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.SizedBox(height: 2),
            pw.Text(p.notes!, style: const pw.TextStyle(fontSize: 10)),
          ],

          // ── Payment instructions ──────────────────────────────────────────
          if (p.paymentInstructions != null &&
              p.paymentInstructions!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Payment instructions',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.SizedBox(height: 2),
            pw.Text(p.paymentInstructions!,
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    );

    return doc.save();
  }

  // ── Shared row helper ──────────────────────────────────────────────────────

  static pw.Widget _row(
    String label,
    String value, {
    bool bold = false,
    PdfColor? color,
  }) {
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

// ─────────────────────────────────────────────────────────────────────────────
// Internal data carriers
// ─────────────────────────────────────────────────────────────────────────────

class _DocParams {
  const _DocParams({
    required this.title,
    required this.number,
    required this.issueDate,
    required this.secondaryDateLabel,
    required this.secondaryDate,
    required this.customerName,
    required this.currency,
    required this.dateFmt,
    required this.items,
    required this.subtotal,
    required this.discount,
    this.taxLabel,
    required this.taxAmount,
    required this.total,
    required this.amountPaid,
    required this.balanceDue,
    this.notes,
    this.paymentInstructions,
    this.business,
    required this.statusLabel,
    required this.showWatermark,
  });

  final String title;
  final String number;
  final DateTime issueDate;
  final String secondaryDateLabel;
  final DateTime secondaryDate;
  final String customerName;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final List<_Line> items;
  final double subtotal;
  final double discount;
  final String? taxLabel;
  final double taxAmount;
  final double total;
  final double amountPaid;
  final double balanceDue;
  final String? notes;
  final String? paymentInstructions;
  final BusinessProfile? business;
  final String statusLabel;
  final bool showWatermark;
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
