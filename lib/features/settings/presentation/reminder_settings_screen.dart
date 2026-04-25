import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_content.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  bool _enabled = true;
  bool _emailEnabled = true;
  bool _whatsappEnabled = false;
  final _beforeCtrl = TextEditingController(text: '3');
  final _afterCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _beforeCtrl.dispose();
    _afterCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Reminder settings saved!')));
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
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: SwitchListTile(
                      title: const Text('Enable payment reminders'),
                      subtitle: const Text('Send automatic payment nudges'),
                      value: _enabled,
                      onChanged: (v) => setState(() => _enabled = v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Send via email'),
                          value: _emailEnabled,
                          onChanged: (v) => setState(() => _emailEnabled = v),
                        ),
                        const Divider(height: 1),
                        ListTile(
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
                              Switch(
                                value: _whatsappEnabled,
                                onChanged: null,
                              ),
                            ],
                          ),
                        ),
                      ],
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
                onPressed: _save,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}
