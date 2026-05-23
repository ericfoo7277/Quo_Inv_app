import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/providers/business_profile_provider.dart';
import '../../../shared/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);
    final isPro =
        (ref.watch(businessProfileProvider).value?.subscriptionTier ??
                'free') ==
            'pro';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const PremiumScreenHeader(
            title: 'Settings',
            subtitle: 'Tune your workspace and business defaults.',
            icon: Icons.settings_rounded,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppCard(
            padding: EdgeInsets.zero,
            child: SettingsTile(
              icon: Icons.workspace_premium_rounded,
              iconColor: AppColors.primary,
              title: isPro ? 'QuoSwift Pro' : 'Upgrade to Pro',
              subtitle: isPro
                  ? 'Unlimited invoices, no watermark'
                  : 'Unlock unlimited docs · RM 4.90/mo',
              onTap: () => context.pushNamed(RouteNames.paywall),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  subtitle: 'Owner account and preferences',
                  onTap: () => context.goNamed(RouteNames.profile),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.business_outlined,
                  title: 'Business details',
                  subtitle: 'Logo, tax ID and invoice identity',
                  onTap: () => context.goNamed(RouteNames.businessProfile),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.payments_outlined,
                  title: 'Payments',
                  subtitle: 'Recent payments and settlement history',
                  onTap: () => context.goNamed(RouteNames.payments),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.tag_rounded,
                  title: 'Numbering',
                  subtitle: 'Invoice and quotation number sequences',
                  onTap: () => context.goNamed(RouteNames.numberingSettings),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.notes_rounded,
                  title: 'Default Notes',
                  subtitle: 'Pre-filled notes for new documents',
                  onTap: () => context.goNamed(RouteNames.defaultNotes),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: EdgeInsets.zero,
            child: SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Reminders',
              subtitle: 'Due date and overdue alerts',
              onTap: () => context.goNamed(RouteNames.reminderSettings),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Appearance', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Choose the look that works best for your day.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto)),
                    ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined)),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_outlined)),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) =>
                      ref.read(themeModeProvider.notifier).set(s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: EdgeInsets.zero,
            child: SettingsTile(
              icon: Icons.logout_rounded,
              iconColor: AppColors.error,
              title: 'Log out',
              subtitle: 'Sign out of this device',
              onTap: () => _confirmLogout(context, ref),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Center(
            child: Text('v1.0.0', style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to access your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(authServiceProvider).signOut();
      if (!context.mounted) return;
      context.goNamed(RouteNames.login);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: $e')),
      );
    }
  }
}
