import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/business_profile.dart';
import '../../../../shared/models/invoice.dart';
import '../../../../shared/models/quotation.dart';
import '../../../../shared/providers/business_profile_provider.dart';
import '../../../../shared/providers/customers_provider.dart';
import '../../services/document_pdf_service.dart';
import '../../services/document_share_service.dart';

enum DocumentAction { duplicate, exportPdf, share, whatsapp, copyMessage }

/// Reusable popup-menu button rendered in the AppBar of an invoice or
/// quotation detail screen. Wires up duplicate, PDF export, system share,
/// WhatsApp share, and "copy reminder message".
class DocumentActionsMenu extends ConsumerWidget {
  const DocumentActionsMenu({
    super.key,
    required this.invoice,
    this.onDuplicate,
  }) : quotation = null;

  const DocumentActionsMenu.quotation({
    super.key,
    required this.quotation,
    this.onDuplicate,
  }) : invoice = null;

  final Invoice? invoice;
  final Quotation? quotation;
  final VoidCallback? onDuplicate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<DocumentAction>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (action) => _handle(context, ref, action),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: DocumentAction.duplicate,
          child: ListTile(
            leading: Icon(Icons.copy_rounded),
            title: Text('Duplicate'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: DocumentAction.exportPdf,
          child: ListTile(
            leading: Icon(Icons.picture_as_pdf_rounded),
            title: Text('Export / Print PDF'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: DocumentAction.share,
          child: ListTile(
            leading: Icon(Icons.ios_share_rounded),
            title: Text('Share PDF'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: DocumentAction.whatsapp,
          child: ListTile(
            leading: Icon(Icons.chat_bubble_outline_rounded),
            title: Text('Send via WhatsApp'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: DocumentAction.copyMessage,
          child: ListTile(
            leading: Icon(Icons.copy_all_rounded),
            title: Text('Copy reminder message'),
            dense: true,
          ),
        ),
      ],
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    DocumentAction action,
  ) async {
    if (action == DocumentAction.duplicate) {
      onDuplicate?.call();
      return;
    }

    final business = ref.read(businessProfileProvider).value;
    final customer =
        await ref.read(customerByIdProvider(_customerId).future);
    if (!context.mounted) return;

    final pdfService = const DocumentPdfService();
    final shareService = const DocumentShareService();

    switch (action) {
      case DocumentAction.exportPdf:
        final bytes = await _buildPdf(pdfService, business);
        if (!context.mounted) return;
        await shareService.previewPdf(bytes: bytes, fileName: _fileName);
        break;
      case DocumentAction.share:
        final bytes = await _buildPdf(pdfService, business);
        if (!context.mounted) return;
        await shareService.sharePdf(
          bytes: bytes,
          fileName: _fileName,
          subject: _subject,
          text: _shareMessage(shareService),
        );
        break;
      case DocumentAction.whatsapp:
        final phone = customer?.whatsappNumber ?? customer?.phone;
        if (phone == null || phone.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer has no phone or WhatsApp number'),
            ),
          );
          return;
        }
        await notifyIfFailed(
          context,
          shareService.openWhatsApp(
            phone: phone,
            message: _shareMessage(shareService),
          ),
        );
        break;
      case DocumentAction.copyMessage:
        await Clipboard.setData(
          ClipboardData(text: _shareMessage(shareService)),
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder message copied')),
        );
        break;
      case DocumentAction.duplicate:
        break;
    }
  }

  // ---- helpers ----

  String get _customerId => invoice?.customerId ?? quotation!.customerId;
  String get _fileName =>
      '${invoice?.invoiceNumber ?? quotation!.quotationNumber}.pdf';
  String get _subject => invoice != null
      ? 'Invoice ${invoice!.invoiceNumber}'
      : 'Quotation ${quotation!.quotationNumber}';

  Future<Uint8List> _buildPdf(
    DocumentPdfService service,
    BusinessProfile? business,
  ) {
    if (invoice != null) {
      return service.buildInvoicePdf(invoice: invoice!, business: business);
    }
    return service.buildQuotationPdf(
        quotation: quotation!, business: business);
  }

  String _shareMessage(DocumentShareService service) {
    final dateFmt = DateFormat.yMMMd();
    if (invoice != null) {
      final inv = invoice!;
      final amount = NumberFormat.simpleCurrency(name: inv.currency)
          .format(inv.balanceDue > 0 ? inv.balanceDue : inv.total);
      return service.defaultMessage(
        docKind: 'invoice',
        docNumber: inv.invoiceNumber,
        customerName: inv.customerName,
        amount: amount,
        dueOrValid: 'Due by ${dateFmt.format(inv.dueDate)}.',
      );
    }
    final q = quotation!;
    final amount = NumberFormat.simpleCurrency(name: q.currency).format(q.total);
    return service.defaultMessage(
      docKind: 'quotation',
      docNumber: q.quotationNumber,
      customerName: q.customerName,
      amount: amount,
      dueOrValid: 'Valid until ${dateFmt.format(q.validUntil)}.',
    );
  }
}
