import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_vault/features/auth/domain/entities/app_user.dart';
import 'package:home_vault/features/auth/presentation/providers/auth_providers.dart';
import 'package:home_vault/features/auth/presentation/screens/login_screen.dart';
import 'package:home_vault/features/auth/presentation/screens/register_screen.dart';
import 'package:home_vault/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:home_vault/features/items/domain/entities/item.dart';
import 'package:home_vault/features/items/presentation/screens/add_edit_item_screen.dart';
import 'package:home_vault/features/scanner/domain/entities/scan_result.dart';
import 'package:home_vault/features/scanner/presentation/screens/scanner_screen.dart';
import 'package:home_vault/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:home_vault/features/splash/presentation/screens/splash_screen.dart';

abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String addItem = '/items/add';
  static const String scanner = '/scanner';
  static const String notificationSettings = '/settings/notifications';
  static String editItem(String id) => '/items/$id/edit';
}

// Listens to auth state changes and triggers GoRouter to re-evaluate redirects.
final _routerNotifierProvider =
    ChangeNotifierProvider<_RouterNotifier>(_RouterNotifier.new);

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    _authValue = ref.read(authStateProvider);
    ref.listen<AsyncValue<AppUser?>>(
      authStateProvider,
      (_, next) {
        _authValue = next;
        notifyListeners();
      },
    );
  }

  AsyncValue<AppUser?> _authValue = const AsyncValue.loading();

  String? redirect(GoRouterState state) {
    final authValue = _authValue;
    final location = state.matchedLocation;

    // Auth still loading — only the splash is safe to show.
    if (authValue.isLoading) {
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    }

    final isLoggedIn = authValue.valueOrNull != null;
    final isAuthRoute =
        location == AppRoutes.login || location == AppRoutes.register;
    final isSplash = location == AppRoutes.splash;

    // Splash manages its own navigation.
    if (isSplash) return null;

    // Unauthenticated user trying to access a protected route.
    if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;

    // Authenticated user on a login/register page.
    if (isLoggedIn && isAuthRoute) return AppRoutes.dashboard;

    return null;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: (context, state) => notifier.redirect(state),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.addItem,
        name: 'add-item',
        builder: (_, state) => AddEditItemScreen(
          scanResult: state.extra is ScanResult ? state.extra as ScanResult : null,
        ),
      ),
      GoRoute(
        path: '/items/:id/edit',
        name: 'edit-item',
        builder: (_, state) => AddEditItemScreen(
          existingItem: state.extra as Item?,
        ),
      ),
      GoRoute(
        path: AppRoutes.scanner,
        name: 'scanner',
        builder: (_, __) => const ScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        name: 'notification-settings',
        builder: (_, __) => const NotificationSettingsScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});
