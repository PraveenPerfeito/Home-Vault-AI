import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault/features/auth/presentation/screens/register_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  group('RegisterScreen', () {
    group('initial render', () {
      testWidgets('shows app bar with "Create Account"', (tester) async {
        await tester.pumpApp(
          const RegisterScreen(),
          overrides: authOverrides(),
        );
        expect(find.text('Create Account'), findsWidgets);
      });

      testWidgets('shows all three form fields', (tester) async {
        await tester.pumpApp(
          const RegisterScreen(),
          overrides: authOverrides(),
        );
        expect(
          find.widgetWithText(TextFormField, 'Display Name'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextFormField, 'Email'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextFormField, 'Password'),
          findsOneWidget,
        );
      });
    });

    group('form validation', () {
      Future<void> tapSubmit(WidgetTester tester) async {
        final submitBtn = find.widgetWithText(ElevatedButton, 'Create Account');
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pump();
      }

      testWidgets('empty display name shows error', (tester) async {
        await tester.pumpApp(
          const RegisterScreen(),
          overrides: authOverrides(),
        );
        await tapSubmit(tester);
        expect(find.text('Enter your name'), findsOneWidget);
      });

      testWidgets('empty email shows error', (tester) async {
        await tester.pumpApp(
          const RegisterScreen(),
          overrides: authOverrides(),
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Display Name'),
          'Alice',
        );
        await tapSubmit(tester);
        expect(find.text('Enter your email'), findsOneWidget);
      });

      testWidgets('invalid email format shows error', (tester) async {
        await tester.pumpApp(
          const RegisterScreen(),
          overrides: authOverrides(),
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Display Name'),
          'Alice',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'bademail',
        );
        await tapSubmit(tester);
        expect(find.text('Enter a valid email'), findsOneWidget);
      });

      testWidgets('password shorter than 6 chars shows error', (tester) async {
        await tester.pumpApp(
          const RegisterScreen(),
          overrides: authOverrides(),
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Display Name'),
          'Alice',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'alice@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'abc',
        );
        await tapSubmit(tester);
        expect(find.text('Min 6 characters'), findsOneWidget);
      });

      testWidgets('valid inputs produce no validation errors', (tester) async {
        await tester.pumpApp(
          const RegisterScreen(),
          overrides: authOverrides(),
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Display Name'),
          'Alice Smith',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'alice@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'securepassword',
        );
        await tapSubmit(tester);
        await tester.pump();

        expect(find.text('Enter your name'), findsNothing);
        expect(find.text('Enter your email'), findsNothing);
        expect(find.text('Enter a valid email'), findsNothing);
        expect(find.text('Min 6 characters'), findsNothing);
      });

      testWidgets('exactly 6 character password passes validation', (tester) async {
        await tester.pumpApp(
          const RegisterScreen(),
          overrides: authOverrides(),
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Display Name'),
          'Bob',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'bob@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'abc123',
        );
        await tapSubmit(tester);
        await tester.pump();
        expect(find.text('Min 6 characters'), findsNothing);
      });
    });
  });
}
