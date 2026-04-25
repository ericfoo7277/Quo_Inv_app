import 'dart:async';

import '../../shared/models/reminder_setting.dart';
import '../repositories/reminder_setting_repository.dart';

/// In-memory mock with sensible defaults.
class MockReminderSettingRepository implements ReminderSettingRepository {
  MockReminderSettingRepository() {
    _setting = const ReminderSetting(
      id: 'rs_mock_001',
      remindBeforeDays: 3,
      remindOnDueDate: true,
      remindAfterDays: 1,
      enablePushNotifications: true,
      enableLocalNotifications: true,
    );
  }

  late ReminderSetting _setting;
  final _controller = StreamController<ReminderSetting>.broadcast();

  static const _latency = Duration(milliseconds: 200);

  void _emit() => _controller.add(_setting);

  @override
  Future<ReminderSetting> fetch() async {
    await Future.delayed(_latency);
    return _setting;
  }

  @override
  Future<ReminderSetting> save(ReminderSetting setting) async {
    await Future.delayed(_latency);
    _setting = setting.copyWith(updatedAt: DateTime.now());
    _emit();
    return _setting;
  }

  @override
  Stream<ReminderSetting> watch() async* {
    yield _setting;
    yield* _controller.stream;
  }
}
