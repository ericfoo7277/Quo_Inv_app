/// User-level reminder configuration.
///
/// Schema: reminder_settings(id, user_id, remind_before_days,
///   remind_on_due_date, remind_after_days, enable_push_notifications,
///   enable_local_notifications, message_template, created_at, updated_at)
class ReminderSetting {
  const ReminderSetting({
    required this.id,
    this.userId,
    this.remindBeforeDays = 3,
    this.remindOnDueDate = true,
    this.remindAfterDays = 3,
    this.enablePushNotifications = true,
    this.enableLocalNotifications = true,
    this.messageTemplate = defaultMessageTemplate,
    this.createdAt,
    this.updatedAt,
  });

  /// Default reminder text. Placeholders: {customer}, {invoice}, {amount},
  /// {due_date}.
  static const String defaultMessageTemplate =
      'Hi {customer}, this is a friendly reminder that invoice {invoice} '
      'for {amount} is due on {due_date}. Thank you!';

  final String id;

  /// Supabase auth user id. Null in mock mode.
  final String? userId;

  /// Number of days before the due date to send a reminder.
  final int remindBeforeDays;

  /// Whether to send a reminder on the exact due date.
  final bool remindOnDueDate;

  /// Number of days after the due date to send an overdue reminder.
  final int remindAfterDays;

  /// Push notifications via FCM (Firebase Cloud Messaging).
  final bool enablePushNotifications;

  /// On-device local notifications (no network required).
  final bool enableLocalNotifications;

  /// Editable text used to compose reminder messages.
  final String messageTemplate;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReminderSetting copyWith({
    String? id,
    String? userId,
    int? remindBeforeDays,
    bool? remindOnDueDate,
    int? remindAfterDays,
    bool? enablePushNotifications,
    bool? enableLocalNotifications,
    String? messageTemplate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderSetting(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      remindBeforeDays: remindBeforeDays ?? this.remindBeforeDays,
      remindOnDueDate: remindOnDueDate ?? this.remindOnDueDate,
      remindAfterDays: remindAfterDays ?? this.remindAfterDays,
      enablePushNotifications:
          enablePushNotifications ?? this.enablePushNotifications,
      enableLocalNotifications:
          enableLocalNotifications ?? this.enableLocalNotifications,
      messageTemplate: messageTemplate ?? this.messageTemplate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
