import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:home_vault/core/theme/app_theme.dart';
import 'package:home_vault/features/auth/domain/entities/app_user.dart';
import 'package:home_vault/features/auth/presentation/providers/auth_providers.dart';
import 'package:home_vault/features/items/presentation/providers/items_providers.dart';

// ── Fake notifiers — extend concrete classes so overrideWith types match ───

class FakeAuthActionsNotifier extends AuthActionsNotifier {
  @override
  Future<void> build() async {}
}

class FakeItemActionsNotifier extends ItemActionsNotifier {
  @override
  Future<void> build() async {}
}

// ── Standard overrides ─────────────────────────────────────────────────────

List<Override> authOverrides({AppUser? user}) => [
      authActionsProvider.overrideWith(FakeAuthActionsNotifier.new),
      authStateProvider.overrideWith(
        (ref) => Stream.value(user),
      ),
    ];

List<Override> itemOverrides({AppUser? user}) => [
      ...authOverrides(user: user),
      itemActionsProvider.overrideWith(FakeItemActionsNotifier.new),
    ];

// ── Router helper ──────────────────────────────────────────────────────────

GoRouter testRouter(Widget home) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => home),
        GoRoute(
            path: '/register',
            builder: (_, __) =>
                const Scaffold(body: Text('RegisterScreen'))),
        GoRoute(
            path: '/login',
            builder: (_, __) => const Scaffold(body: Text('LoginScreen'))),
        GoRoute(
            path: '/dashboard',
            builder: (_, __) =>
                const Scaffold(body: Text('DashboardScreen'))),
      ],
      errorBuilder: (_, s) =>
          Scaffold(body: Text('404: ${s.uri}')),
    );

// ── Extension on WidgetTester ──────────────────────────────────────────────

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget child, {
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: testRouter(child),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
    await pump();
  }
}
