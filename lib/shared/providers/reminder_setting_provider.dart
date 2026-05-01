import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/reminder_setting.dart';
import '../../data/mock/mock_reminder_setting_repository.dart';
import '../../data/repositories/reminder_setting_repository.dart';
import '../../data/supabase/supabase_reminder_setting_repository.dart';
import 'auth_providers.dart';

final reminderSettingRepositoryProvider =
    Provider<ReminderSettingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) {
    return SupabaseReminderSettingRepository(client);
  }
  return MockReminderSettingRepository();
});

/// Watches the current user's reminder settings.
final reminderSettingProvider = StreamProvider<ReminderSetting>((ref) {
  return ref.watch(reminderSettingRepositoryProvider).watch();
});
