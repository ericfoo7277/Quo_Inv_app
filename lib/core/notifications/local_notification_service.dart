import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../shared/models/invoice.dart';
import '../../shared/models/reminder_setting.dart';

/// Wraps `flutter_local_notifications` to schedule reminders for due-soon and
/// overdue invoices based on the user's [ReminderSetting].
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const String _channelId = 'invoice_reminders';
  static const String _channelName = 'Invoice reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _lastScheduleSignature;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
        macOS: iosInit,
      ),
    );

    // Request runtime permission on Android 13+ / iOS.
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  /// Cancels any previously scheduled invoice reminders and schedules fresh
  /// ones for every still-open invoice based on [setting].
  Future<void> rescheduleInvoiceReminders({
    required List<Invoice> invoices,
    required ReminderSetting setting,
  }) async {
    if (!_initialized) await init();

    final signature = _scheduleSignature(invoices: invoices, setting: setting);
    if (_lastScheduleSignature == signature) return;
    _lastScheduleSignature = signature;

    if (!setting.enableLocalNotifications) {
      await _plugin.cancelAll();
      return;
    }
    await _plugin.cancelAll();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Reminders for invoices due soon and overdue',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    final now = DateTime.now();
    var scheduled = 0;
    for (final inv in invoices) {
      if (!_shouldRemind(inv)) {
        continue;
      }

      final dueDate = DateTime(inv.dueDate.year, inv.dueDate.month,
          inv.dueDate.day, 9); // 9 AM local

      // Reminder N days BEFORE due date.
      final beforeAt =
          dueDate.subtract(Duration(days: setting.remindBeforeDays));
      if (setting.remindBeforeDays > 0 && beforeAt.isAfter(now)) {
        await _schedule(
          id: _idFor(inv.id, 'before'),
          when: beforeAt,
          title: 'Invoice ${inv.invoiceNumber} due soon',
          body:
              '${inv.customerName} • due in ${setting.remindBeforeDays} days',
          payload: inv.id,
          details: details,
        );
        scheduled++;
      }

      // Reminder ON the due date.
      if (setting.remindOnDueDate && dueDate.isAfter(now)) {
        await _schedule(
          id: _idFor(inv.id, 'on'),
          when: dueDate,
          title: 'Invoice ${inv.invoiceNumber} is due today',
          body: '${inv.customerName} • please follow up',
          payload: inv.id,
          details: details,
        );
        scheduled++;
      }

      // Reminder N days AFTER due date (overdue follow-up).
      if (setting.remindAfterDays > 0) {
        final afterAt =
            dueDate.add(Duration(days: setting.remindAfterDays));
        if (afterAt.isAfter(now)) {
          await _schedule(
            id: _idFor(inv.id, 'after'),
            when: afterAt,
            title: 'Invoice ${inv.invoiceNumber} is overdue',
            body:
                '${inv.customerName} • ${setting.remindAfterDays} days late',
            payload: inv.id,
            details: details,
          );
          scheduled++;
        }
      }
    }

    if (kDebugMode) {
      debugPrint('LocalNotificationService: scheduled $scheduled reminders');
    }
  }

  Future<void> _schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String payload,
    required NotificationDetails details,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Stable, deterministic 31-bit notification id from invoice id + phase.
  int _idFor(String invoiceId, String phase) {
    final raw = '$invoiceId|$phase'.hashCode;
    return raw & 0x7fffffff;
  }

  bool _shouldRemind(Invoice invoice) {
    return invoice.status == InvoiceStatus.sent ||
        invoice.status == InvoiceStatus.partiallyPaid ||
        invoice.status == InvoiceStatus.overdue;
  }

  String _scheduleSignature({
    required List<Invoice> invoices,
    required ReminderSetting setting,
  }) {
    final invoiceParts = [...invoices]
      ..sort((a, b) => a.id.compareTo(b.id));

    return [
      setting.enableLocalNotifications,
      setting.remindBeforeDays,
      setting.remindOnDueDate,
      setting.remindAfterDays,
      for (final inv in invoiceParts)
        [
          inv.id,
          inv.invoiceNumber,
          inv.customerName,
          inv.status.name,
          inv.dueDate.toIso8601String(),
          inv.amountPaid,
          inv.storedTotal ?? inv.total,
        ].join(':'),
    ].join('|');
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
