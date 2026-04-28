// supabase_provider.dart
//
// The canonical Supabase client providers live in auth_providers.dart:
//
//   • supabaseClientProvider  – Provider<SupabaseClient?>
//       Returns null when the app is running in mock/dev mode without
//       SUPABASE_URL / SUPABASE_ANON_KEY dart-defines. All auth-screen
//       widgets and AuthService use this provider.
//
//   • authServiceProvider     – Provider<AuthService>
//       Wraps the nullable client; throws a clear StateError if called
//       before Supabase is configured.
//
// Future repository implementations (SupabaseCustomerRepository, etc.)
// should import auth_providers.dart and depend on supabaseClientProvider.
// The AuthService._requireClient() pattern shows the recommended approach
// for handling the nullable client gracefully.
//
// Example:
// ```dart
// import '../../../shared/providers/auth_providers.dart';
//
// final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
//   final client = ref.watch(supabaseClientProvider);
//   if (client == null) return MockCustomerRepository();
//   return SupabaseCustomerRepository(client);
// });
// ```

export 'auth_providers.dart' show supabaseClientProvider;
