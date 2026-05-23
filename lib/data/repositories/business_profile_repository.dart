import 'dart:typed_data';

import '../../shared/models/business_profile.dart';

/// Repository contract for business profile persistence.
///
/// The mock implementation lives in [MockBusinessProfileRepository]. A future
/// `SupabaseBusinessProfileRepository` implements this same interface so the
/// rest of the app keeps working unchanged.
abstract class BusinessProfileRepository {
  /// Returns the profile for the currently authenticated user, or null if not
  /// set up yet.
  Future<BusinessProfile?> fetch();

  /// Creates or fully replaces the current user's business profile.
  Future<BusinessProfile> save(BusinessProfile profile);

  /// Live updates. Emits whenever the profile changes.
  Stream<BusinessProfile?> watch();

  /// Uploads a logo image and returns its public URL.
  ///
  /// In mock mode this is a no-op that returns an empty string.
  Future<String> uploadLogo(Uint8List imageBytes);

  /// Persists the subscription tier for the current user. Pass `'pro'` after
  /// a successful RevenueCat purchase / restore, or `'free'` on cancellation.
  ///
  /// NOTE: This is an MVP-grade approach that trusts the client. Harden it
  /// later by moving the write to a Supabase Edge Function that validates the
  /// RevenueCat receipt or by wiring a RevenueCat webhook.
  Future<void> setSubscriptionTier(String tier);
}
