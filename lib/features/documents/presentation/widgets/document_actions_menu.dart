import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/business_profile.dart';
import '../../../../shared/models/invoice.dart';
import '../../../../shared/models/quotation.dart';
import '../../../../shared/providers/business_profile_provider.dart';
import '../../../../shared/providers/customers_provider.dart';
import '../../../../shared/providers/invoices_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/utils/currency_format.dart';
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
    this.business,
    this.onDuplicate,
  }) : quotation = null;

  const DocumentActionsMenu.quotation({
    super.key,
    required this.quotation,
    this.business,
    this.onDuplicate,
  }) : invoice = null;

  final Invoice? invoice;
  final Quotation? quotation;
  final BusinessProfile? business;
  final VoidCallback? onDuplicate;

  /// Shows a bottom sheet with sharing options (preview, share, WhatsApp,
  /// copy message). Call this from the "Send to customer" button.
  ///
  /// The sheet returns the chosen [DocumentAction] as its result so the action
  /// is executed *after* the sheet is fully dismissed, using a context that is
  /// guaranteed to still be mounted.
  static Future<void> showSendSheet(
    BuildContext context,
    WidgetRef ref, {
    Invoice? invoice,
    Quotation? quotation,
    BusinessProfile? business,
  }) async {
    assert(invoice != null || quotation != null);

    final action = await showModalBottomSheet<DocumentAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: const Text('Preview PDF'),
              onTap: () =>
                  Navigator.of(sheetCtx).pop(DocumentAction.exportPdf),
            ),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('Share PDF'),
              onTap: () => Navigator.of(sheetCtx).pop(DocumentAction.share),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded),
              title: const Text('Send via WhatsApp'),
              onTap: () =>
                  Navigator.of(sheetCtx).pop(DocumentAction.whatsapp),
            ),
            ListTile(
              leading: const Icon(Icons.copy_all_rounded),
              title: const Text('Copy reminder message'),
              onTap: () =>
                  Navigator.of(sheetCtx).pop(DocumentAction.copyMessage),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    // Sheet is now fully dismissed. Execute the chosen action using the
    // parent screen's context which is guaranteed to still be mounted.
    if (action == null || !context.mounted) return;

    final menu = invoice != null
        ? DocumentActionsMenu(invoice: invoice, business: business)
        : DocumentActionsMenu.quotation(
            quotation: quotation!,
            business: business,
          );
    await menu._handle(context, ref, action, business: business);
  }

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
    DocumentAction action, {
    BusinessProfile? business,
  }) async {
    if (action == DocumentAction.duplicate) {
      onDuplicate?.call();
      return;
    }

    // For popup-menu calls, prefer the constructor value from the detail screen.
    business ??= this.business ?? ref.read(businessProfileProvider).value;

    try {
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
          // Only fetch customer for WhatsApp (needs phone number).
          final customer =
              await ref.read(customerByIdProvider(_customerId).future);
          if (!context.mounted) return;
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

      // After a real send action on a draft invoice, ask if it was sent.
      if (invoice != null &&
          invoice!.status == InvoiceStatus.draft &&
          (action == DocumentAction.share ||
              action == DocumentAction.whatsapp ||
              action == DocumentAction.copyMessage)) {
        if (!context.mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Mark as sent?'),
            content: const Text(
                'Did you send this invoice to your customer?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Not yet'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Yes, mark as sent'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          final updated = invoice!.copyWith(status: InvoiceStatus.sent);
          await ref.read(invoiceRepositoryProvider).update(updated);
          ref.invalidate(invoiceByIdProvider(invoice!.id));
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
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
      final amount = AppCurrencyFormat.format(
        inv.balanceDue > 0 ? inv.balanceDue : inv.total,
        currency: business?.currency ?? inv.currency,
      );
      return service.defaultMessage(
        docKind: 'invoice',
        docNumber: inv.invoiceNumber,
        customerName: inv.customerName,
        amount: amount,
        dueOrValid: 'Due by ${dateFmt.format(inv.dueDate)}.',
      );
    }
    final q = quotation!;
    final amount = AppCurrencyFormat.format(
      q.total,
      currency: business?.currency ?? q.currency,
    );
    return service.defaultMessage(
      docKind: 'quotation',
      docNumber: q.quotationNumber,
      customerName: q.customerName,
      amount: amount,
      dueOrValid: 'Valid until ${dateFmt.format(q.validUntil)}.',
    );
  }
}
