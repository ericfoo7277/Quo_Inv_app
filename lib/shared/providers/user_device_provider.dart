import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/firebase_messaging_service.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

/// Side-effect provider that:
///   1. Waits for an authenticated Supabase session.
///   2. Asks the user for notification permission and obtains an FCM token.
///   3. Upserts that token into `user_devices` for the current user.
///   4. Re-registers on every token refresh.
///   5. Marks the token inactive on sign-out.
///
/// Watch this from a top-level widget (e.g. inside `QuoSwiftApp.build`) so it
/// stays alive for the app lifetime.
final fcmTokenRegistrationProvider = Provider<void>((ref) {
  final session = ref.watch(authSessionProvider).value;

  // Track the latest token so we can deactivate it on sign-out.
  String? activeToken;
  StreamSubscription<String>? sub;

  Future<void> registerToken(String token) async {
    try {
      final repo = ref.read(userDeviceRepositoryProvider);
      await repo.registerToken(
        fcmToken: token,
        platform: _platformLabel(),
      );
      activeToken = token;
    } catch (e) {
      if (kDebugMode) debugPrint('user_devices register failed: $e');
    }
  }

  Future<void> bootstrap() async {
    final fcm = FirebaseMessagingService.instance;

    // Request permission (no-op on subsequent calls) and get the initial token.
    final token = await fcm.requestPermissionAndGetToken();
    if (token != null) {
      await registerToken(token);
    }

    // Re-register on every refresh.
    sub = fcm.tokenStream.listen(registerToken);
  }

  if (session != null) {
    bootstrap();
  } else if (activeToken != null) {
    // Signed out – deactivate previously registered token. Best-effort: if the
    // session is gone we can't write under RLS, so the Edge Function will skip
    // it on the next run anyway via stale `last_seen_at`.
    final token = activeToken;
    activeToken = null;
    () async {
      try {
        await ref.read(userDeviceRepositoryProvider).deactivateToken(token!);
      } catch (_) {}
      await FirebaseMessagingService.instance.deleteToken();
    }();
  }

  ref.onDispose(() {
    sub?.cancel();
  });
});

String _platformLabel() {
  if (kIsWeb) return 'web';
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isMacOS) return 'macos';
  return 'other';
}
