import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault/features/auth/presentation/screens/login_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  group('LoginScreen', () {
    group('initial render', () {
      testWidgets('shows Google sign-in button', (tester) async {
        await tester.pumpApp(
          const LoginScreen(),
          overrides: authOverrides(),
        );
        expect(find.text('Continue with Google'), findsOneWidget);
      });

      testWidgets('shows email toggle button', (tester) async {
        await tester.pumpApp(
          const LoginScreen(),
          overrides: authOverrides(),
        );
        expect(find.text('Sign In with Email'), findsOneWidget);
      });

      testWidgets('shows guest button', (tester) async {
        await tester.pumpApp(
          const LoginScreen(),
          overrides: authOverrides(),
        );
        expect(find.text('Continue as Guest'), findsOneWidget);
      });

      testWidgets('email form is hidden initially', (tester) async {
        await tester.pumpApp(
          const LoginScreen(),
          overrides: authOverrides(),
        );
        expect(find.widgetWithText(TextFormField, 'Email'), findsNothing);
      });
    });

    group('email form toggle', () {
      testWidgets('tapping email button reveals form fields', (tester) async {
        await tester.pumpApp(
          const LoginScreen(),
          overrides: authOverrides(),
        );
        await tester.tap(find.text('Sign In with Email'));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      });

      testWidgets('tapping email button twice hides form again', (tester) async {
        await tester.pumpApp(
          const LoginScreen(),
          overrides: authOverrides(),
        );
        await tester.tap(find.text('Sign In with Email'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hide Email Form'));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextFormField, 'Email'), findsNothing);
      });
    });

    group('email form validation', () {
      Future<void> openEmailForm(WidgetTester tester) async {
        await tester.pumpApp(
          const LoginScreen(),
          overrides: authOverrides(),
        );
        await tester.tap(find.text('Sign In with Email'));
        await tester.pumpAndSettle();
      }

      testWidgets('empty email shows error', (tester) async {
        await openEmailForm(tester);
        await tester.ensureVisible(find.text('Sign In'));
        await tester.tap(find.text('Sign In'));
        await tester.pump();
        expect(find.text('Enter your email'), findsOneWidget);
      });

      testWidgets('invalid email format shows error', (tester) async {
        await openEmailForm(tester);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'notanemail',
        );
        await tester.ensureVisible(find.text('Sign In'));
        await tester.tap(find.text('Sign In'));
        await tester.pump();
        expect(find.text('Enter a valid email'), findsOneWidget);
      });

      testWidgets('short password shows error', (tester) async {
        await openEmailForm(tester);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'user@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          '123',
        );
        await tester.ensureVisible(find.text('Sign In'));
        await tester.tap(find.text('Sign In'));
        await tester.pump();
        expect(find.text('Min 6 characters'), findsOneWidget);
      });

      testWidgets('valid inputs produce no validation errors', (tester) async {
        await openEmailForm(tester);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'user@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );
        await tester.pump();
        expect(find.text('Enter your email'), findsNothing);
        expect(find.text('Enter a valid email'), findsNothing);
        expect(find.text('Min 6 characters'), findsNothing);
      });
    });

    group('app title / branding', () {
      testWidgets('shows Home Vault title', (tester) async {
        await tester.pumpApp(
          const LoginScreen(),
          overrides: authOverrides(),
        );
        expect(find.text('Home Vault'), findsOneWidget);
      });

      testWidgets('shows welcome text', (tester) async {
        await tester.pumpApp(
          const LoginScreen(),
          overrides: authOverrides(),
        );
        expect(find.text('Welcome back'), findsOneWidget);
      });
    });
  });
}
