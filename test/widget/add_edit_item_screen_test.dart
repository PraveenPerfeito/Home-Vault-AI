import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault/features/auth/domain/entities/app_user.dart';
import 'package:home_vault/features/items/domain/entities/item.dart';
import 'package:home_vault/features/items/presentation/screens/add_edit_item_screen.dart';
import 'package:home_vault/features/scanner/domain/entities/scan_result.dart';

import '../helpers/pump_app.dart';

AppUser _fakeUser() => AppUser(
      id: 'user-001',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: null,
      isAnonymous: false,
      plan: 'free',
      createdAt: DateTime(2026, 1, 1),
    );

Item _fakeItem() => Item(
      id: 'item-001',
      userId: 'user-001',
      name: 'Paracetamol 500mg',
      category: ItemCategory.medicine,
      createdAt: DateTime(2026, 1, 1),
      expiryDate: DateTime(2027, 12, 31),
    );

void main() {
  group('AddEditItemScreen', () {
    group('Add mode', () {
      testWidgets('shows "Add Item" title', (tester) async {
        await tester.pumpApp(
          const AddEditItemScreen(),
          overrides: itemOverrides(user: _fakeUser()),
        );
        expect(find.text('Add Item'), findsOneWidget);
      });

      testWidgets('shows product name field', (tester) async {
        await tester.pumpApp(
          const AddEditItemScreen(),
          overrides: itemOverrides(user: _fakeUser()),
        );
        expect(
          find.widgetWithText(TextFormField, 'Product Name *'),
          findsOneWidget,
        );
      });

      testWidgets('empty name shows validation error on save', (tester) async {
        await tester.pumpApp(
          const AddEditItemScreen(),
          overrides: itemOverrides(user: _fakeUser()),
        );
        await tester.tap(find.text('Save'));
        await tester.pump();
        expect(find.text('Name is required'), findsOneWidget);
      });

      testWidgets('valid name passes validation', (tester) async {
        await tester.pumpApp(
          const AddEditItemScreen(),
          overrides: itemOverrides(user: _fakeUser()),
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Product Name *'),
          'Milk Packet',
        );
        await tester.pump();
        expect(find.text('Name is required'), findsNothing);
      });
    });

    group('Edit mode', () {
      testWidgets('shows "Edit Item" title', (tester) async {
        await tester.pumpApp(
          AddEditItemScreen(existingItem: _fakeItem()),
          overrides: itemOverrides(user: _fakeUser()),
        );
        expect(find.text('Edit Item'), findsOneWidget);
      });

      testWidgets('pre-fills existing item name', (tester) async {
        await tester.pumpApp(
          AddEditItemScreen(existingItem: _fakeItem()),
          overrides: itemOverrides(user: _fakeUser()),
        );
        expect(find.text('Paracetamol 500mg'), findsOneWidget);
      });
    });

    group('OCR pre-fill mode', () {
      testWidgets('shows scan result banner', (tester) async {
        await tester.pumpApp(
          AddEditItemScreen(
            scanResult: const ScanResult(
              rawText: 'PARACETAMOL\nEXP: 06/2027',
              extractedName: 'PARACETAMOL',
              extractedExpiry: null,
            ),
          ),
          overrides: itemOverrides(user: _fakeUser()),
        );
        expect(
          find.textContaining('Values pre-filled from label scan'),
          findsOneWidget,
        );
      });

      testWidgets('pre-fills name from scan result', (tester) async {
        await tester.pumpApp(
          AddEditItemScreen(
            scanResult: const ScanResult(
              rawText: 'DOVE SOAP\nEXP: 08/2027',
              extractedName: 'DOVE SOAP',
              extractedExpiry: null,
            ),
          ),
          overrides: itemOverrides(user: _fakeUser()),
        );
        expect(find.text('DOVE SOAP'), findsOneWidget);
      });

      testWidgets('no banner shown without scan result', (tester) async {
        await tester.pumpApp(
          const AddEditItemScreen(),
          overrides: itemOverrides(user: _fakeUser()),
        );
        expect(
          find.textContaining('Values pre-filled'),
          findsNothing,
        );
      });
    });
  });
}
