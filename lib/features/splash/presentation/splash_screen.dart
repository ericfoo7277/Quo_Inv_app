import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/providers/business_profile_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minimumDelayElapsed = false;
  bool _navigated = false;
  bool _profileCheckStarted = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _minimumDelayElapsed = true);
      _tryNavigateFromSession(ref.read(authSessionProvider));
    });
  }

  /// Called both from the delay callback and from ref.listen so navigation
  /// fires exactly once regardless of which signal arrives first.
  void _tryNavigateFromSession(AsyncValue<dynamic> session) {
    if (!_minimumDelayElapsed) return;
    session.whenOrNull(
      data: (s) {
        if (s == null) {
          _scheduleNavigation(RouteNames.login);
        } else {
          _navigateAfterProfileCheck();
        }
      },
      error: (_, __) => _scheduleNavigation(RouteNames.login),
    );
  }

  void _scheduleNavigation(String routeName) {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.goNamed(routeName);
  }

  Future<void> _navigateAfterProfileCheck() async {
    if (_profileCheckStarted) return;
    _profileCheckStarted = true;

    try {
      final profile = await ref
          .read(businessProfileRepositoryProvider)
          .fetch()
          .timeout(const Duration(seconds: 8));
      if (mounted) {
        _scheduleNavigation(
          profile == null ? RouteNames.businessSetup : RouteNames.dashboard,
        );
      }
    } catch (_) {
      // Network error, timeout, or table not yet created — default to dashboard.
      if (mounted) _scheduleNavigation(RouteNames.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // React to session changes that arrive after the minimum delay.
    ref.listen<AsyncValue<dynamic>>(
      authSessionProvider,
      (_, next) => _tryNavigateFromSession(next),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'QuoSwift',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Create, send, and track quotes and invoices.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
