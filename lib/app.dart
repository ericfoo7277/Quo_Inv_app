import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/firebase_messaging_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/notification_sync_provider.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/providers/user_device_provider.dart';

class QuoSwiftApp extends ConsumerStatefulWidget {
  const QuoSwiftApp({super.key});

  @override
  ConsumerState<QuoSwiftApp> createState() => _QuoSwiftAppState();
}

class _QuoSwiftAppState extends ConsumerState<QuoSwiftApp> {
  @override
  void initState() {
    super.initState();
    // Register foreground / opened-app handlers once. Navigation on tap is
    // wired through the router – we read the current GoRouter from the
    // provider when a message arrives.
    FirebaseMessagingService.instance.registerHandlers(
      onOpenedApp: (message) {
        final invoiceId = message.data['invoice_id'] as String?;
        if (invoiceId == null) return;
        final router = ref.read(appRouterProvider);
        router.push('/invoices/$invoiceId');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep these side-effect providers alive for the app lifetime.
    ref.watch(fcmTokenRegistrationProvider);
    ref.watch(notificationSyncProvider);

    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'QuoSwift',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
