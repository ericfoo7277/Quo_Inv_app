import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/user_device.dart';
import '../repositories/user_device_repository.dart';

/// Supabase-backed implementation of [UserDeviceRepository].
///
/// Uses upsert on `fcm_token` (the unique column) so re-registering the same
/// token simply refreshes `user_id`, `is_active`, and `last_seen_at`.
class SupabaseUserDeviceRepository implements UserDeviceRepository {
  SupabaseUserDeviceRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'user_devices';

  String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }
    return user.id;
  }

  @override
  Future<UserDevice> registerToken({
    required String fcmToken,
    required String platform,
    String? deviceName,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final row = await _client
        .from(_table)
        .upsert(
          {
            'user_id': _uid,
            'fcm_token': fcmToken,
            'platform': platform,
            'device_name': deviceName,
            'is_active': true,
            'last_seen_at': nowIso,
            'updated_at': nowIso,
          },
          onConflict: 'fcm_token',
        )
        .select()
        .single();
    return _fromMap(row);
  }

  @override
  Future<void> deactivateToken(String fcmToken) async {
    await _client.from(_table).update({
      'is_active': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('fcm_token', fcmToken);
  }

  @override
  Future<void> touch(String fcmToken) async {
    await _client.from(_table).update({
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('fcm_token', fcmToken);
  }

  UserDevice _fromMap(Map<String, dynamic> m) => UserDevice(
        id: m['id'] as String,
        userId: m['user_id'] as String?,
        fcmToken: m['fcm_token'] as String,
        platform: m['platform'] as String,
        deviceName: m['device_name'] as String?,
        isActive: m['is_active'] as bool? ?? true,
        lastSeenAt: DateTime.tryParse(m['last_seen_at'] as String? ?? ''),
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? ''),
        updatedAt: DateTime.tryParse(m['updated_at'] as String? ?? ''),
      );
}
