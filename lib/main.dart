import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/billing/revenuecat_service.dart';
import 'core/config/app_config.dart';
import 'core/notifications/firebase_messaging_service.dart';
import 'core/notifications/local_notification_service.dart';

// ---------------------------------------------------------------------------
// HOW TO CONNECT TO YOUR SUPABASE PROJECT
// ---------------------------------------------------------------------------
// Credentials are injected at build/run time via --dart-define so they are
// never hard-coded in source control.
//
// Option A – VS Code:
//   Open .vscode/launch.json, select "QuoSwift (Supabase – fill in your keys)"
//   and replace the placeholder values with your real Project URL and
//   Publishable (anon) key from Supabase → Settings → API Keys.
//
// Option B – Command line:
//   flutter run \
//     --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
//
// Option C – flutter build:
//   flutter build apk \
//     --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
//
// When neither variable is set the app starts in mock mode – auth screens are
// visible but the "Sign in" button bypasses the auth check and goes straight
// to the dashboard.
// ---------------------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final appConfig = AppConfig.fromEnvironment();

  if (appConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: appConfig.supabaseUrl,
      anonKey: appConfig.supabaseAnonKey,
    );
  }

  // RevenueCat — safe no-op if API keys are not supplied via --dart-define.
  await RevenueCatService.instance.init(
    userId: appConfig.isSupabaseConfigured
        ? Supabase.instance.client.auth.currentUser?.id
        : null,
  );
  // Keep RevenueCat identity in sync with Supabase auth state.
  if (appConfig.isSupabaseConfigured) {
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final uid = event.session?.user.id;
      if (uid != null && uid.isNotEmpty) {
        RevenueCatService.instance.identify(uid);
      } else {
        RevenueCatService.instance.reset();
      }
    });
  }

  // Firebase – uses google-services.json (Android) and GoogleService-Info
  // .plist (iOS) so we don't need a generated firebase_options.dart.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FirebaseMessagingService.instance.init();
  } catch (e, st) {
    // Don't block app start if Firebase config files are missing in dev.
    if (kDebugMode) {
      debugPrint('Firebase init skipped: $e\n$st');
    }
  }

  await LocalNotificationService.instance.init();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(appConfig),
      ],
      child: const QuoSwiftApp(),
    ),
  );
}

/// Convenience getter – access the Supabase client anywhere in the app
/// without looking it up through the widget tree.
///
/// Example:
/// ```dart
/// final data = await supabase.from('customers').select();
/// ```
SupabaseClient get supabase => Supabase.instance.client;
