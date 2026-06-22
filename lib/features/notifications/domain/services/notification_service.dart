import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:home_vault/features/items/domain/entities/item.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Manages local expiry-reminder notifications.
///
/// **Notification ID scheme**
/// Each item gets 4 notification slots, derived deterministically from its
/// Firestore document ID so IDs survive app restarts:
///
///   notifId(itemId, slot) = (itemId.hashCode.abs() % 199_999_997) * 10 + slot
///
///   slot 0 → 30-day reminder
///   slot 1 →  7-day reminder
///   slot 2 →  1-day reminder
///   slot 3 → expiry-day reminder
///
/// Max ID: 199_999_997 × 10 + 3 = 1_999_999_973 — safely within Android int32
/// (max 2_147_483_647). Collision probability at 100 items: ~0.0025%.
///
/// **Scheduling**
/// All reminders fire at 09:00 local time on their target day. Reminders whose
/// scheduled time is already in the past are silently skipped.
///
/// **Threading**
/// All public methods are safe to call from any isolate after [initialize].
class NotificationService {
  static const _channelId = 'expiry_reminders';
  static const _channelName = 'Expiry Reminders';
  static const _channelDesc = 'Upcoming product expiry date reminders';

  static const _slot30 = 0;
  static const _slot7 = 1;
  static const _slot1 = 2;
  static const _slotToday = 3;

  static const _reminderHour = 9; // 09:00 local time

  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  // ── Public helpers ─────────────────────────────────────────────────────────

  /// Deterministic notification ID for a given item + slot.
  /// Pure function — testable without plugin.
  static int notifId(String itemId, int slot) =>
      (itemId.hashCode.abs() % 199999997) * 10 + slot;

  /// Returns the 09:00 AM time on [date]'s calendar day.
  static DateTime remindAt(DateTime date) =>
      DateTime(date.year, date.month, date.day, _reminderHour);

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    // Set the local timezone so scheduled notifications fire at the correct
    // local time instead of always using UTC.
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Falls back to UTC if timezone detection fails — better than crashing.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    // Create the notification channel (no-op if it already exists).
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Permissions ────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;
    return await androidPlugin.requestNotificationsPermission() ?? false;
  }

  Future<bool> hasPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;
    return await androidPlugin.areNotificationsEnabled() ?? false;
  }

  // ── Scheduling ─────────────────────────────────────────────────────────────

  /// Schedules up to 4 reminders for [item].
  ///
  /// Cancels any previously scheduled notifications for this item first, so
  /// this method is safe to call on both create and update.
  /// Items with no [expiryDate] or an empty [id] are silently ignored.
  Future<void> scheduleItemNotifications(Item item) async {
    if (item.expiryDate == null || item.id.isEmpty) return;

    await cancelItemNotifications(item.id);

    final expiry = item.expiryDate!;
    final reminders = [
      (
        _slot30,
        expiry.subtract(const Duration(days: 30)),
        'Expires in 30 days',
        'Your ${item.name} expires in 30 days.',
      ),
      (
        _slot7,
        expiry.subtract(const Duration(days: 7)),
        'Expires in 7 days',
        'Your ${item.name} expires in 7 days.',
      ),
      (
        _slot1,
        expiry.subtract(const Duration(days: 1)),
        'Expires tomorrow',
        'Your ${item.name} expires tomorrow.',
      ),
      (
        _slotToday,
        expiry,
        'Expires today',
        'Your ${item.name} expires today.',
      ),
    ];

    for (final (slot, date, title, body) in reminders) {
      await _scheduleIfFuture(item.id, slot, date, title, body);
    }
  }

  /// Cancels all 4 reminder slots for the given item ID.
  Future<void> cancelItemNotifications(String itemId) async {
    for (final slot in [_slot30, _slot7, _slot1, _slotToday]) {
      await _plugin.cancel(notifId(itemId, slot));
    }
  }

  /// Cancels every pending notification — used when disabling notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _scheduleIfFuture(
    String itemId,
    int slot,
    DateTime targetDate,
    String title,
    String body,
  ) async {
    final scheduledAt = remindAt(targetDate);
    if (scheduledAt.isBefore(DateTime.now())) return;

    final tzDate = tz.TZDateTime.from(scheduledAt, tz.local);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await androidPlugin?.canScheduleExactNotifications() ?? false;

    await _plugin.zonedSchedule(
      notifId(itemId, slot),
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
