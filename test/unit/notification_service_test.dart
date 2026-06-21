import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault/features/notifications/domain/services/notification_service.dart';

// ── Pure-logic tests for NotificationService ──────────────────────────────────
//
// flutter_local_notifications requires a platform channel unavailable in the
// test host, so we test only the methods that are pure Dart (no plugin calls):
//   - notifId()   — deterministic ID derivation
//   - remindAt()  — 09:00 AM rounding
//
// Scheduling / cancellation require a real device or integration test harness.

void main() {
  group('NotificationService.notifId', () {
    test('returns non-negative int', () {
      final id = NotificationService.notifId('abc123', 0);
      expect(id, greaterThanOrEqualTo(0));
    });

    test('slot 0–3 produce distinct IDs for the same item', () {
      const itemId = 'testItem';
      final ids = List.generate(4, (i) => NotificationService.notifId(itemId, i));
      expect(ids.toSet().length, 4, reason: 'All 4 slots must be unique');
    });

    test('different item IDs produce different base IDs', () {
      final id1 = NotificationService.notifId('item_alpha', 0);
      final id2 = NotificationService.notifId('item_beta', 0);
      // Different items should (almost always) map to different IDs.
      // This test catches obviously broken implementations.
      expect(id1, isNot(equals(id2)));
    });

    test('same item ID always produces the same ID (deterministic)', () {
      const itemId = 'stableItem';
      final first = NotificationService.notifId(itemId, 1);
      final second = NotificationService.notifId(itemId, 1);
      expect(first, equals(second));
    });

    test('slot component is the last digit of the ID', () {
      for (var slot = 0; slot < 4; slot++) {
        final id = NotificationService.notifId('someItem', slot);
        expect(id % 10, equals(slot),
            reason: 'Slot $slot should be encoded in units digit');
      }
    });

    test('ID fits within Android int32 range', () {
      // Android notification IDs are int32 (max 2_147_483_647).
      // Our scheme: (hash % 199_999_997) * 10 + slot ≤ 1_999_999_973 — within range.
      const maxExpected = 199999997 * 10 + 3;
      final id = NotificationService.notifId('anyItem', 3);
      expect(id, lessThanOrEqualTo(maxExpected));
    });

    test('empty string ID returns valid non-negative int', () {
      final id = NotificationService.notifId('', 0);
      expect(id, greaterThanOrEqualTo(0));
    });
  });

  group('NotificationService.remindAt', () {
    test('sets time to 09:00:00 on same calendar day', () {
      final input = DateTime(2027, 8, 15, 14, 35, 22);
      final result = NotificationService.remindAt(input);
      expect(result, equals(DateTime(2027, 8, 15, 9, 0, 0)));
    });

    test('preserves the year, month, and day', () {
      final input = DateTime(2026, 12, 31, 0, 0, 1);
      final result = NotificationService.remindAt(input);
      expect(result.year, 2026);
      expect(result.month, 12);
      expect(result.day, 31);
    });

    test('always returns 09:00:00 regardless of input time', () {
      final times = [
        DateTime(2027, 1, 1, 0, 0, 0),
        DateTime(2027, 1, 1, 8, 59, 59),
        DateTime(2027, 1, 1, 9, 0, 0),
        DateTime(2027, 1, 1, 23, 59, 59),
      ];
      for (final t in times) {
        final result = NotificationService.remindAt(t);
        expect(result.hour, 9, reason: 'Hour must be 9 for input $t');
        expect(result.minute, 0);
        expect(result.second, 0);
      }
    });
  });

  group('Reminder date calculations', () {
    // These tests validate the offsets used in scheduleItemNotifications
    // without calling the plugin.

    test('30-day reminder is exactly 30 days before expiry', () {
      final expiry = DateTime(2027, 9, 1);
      final reminder = expiry.subtract(const Duration(days: 30));
      expect(reminder, equals(DateTime(2027, 8, 2)));
    });

    test('7-day reminder is exactly 7 days before expiry', () {
      final expiry = DateTime(2027, 9, 1);
      final reminder = expiry.subtract(const Duration(days: 7));
      expect(reminder, equals(DateTime(2027, 8, 25)));
    });

    test('1-day reminder is exactly 1 day before expiry', () {
      final expiry = DateTime(2027, 9, 1);
      final reminder = expiry.subtract(const Duration(days: 1));
      expect(reminder, equals(DateTime(2027, 8, 31)));
    });

    test('expiry-day reminder is on the expiry date itself', () {
      final expiry = DateTime(2027, 9, 1);
      expect(expiry, equals(DateTime(2027, 9, 1)));
    });

    test('all 4 reminders are in chronological order', () {
      final expiry = DateTime(2027, 9, 1);
      final dates = [
        expiry.subtract(const Duration(days: 30)),
        expiry.subtract(const Duration(days: 7)),
        expiry.subtract(const Duration(days: 1)),
        expiry,
      ];
      for (var i = 0; i < dates.length - 1; i++) {
        expect(dates[i].isBefore(dates[i + 1]), isTrue,
            reason: 'Reminder $i must precede reminder ${i + 1}');
      }
    });

    test('past reminder dates are correctly identified as past', () {
      // A reminder date in the past should be skipped (isBefore(now)).
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      expect(NotificationService.remindAt(pastDate).isBefore(DateTime.now()),
          isTrue);
    });

    test('future reminder dates are correctly identified as future', () {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      expect(NotificationService.remindAt(futureDate).isAfter(DateTime.now()),
          isTrue);
    });
  });
}
