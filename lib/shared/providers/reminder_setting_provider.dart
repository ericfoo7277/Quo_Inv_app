import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/reminder_setting.dart';
import '../mock/mock_reminder_setting_repository.dart';
import '../repositories/reminder_setting_repository.dart';

final reminderSettingRepositoryProvider =
    Provider<ReminderSettingRepository>((ref) {
  return MockReminderSettingRepository();
});

/// Watches the current user's reminder settings.
final reminderSettingProvider = StreamProvider<ReminderSetting>((ref) {
  return ref.watch(reminderSettingRepositoryProvider).watch();
});
