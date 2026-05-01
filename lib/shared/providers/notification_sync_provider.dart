import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/local_notification_service.dart';
import 'invoices_provider.dart';
import 'reminder_setting_provider.dart';

/// Side-effect provider that re-schedules local notifications whenever the
/// invoices list or the user's reminder settings change. Keep it watched
/// from a top-level widget so it stays alive.
final notificationSyncProvider = Provider<void>((ref) {
  final invoicesAsync = ref.watch(invoicesProvider);
  final settingAsync = ref.watch(reminderSettingProvider);

  final invoices = invoicesAsync.value;
  final setting = settingAsync.value;
  if (invoices == null || setting == null) return;

  // Fire and forget – we don't await in the provider builder.
  LocalNotificationService.instance.rescheduleInvoiceReminders(
    invoices: invoices,
    setting: setting,
  );
});
