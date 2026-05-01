import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/reminder_setting.dart';
import '../repositories/reminder_setting_repository.dart';

/// Supabase-backed implementation of [ReminderSettingRepository].
///
/// Each user owns exactly one row in `reminder_settings`, keyed by
/// `user_id = auth.uid()`. `save` upserts on conflict so it works for both
/// first-time creation and subsequent edits.
class SupabaseReminderSettingRepository implements ReminderSettingRepository {
  SupabaseReminderSettingRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'reminder_settings';

  String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }
    return user.id;
  }

  ReminderSetting _defaults() => ReminderSetting(
        id: '',
        userId: _uid,
      );

  @override
  Future<ReminderSetting> fetch() async {
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', _uid)
        .maybeSingle();
    return data == null ? _defaults() : _fromMap(data);
  }

  @override
  Future<ReminderSetting> save(ReminderSetting setting) async {
    final data = await _client
        .from(_table)
        .upsert(_toMap(setting), onConflict: 'user_id')
        .select()
        .single();
    return _fromMap(data);
  }

  @override
  Stream<ReminderSetting> watch() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', _uid)
        .map((rows) => rows.isEmpty ? _defaults() : _fromMap(rows.first));
  }

  // ---------------------------------------------------------------------------
  // Mapping
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _toMap(ReminderSetting s) {
    final map = <String, dynamic>{
      'user_id': _uid,
      'remind_before_days': s.remindBeforeDays,
      'remind_on_due_date': s.remindOnDueDate,
      'remind_after_days': s.remindAfterDays,
      'enable_push_notifications': s.enablePushNotifications,
      'enable_local_notifications': s.enableLocalNotifications,
      'message_template': s.messageTemplate,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    // Only include id when it's an existing Postgres-generated uuid.
    if (s.id.isNotEmpty) map['id'] = s.id;
    return map;
  }

  ReminderSetting _fromMap(Map<String, dynamic> m) => ReminderSetting(
        id: m['id'] as String,
        userId: m['user_id'] as String?,
        remindBeforeDays: (m['remind_before_days'] as num?)?.toInt() ?? 3,
        remindOnDueDate: m['remind_on_due_date'] as bool? ?? true,
        remindAfterDays: (m['remind_after_days'] as num?)?.toInt() ?? 3,
        enablePushNotifications:
            m['enable_push_notifications'] as bool? ?? true,
        enableLocalNotifications:
            m['enable_local_notifications'] as bool? ?? true,
        messageTemplate: (m['message_template'] as String?) ??
            ReminderSetting.defaultMessageTemplate,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? ''),
        updatedAt: DateTime.tryParse(m['updated_at'] as String? ?? ''),
      );
}
