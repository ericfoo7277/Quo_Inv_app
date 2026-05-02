import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler.
///
/// Must be a top-level function (not a closure) so the FCM SDK can spawn an
/// isolate for it. The Dart VM looks the function up by symbol name.
///
/// Keep this body minimal – Firebase is already initialised by the FlutterFire
/// background isolate bootstrap, but heavy work (Supabase calls, navigation)
/// is unsafe here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint(
      'FCM background message: ${message.messageId} '
      'data=${message.data} notification=${message.notification?.title}',
    );
  }
}

/// Wraps `firebase_messaging` to handle permissions, token retrieval, and
/// foreground / opened-app message routing.
///
/// Token persistence to Supabase happens in `user_device_provider.dart`; this
/// service is platform-only and Supabase-agnostic.
class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  static const String _channelId = 'invoice_reminders';
  static const String _channelName = 'Invoice reminders';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Latest known token. Null until [requestPermissionAndGetToken] resolves.
  String? get currentToken => _cachedToken;
  String? _cachedToken;

  /// Stream of new tokens (initial + every refresh).
  Stream<String> get tokenStream async* {
    if (_cachedToken != null) yield _cachedToken!;
    yield* _messaging.onTokenRefresh;
  }

  /// Initialise FCM: register a high-importance Android channel for foreground
  /// banners and configure foreground presentation on iOS.
  Future<void> init() async {
    if (_initialized) return;

    // iOS: show banner + sound + badge while app is foregrounded.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android: ensure the channel exists so foreground notifications surface.
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Reminders for invoices due soon and overdue',
      importance: Importance.high,
    );
    await _localPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Ask the user for notification permission, then return the FCM token.
  ///
  /// On iOS the APNs token must be available before FCM can return a token; we
  /// poll briefly to avoid races on cold start.
  Future<String?> requestPermissionAndGetToken() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (kDebugMode) debugPrint('FCM permission denied');
      return null;
    }

    if (Platform.isIOS) {
      // Wait for APNs registration so `getToken` doesn't return null.
      String? apns;
      for (var i = 0; i < 10 && apns == null; i++) {
        apns = await _messaging.getAPNSToken();
        if (apns == null) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
      }
    }

    final token = await _messaging.getToken();
    _cachedToken = token;
    if (kDebugMode) debugPrint('FCM token: $token');
    return token;
  }

  /// Wire foreground & opened-app handlers. Call once after init.
  ///
  /// [onOpenedApp] receives the message that opened the app from a
  /// notification tap (terminated or background). Use it to navigate to e.g.
  /// the matching invoice detail screen.
  Future<void> registerHandlers({
    void Function(RemoteMessage message)? onOpenedApp,
  }) async {
    // Cold start tap.
    final initial = await _messaging.getInitialMessage();
    if (initial != null && onOpenedApp != null) {
      onOpenedApp(initial);
    }

    // Tap while in background.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (onOpenedApp != null) onOpenedApp(message);
    });

    // Foreground delivery – render via local notifications so users see a
    // banner instead of the message being silently dropped on Android.
    FirebaseMessaging.onMessage.listen(_showForeground);
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    await _localPlugin.show(
      id: notif.hashCode & 0x7fffffff,
      title: notif.title,
      body: notif.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminders for invoices due soon and overdue',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['invoice_id'] as String?,
    );
  }

  /// Best-effort token deletion (used on sign-out).
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _cachedToken = null;
    } catch (e) {
      if (kDebugMode) debugPrint('FCM deleteToken failed: $e');
    }
  }
}
