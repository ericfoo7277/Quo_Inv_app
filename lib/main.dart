import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';

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
