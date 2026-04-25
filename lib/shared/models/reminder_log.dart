/// Audit log entry for a sent payment reminder.
///
/// Schema: reminder_logs(id, user_id, invoice_id, reminder_type, channel,
///   status, sent_at, error_message, created_at)
class ReminderLog {
  const ReminderLog({
    required this.id,
    required this.invoiceId,
    required this.reminderType,
    required this.channel,
    required this.status,
    this.userId,
    this.sentAt,
    this.errorMessage,
    this.createdAt,
  });

  final String id;

  /// Supabase auth user id. Null in mock mode.
  final String? userId;

  final String invoiceId;

  /// Type of reminder, e.g. "before_due", "on_due", "after_due".
  final String reminderType;

  /// Delivery channel, e.g. "push", "email", "whatsapp".
  final String channel;

  /// Delivery outcome, e.g. "sent", "failed", "skipped".
  final String status;

  /// Timestamp when the reminder was dispatched.
  final DateTime? sentAt;

  /// Error details when [status] is "failed".
  final String? errorMessage;

  final DateTime? createdAt;
}
