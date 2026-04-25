/// A registered device for push notification delivery.
///
/// Schema: user_devices(id, user_id, fcm_token, platform, device_name,
///   is_active, last_seen_at, created_at, updated_at)
class UserDevice {
  const UserDevice({
    required this.id,
    required this.fcmToken,
    required this.platform,
    this.userId,
    this.deviceName,
    this.isActive = true,
    this.lastSeenAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// Supabase auth user id. Null in mock mode.
  final String? userId;

  /// Firebase Cloud Messaging registration token.
  final String fcmToken;

  /// Platform identifier, e.g. "android" or "ios".
  final String platform;

  /// Human-readable device name, e.g. "iPhone 15 Pro".
  final String? deviceName;

  /// Whether this device is still actively receiving notifications.
  final bool isActive;

  /// Timestamp of the last successful message delivery or heartbeat.
  final DateTime? lastSeenAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserDevice copyWith({
    String? id,
    String? userId,
    String? fcmToken,
    String? platform,
    String? deviceName,
    bool? isActive,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserDevice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fcmToken: fcmToken ?? this.fcmToken,
      platform: platform ?? this.platform,
      deviceName: deviceName ?? this.deviceName,
      isActive: isActive ?? this.isActive,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
