import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_business_profile_repository.dart';
import '../../data/repositories/business_profile_repository.dart';
import '../../shared/models/business_profile.dart';

final businessProfileRepositoryProvider =
    Provider<BusinessProfileRepository>((ref) {
  return MockBusinessProfileRepository();
});

/// Watches the current business profile. Emits null when not yet set up.
final businessProfileProvider =
    StreamProvider<BusinessProfile?>((ref) {
  return ref.watch(businessProfileRepositoryProvider).watch();
});
