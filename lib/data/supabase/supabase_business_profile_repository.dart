import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/business_profile.dart';
import '../repositories/business_profile_repository.dart';

/// Supabase-backed implementation of [BusinessProfileRepository].
///
/// Each user owns exactly one row in `business_profiles`, keyed by
/// `user_id = auth.uid()`.  The `save` method upserts on conflict so it
/// works for both first-time setup and subsequent edits.
class SupabaseBusinessProfileRepository implements BusinessProfileRepository {
  SupabaseBusinessProfileRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'business_profiles';
  static const _bucket = 'business-logos';

  String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError(
        'No authenticated user. Ensure the user is signed in before '
        'accessing the business profile repository.',
      );
    }
    return user.id;
  }

  // ---------------------------------------------------------------------------
  // BusinessProfileRepository interface
  // ---------------------------------------------------------------------------

  @override
  Future<BusinessProfile?> fetch() async {
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', _uid)
        .maybeSingle();
    return data == null ? null : _fromMap(data);
  }

  @override
  Future<BusinessProfile> save(BusinessProfile profile) async {
    final map = _toMap(profile);
    final data = await _client
        .from(_table)
        .upsert(map, onConflict: 'user_id')
        .select()
        .single();
    return _fromMap(data);
  }

  @override
  Stream<BusinessProfile?> watch() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', _uid)
        .map((rows) => rows.isEmpty ? null : _fromMap(rows.first));
  }

  // ---------------------------------------------------------------------------
  // Logo upload
  // ---------------------------------------------------------------------------

  /// Uploads [imageBytes] to Supabase Storage under the authenticated user's
  /// folder and returns the public URL of the uploaded logo.
  Future<String> uploadLogo(Uint8List imageBytes) async {
    final path = '$_uid/logo.png';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          imageBytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/png'),
        );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  // ---------------------------------------------------------------------------
  // Serialisation helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _toMap(BusinessProfile p) => {
        'id': p.id,
        'user_id': _uid,
        'business_name': p.businessName,
        'phone': p.phone,
        'email': p.email,
        'address': p.address,
        'logo_url': p.logoUrl,
        'currency': p.currency,
        'payment_instructions': p.paymentInstructions,
        'default_quotation_notes': p.defaultQuotationNotes,
        'default_invoice_notes': p.defaultInvoiceNotes,
        'quotation_prefix': p.quotationPrefix,
        'invoice_prefix': p.invoicePrefix,
        'quotation_next_number': p.quotationNextNumber,
        'invoice_next_number': p.invoiceNextNumber,
        'timezone': p.timezone,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  BusinessProfile _fromMap(Map<String, dynamic> m) => BusinessProfile(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        businessName: m['business_name'] as String,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        address: m['address'] as String?,
        logoUrl: m['logo_url'] as String?,
        currency: m['currency'] as String? ?? 'MYR',
        paymentInstructions: m['payment_instructions'] as String?,
        defaultQuotationNotes: m['default_quotation_notes'] as String?,
        defaultInvoiceNotes: m['default_invoice_notes'] as String?,
        quotationPrefix: m['quotation_prefix'] as String? ?? 'Q-',
        invoicePrefix: m['invoice_prefix'] as String? ?? 'INV-',
        quotationNextNumber: m['quotation_next_number'] as int? ?? 1,
        invoiceNextNumber: m['invoice_next_number'] as int? ?? 1,
        timezone: m['timezone'] as String? ?? 'Asia/Kuala_Lumpur',
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? ''),
        updatedAt: DateTime.tryParse(m['updated_at'] as String? ?? ''),
      );
}
