import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../shared/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    final email = user?.email ?? '—';
    final displayName =
        (user?.userMetadata?['full_name'] as String?)?.trim() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const PremiumScreenHeader(
            title: 'Your Account',
            subtitle: 'Manage your login credentials.',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Account info card ───────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        _initials(displayName.isNotEmpty ? displayName : email),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (displayName.isNotEmpty)
                            Text(
                              displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Text(
                            email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Actions ─────────────────────────────────────────────────────
          AppCard(
            padding: EdgeInsets.zero,
            child: SettingsTile(
              icon: Icons.lock_reset_rounded,
              title: 'Change password',
              subtitle: 'Send a password-reset link to $email',
              onTap: () => _sendPasswordReset(context, ref, email),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return value.isNotEmpty ? value[0].toUpperCase() : '?';
  }

  Future<void> _sendPasswordReset(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) async {
    try {
      await ref
          .read(authServiceProvider)
          .sendPasswordResetEmail(email: email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password-reset email sent to $email'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reset email: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
