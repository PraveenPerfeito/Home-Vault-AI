import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_vault/core/config/app_config.dart';
import 'package:home_vault/core/config/firebase_options.dart';
import 'package:home_vault/core/logging/app_logger.dart';
import 'package:home_vault/core/router/app_router.dart';
import 'package:home_vault/core/storage/hive_service.dart';
import 'package:home_vault/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  await _initFirebase();

  AppLogger.init();
  AppLogger.info('App starting — env: ${AppConfig.env}');

  runApp(
    const ProviderScope(
      child: HomeVaultApp(),
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
