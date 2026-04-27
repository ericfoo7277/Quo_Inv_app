import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

final hasSupabaseConfigProvider = Provider<bool>((ref) {
  return ref.watch(appConfigProvider).isSupabaseConfigured;
});

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!ref.watch(hasSupabaseConfigProvider)) {
    return null;
  }

  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

final authSessionProvider = StreamProvider<Session?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);

  if (client == null) {
    yield null;
    return;
  }

  yield client.auth.currentSession;
  yield* client.auth.onAuthStateChange.map((event) => event.session);
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authSessionProvider).maybeWhen(
        data: (session) => session?.user,
        orElse: () => null,
      );
});

class AuthService {
  const AuthService(this._client);

  final SupabaseClient? _client;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _requireClient().auth.signInWithPassword(
          email: email,
          password: password,
        );
  }

  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _requireClient().auth.signUp(
          email: email,
          password: password,
          data: {'full_name': fullName},
        );
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _requireClient().auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() {
    return _requireClient().auth.signOut();
  }

  SupabaseClient _requireClient() {
    if (_client == null) {
      throw StateError(
        'Supabase is not configured. Launch with '
        '--dart-define=SUPABASE_URL=... '
        '--dart-define=SUPABASE_ANON_KEY=...',
      );
    }

    return _client;
  }
}

String authErrorMessage(Object error) {
  if (error is AuthException) {
    return error.message;
  }

  if (error is StateError) {
    return error.message.toString();
  }

  return 'Something went wrong. Please try again.';
}