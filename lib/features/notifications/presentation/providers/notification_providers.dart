import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_vault/core/logging/app_logger.dart';
import 'package:home_vault/features/items/domain/entities/item.dart';
import 'package:home_vault/features/items/presentation/providers/items_providers.dart';
import 'package:home_vault/features/notifications/domain/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Service ───────────────────────────────────────────────────────────────────

/// Singleton notification service. Overridden in main() with the pre-initialized
/// instance so callers never race against [NotificationService.initialize].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ── Permission status ─────────────────────────────────────────────────────────

/// Current Android notification permission status.
/// Invalidated via [ref.invalidate(notificationPermissionProvider)] after
/// requesting or after returning from settings.
final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  return ref.read(notificationServiceProvider).hasPermission();
});

// ── Enabled toggle ────────────────────────────────────────────────────────────

const _kEnabledKey = 'notifications_enabled';

/// Whether the user has enabled expiry reminders.
/// Persisted via SharedPreferences. Defaults to true on first launch.
final notificationsEnabledProvider =
    AsyncNotifierProvider<NotificationsEnabledNotifier, bool>(
  NotificationsEnabledNotifier.new,
);

class NotificationsEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final svc = ref.read(notificationServiceProvider);
    if (!value) {
      await svc.cancelAll();
    } else {
      // Re-schedule all existing items when re-enabled.
      final items = ref.read(itemsStreamProvider).valueOrNull ?? [];
      for (final item in items) {
        await svc.scheduleItemNotifications(item);
      }
    }
    state = AsyncData(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, value);
  }
}

// ── Reactive sync ─────────────────────────────────────────────────────────────

/// Watches [itemsStreamProvider] and keeps notification schedules in sync.
///
/// Lifecycle:
/// - NEW item detected (id not in _knownExpiry) → schedule
/// - CHANGED expiryDate → reschedule (cancel old + schedule new)
/// - REMOVED item (id absent from current list) → cancel
///
/// Non-autoDispose so it lives for the full app lifetime and keeps
/// [itemsStreamProvider] alive even when no UI widget is subscribed.
final notificationSyncProvider =
    NotifierProvider<NotificationSyncNotifier, void>(
  NotificationSyncNotifier.new,
);

class NotificationSyncNotifier extends Notifier<void> {
  // itemId → last known expiryDate (null = item has no expiry)
  final _knownExpiry = <String, DateTime?>{};

  @override
  void build() {
    ref.listen<AsyncValue<List<Item>>>(
      itemsStreamProvider,
      (_, next) => next.whenData(_sync),
    );
  }

  Future<void> _sync(List<Item> items) async {
    final enabled = ref.read(notificationsEnabledProvider).valueOrNull ?? true;
    if (!enabled) return;

    final svc = ref.read(notificationServiceProvider);
    final currentIds = {for (final i in items) i.id};

    // Cancel notifications for items that were deleted.
    for (final id in _knownExpiry.keys.toList()) {
      if (!currentIds.contains(id)) {
        try {
          await svc.cancelItemNotifications(id);
        } catch (e) {
          AppLogger.warning('Failed to cancel notifications for $id: $e');
        }
        _knownExpiry.remove(id);
      }
    }

    // Schedule / reschedule for new or updated items.
    for (final item in items) {
      final prevExpiry = _knownExpiry[item.id];
      final isNew = !_knownExpiry.containsKey(item.id);
      final hasChanged = !isNew && prevExpiry != item.expiryDate;

      if (isNew || hasChanged) {
        try {
          await svc.scheduleItemNotifications(item);
        } catch (e) {
          AppLogger.warning('Failed to schedule notifications for ${item.id}: $e');
        }
        _knownExpiry[item.id] = item.expiryDate;
      }
    }
  }
}
