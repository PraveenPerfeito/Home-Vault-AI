import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_vault/core/config/app_config.dart';
import 'package:home_vault/firebase_options.dart';
import 'package:home_vault/core/logging/app_logger.dart';
import 'package:home_vault/core/router/app_router.dart';
import 'package:home_vault/core/storage/hive_service.dart';
import 'package:home_vault/core/theme/app_theme.dart';
import 'package:home_vault/features/notifications/domain/services/notification_service.dart';
import 'package:home_vault/features/notifications/presentation/providers/notification_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors (widget build, layout, etc.).
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('[HomeVault] Flutter error: ${details.exception}');
    debugPrint('[HomeVault] Stack: ${details.stack}');
  };

  // Catch async Dart errors that escape the Flutter framework (platform channel
  // callbacks, isolate errors, etc.) — prevents silent app termination.
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[HomeVault] Platform error: $error');
    debugPrint('[HomeVault] Stack: $stack');
    return true;
  };

  await HiveService.init();
  await _initFirebase();

  // Initialize local notification service and timezone data.
  final notifService = NotificationService();
  try {
    await notifService.initialize();
  } catch (e) {
    debugPrint('[HomeVault] NotificationService init failed: $e');
  }

  AppLogger.init();
  AppLogger.info('App starting — env: ${AppConfig.env}');

  runApp(
    ProviderScope(
      overrides: [
        // Provide the pre-initialized service so callers never race against
        // the async initialize() call.
        notificationServiceProvider.overrideWithValue(notifService),
      ],
      child: const HomeVaultApp(),
    ),
  );
}

// Firebase fails gracefully until `flutterfire configure` is run.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[HomeVault] Firebase not configured — run: flutterfire configure');
  }
}

class HomeVaultApp extends ConsumerWidget {
  const HomeVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Keep the notification sync provider alive for the full app lifetime.
    // The provider watches itemsStreamProvider and schedules/cancels
    // notifications reactively — no UI rebuilds triggered (void state).
    ref.watch(notificationSyncProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
