import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../shared/models/reminder_setting.dart';
import '../../../shared/providers/reminder_setting_provider.dart';

const _uuid = Uuid();

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState
    extends ConsumerState<ReminderSettingsScreen> {
  bool _enablePush = true;
  bool _enableLocal = true;
  bool _remindOnDueDate = true;
  final _beforeCtrl = TextEditingController(text: '3');
  final _afterCtrl = TextEditingController(text: '1');
  String? _settingId;
  bool _loading = false;
  bool _populated = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final setting =
        await ref.read(reminderSettingRepositoryProvider).fetch();
    if (mounted && !_populated) {
      _populated = true;
      _settingId = setting.id;
      _beforeCtrl.text = setting.remindBeforeDays.toString();
      _remindOnDueDate = setting.remindOnDueDate;
      _afterCtrl.text = setting.remindAfterDays.toString();
      _enablePush = setting.enablePushNotifications;
      _enableLocal = setting.enableLocalNotifications;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _beforeCtrl.dispose();
    _afterCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final setting = ReminderSetting(
        id: _settingId ?? _uuid.v4(),
        remindBeforeDays: int.tryParse(_beforeCtrl.text) ?? 3,
        remindOnDueDate: _remindOnDueDate,
        remindAfterDays: int.tryParse(_afterCtrl.text) ?? 1,
        enablePushNotifications: _enablePush,
        enableLocalNotifications: _enableLocal,
      );
      await ref.read(reminderSettingRepositoryProvider).save(setting);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder settings saved!')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const ResponsiveContent(
              child: PremiumScreenHeader(
                title: 'Reminder settings',
                subtitle: 'Automate payment nudges for your clients.',
                icon: Icons.notifications_outlined,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ResponsiveContent(
              maxWidth: 640,
              child: Column(
                children: [
                  // Notification channels
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Push notifications'),
                          subtitle: const Text('Via Firebase Cloud Messaging'),
                          value: _enablePush,
                          onChanged: (v) =>
                              setState(() => _enablePush = v),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Local notifications'),
                          subtitle:
                              const Text('On-device, no internet required'),
                          value: _enableLocal,
                          onChanged: (v) =>
                              setState(() => _enableLocal = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Timing
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        AppTextField(
                          label: 'Days before due date',
                          hint: '3',
                          controller: _beforeCtrl,
                          prefixIcon: Icons.schedule_rounded,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Days after due date (overdue)',
                          hint: '1',
                          controller: _afterCtrl,
                          prefixIcon: Icons.warning_amber_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // On due date toggle
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: SwitchListTile(
                      title: const Text('Remind on the due date'),
                      subtitle: const Text(
                          'Send a reminder on the exact due date'),
                      value: _remindOnDueDate,
                      onChanged: (v) =>
                          setState(() => _remindOnDueDate = v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // WhatsApp — coming soon
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      title: const Text('Send via WhatsApp'),
                      subtitle: const Text('Coming soon'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: const Text('Coming soon'),
                            labelStyle: theme.textTheme.labelSmall,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          Switch(value: false, onChanged: null),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ResponsiveContent(
              maxWidth: 640,
              child: PrimaryButton(
                label: 'Save',
                icon: Icons.check_rounded,
                isLoading: _loading,
                onPressed: _loading ? null : _save,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}
