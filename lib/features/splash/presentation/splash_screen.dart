import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minimumDelayElapsed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _minimumDelayElapsed = true);
      }
    });
  }

  void _scheduleNavigation(String routeName) {
    if (_navigated) {
      return;
    }

    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.goNamed(routeName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authSession = ref.watch(authSessionProvider);

    if (_minimumDelayElapsed) {
      authSession.when(
        data: (session) {
          _scheduleNavigation(
            session == null ? RouteNames.login : RouteNames.dashboard,
          );
        },
        error: (_, __) => _scheduleNavigation(RouteNames.login),
        loading: () {},
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_rounded, size: 72, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Quo Inv',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
