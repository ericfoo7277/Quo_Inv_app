import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cross-document sharing helpers (PDF preview, system share, WhatsApp).
class DocumentShareService {
  const DocumentShareService();

  /// Shows the OS print/preview sheet for the given PDF bytes.
  Future<void> previewPdf({
    required Uint8List bytes,
    required String fileName,
  }) {
    return Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: fileName,
    );
  }

  /// Saves the PDF to a temp file and triggers the OS share sheet.
  Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
    required String subject,
    String? text,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(file.path, mimeType: 'application/pdf', name: fileName),
        ],
        subject: subject,
        text: text,
      ),
    );
  }

  /// Opens WhatsApp (or the WhatsApp web fallback) with a prefilled message
  /// to the given phone number. Returns false if WhatsApp can't be launched.
  ///
  /// PDFs cannot be auto-attached on most platforms — the message text invites
  /// the user to attach the PDF that they can also share via [sharePdf].
  Future<bool> openWhatsApp({
    required String phone,
    required String message,
  }) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return false;
    final uri = Uri.parse(
        'https://wa.me/$cleaned?text=${Uri.encodeComponent(message)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Helper that builds a friendly default WhatsApp / share message.
  String defaultMessage({
    required String docKind,
    required String docNumber,
    required String customerName,
    String? amount,
    String? dueOrValid,
  }) {
    final buffer = StringBuffer()
      ..writeln('Hi $customerName,')
      ..writeln()
      ..write('Please find $docKind $docNumber attached');
    if (amount != null) buffer.write(' for $amount');
    buffer.writeln('.');
    if (dueOrValid != null) buffer.writeln(dueOrValid);
    buffer
      ..writeln()
      ..writeln('Thank you!');
    return buffer.toString();
  }
}

/// Extension that surfaces a SnackBar when WhatsApp can't be opened.
Future<void> notifyIfFailed(
  BuildContext context,
  Future<bool> action, {
  String message = 'Could not open WhatsApp',
}) async {
  final ok = await action;
  if (!context.mounted || ok) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
