import '../../shared/models/reminder_setting.dart';

/// Repository contract for reminder settings persistence.
///
/// The mock implementation lives in [MockReminderSettingRepository]. A future
/// `SupabaseReminderSettingRepository` implements this same interface.
abstract class ReminderSettingRepository {
  /// Returns the reminder settings for the current user, or default values if
  /// not yet configured.
  Future<ReminderSetting> fetch();

  /// Saves updated reminder settings for the current user.
  Future<ReminderSetting> save(ReminderSetting setting);

  /// Live updates. Emits whenever settings change.
  Stream<ReminderSetting> watch();
}
