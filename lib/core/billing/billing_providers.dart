import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/business_profile_provider.dart';
import 'revenuecat_service.dart';

/// Singleton accessor for the RevenueCat service.
final revenueCatServiceProvider = Provider<RevenueCatService>(
  (ref) => RevenueCatService.instance,
);

/// Live `pro` entitlement state straight from RevenueCat's customer-info
/// stream. Defaults to false until the first event is emitted.
final revenueCatProStreamProvider = StreamProvider<bool>((ref) {
  return ref.watch(revenueCatServiceProvider).proStream;
});

/// Effective Pro state used across the app. Derived from the persisted
/// `subscription_tier` on the business profile (which is the source of truth
/// for server-side gating). Falls back to false while loading.
final isProProvider = Provider<bool>((ref) {
  final profile = ref.watch(businessProfileProvider).value;
  return (profile?.subscriptionTier ?? 'free') == 'pro';
});
