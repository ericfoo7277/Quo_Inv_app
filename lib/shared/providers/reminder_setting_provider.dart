import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_reminder_setting_repository.dart';
import '../../data/repositories/reminder_setting_repository.dart';
import '../../shared/models/reminder_setting.dart';

final reminderSettingRepositoryProvider =
    Provider<ReminderSettingRepository>((ref) {
  return MockReminderSettingRepository();
});

/// Watches the current user's reminder settings.
final reminderSettingProvider = StreamProvider<ReminderSetting>((ref) {
  return ref.watch(reminderSettingRepositoryProvider).watch();
});
