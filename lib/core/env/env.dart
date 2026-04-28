/// Environment configuration read from `--dart-define` build arguments.
///
/// Run the app with:
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=your-anon-key
/// ```
///
/// Both constants default to an empty string when the corresponding
/// `--dart-define` flag is not supplied. Check [isConfigured] before
/// attempting to use them, and call [assertConfigured] in debug builds
/// to surface missing values early.
///
/// Never commit real keys to source control.
class Env {
  static const supabaseUrl =
      String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Returns `true` when both required values are non-empty.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Throws a [StateError] in debug mode if either required value is missing.
  ///
  /// Call this once at app startup (e.g. in `main()`) to surface
  /// configuration problems before Supabase is initialised:
  /// ```dart
  /// Env.assertConfigured();
  /// ```
  static void assertConfigured() {
    assert(
      isConfigured,
      'Supabase credentials are not configured.\n'
      'Run the app with:\n'
      '  --dart-define=SUPABASE_URL=https://xxxx.supabase.co\n'
      '  --dart-define=SUPABASE_ANON_KEY=your-anon-key',
    );
  }
}
