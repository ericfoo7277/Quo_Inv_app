import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides the [SupabaseClient] singleton to the Riverpod widget tree.
///
/// Usage:
/// ```dart
/// final client = ref.watch(supabaseClientProvider);
/// ```
///
/// Repository providers that need Supabase should depend on this provider:
/// ```dart
/// final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
///   return SupabaseCustomerRepository(ref.watch(supabaseClientProvider));
/// });
/// ```
final supabaseClientProvider = Provider<SupabaseClient>((_) {
  return Supabase.instance.client;
});
