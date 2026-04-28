import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';

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
