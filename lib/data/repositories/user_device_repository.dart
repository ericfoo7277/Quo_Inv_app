import '../../shared/models/user_device.dart';

/// Persists FCM device registrations so server-side functions can deliver
/// push notifications to every device a user is signed in on.
abstract class UserDeviceRepository {
  /// Insert or update the row keyed by [fcmToken] and mark it active.
  Future<UserDevice> registerToken({
    required String fcmToken,
    required String platform,
    String? deviceName,
  });

  /// Mark a token inactive (call on sign-out).
  Future<void> deactivateToken(String fcmToken);

  /// Refresh `last_seen_at` to indicate the device is alive.
  Future<void> touch(String fcmToken);
}
