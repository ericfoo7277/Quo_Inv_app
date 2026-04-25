import 'dart:async';

import '../../shared/models/business_profile.dart';
import '../repositories/business_profile_repository.dart';

/// In-memory mock. Starts with a sensible default profile so settings screens
/// can display pre-populated data without Supabase.
class MockBusinessProfileRepository implements BusinessProfileRepository {
  MockBusinessProfileRepository() {
    _profile = BusinessProfile(
      id: 'bp_mock_001',
      businessName: 'My Business',
      email: '',
      phone: '',
      address: '',
      currency: 'USD',
      quotationPrefix: 'QUO',
      invoicePrefix: 'INV',
      quotationNextNumber: 6,
      invoiceNextNumber: 8,
      timezone: 'UTC',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  late BusinessProfile _profile;
  final _controller = StreamController<BusinessProfile?>.broadcast();

  static const _latency = Duration(milliseconds: 200);

  void _emit() => _controller.add(_profile);

  @override
  Future<BusinessProfile?> fetch() async {
    await Future.delayed(_latency);
    return _profile;
  }

  @override
  Future<BusinessProfile> save(BusinessProfile profile) async {
    await Future.delayed(_latency);
    _profile = profile.copyWith(updatedAt: DateTime.now());
    _emit();
    return _profile;
  }

  @override
  Stream<BusinessProfile?> watch() async* {
    yield _profile;
    yield* _controller.stream;
  }
}
