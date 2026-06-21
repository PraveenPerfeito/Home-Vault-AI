import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_vault/core/di/providers.dart';
import 'package:home_vault/core/error/app_exception.dart';
import 'package:home_vault/features/auth/presentation/providers/auth_providers.dart';
import 'package:home_vault/features/items/data/datasources/items_remote_datasource.dart';
import 'package:home_vault/features/items/data/repositories/items_repository_impl.dart';
import 'package:home_vault/features/items/domain/entities/item.dart';
import 'package:home_vault/features/items/domain/repositories/items_repository.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────

final itemsRemoteDatasourceProvider = Provider<ItemsRemoteDatasource>((ref) {
  return ItemsRemoteDatasourceImpl(
    firestore: ref.watch(firestoreProvider),
  );
});

final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  return ItemsRepositoryImpl(
    datasource: ref.watch(itemsRemoteDatasourceProvider),
  );
});

// ── Items Stream ─────────────────────────────────────────────────────────────

/// Real-time list of all items for the signed-in user.
/// Emits an empty list when signed out.
final itemsStreamProvider = StreamProvider.autoDispose<List<Item>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(itemsRepositoryProvider).watchItems(userId: user.id);
});

// ── Expiry Dashboard ─────────────────────────────────────────────────────────

/// Items bucketed into 5 expiry sections, sorted within each section.
///
/// Each item appears in exactly ONE section based on its urgency:
///   expired → expiringToday → expiringWeek → expiringMonth → recentlyAdded
class ExpiryDashboardData {
  final List<Item> expired;
  final List<Item> expiringToday;
  final List<Item> expiringWeek;  // 1–7 days
  final List<Item> expiringMonth; // 8–30 days
  final List<Item> recentlyAdded; // >30 days or no expiry — sorted by createdAt desc

  const ExpiryDashboardData({
    required this.expired,
    required this.expiringToday,
    required this.expiringWeek,
    required this.expiringMonth,
    required this.recentlyAdded,
  });

  int get totalCount =>
      expired.length +
      expiringToday.length +
      expiringWeek.length +
      expiringMonth.length +
      recentlyAdded.length;

  int get expiredCount => expired.length;

  // "Expiring soon" = today + within 7 days
  int get expiringSoonCount => expiringToday.length + expiringWeek.length;

  bool get isEmpty => totalCount == 0;
}

final expiryDashboardProvider =
    Provider.autoDispose<ExpiryDashboardData>((ref) {
  final items = ref.watch(itemsStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final expired = <Item>[];
  final expiringToday = <Item>[];
  final expiringWeek = <Item>[];
  final expiringMonth = <Item>[];
  final recentlyAdded = <Item>[];

  for (final item in items) {
    final expiry = item.expiryDate;
    if (expiry == null) {
      recentlyAdded.add(item);
      continue;
    }
    // Compare at day granularity (ignore time-of-day)
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    final daysDiff = expiryDay.difference(today).inDays;

    if (daysDiff < 0) {
      expired.add(item);
    } else if (daysDiff == 0) {
      expiringToday.add(item);
    } else if (daysDiff <= 7) {
      expiringWeek.add(item);
    } else if (daysDiff <= 30) {
      expiringMonth.add(item);
    } else {
      recentlyAdded.add(item);
    }
  }

  // Sort each section for maximum usefulness
  // Expired: most recently expired first (so user sees what just expired)
  expired.sort((a, b) => b.expiryDate!.compareTo(a.expiryDate!));
  // Today: alphabetical (few items, order matters less)
  expiringToday.sort((a, b) => a.name.compareTo(b.name));
  // Week + Month: soonest first (most urgent at top)
  expiringWeek.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
  expiringMonth.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
  // Recently Added: newest first
  recentlyAdded.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return ExpiryDashboardData(
    expired: expired,
    expiringToday: expiringToday,
    expiringWeek: expiringWeek,
    expiringMonth: expiringMonth,
    recentlyAdded: recentlyAdded,
  );
});

// ── CRUD Actions ─────────────────────────────────────────────────────────────

final itemActionsProvider =
    AutoDisposeAsyncNotifierProvider<ItemActionsNotifier, void>(
  ItemActionsNotifier.new,
);

class ItemActionsNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  ItemsRepository get _repo => ref.read(itemsRepositoryProvider);

  Future<void> createItem({
    required String name,
    required ItemCategory category,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? notes,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.createItem(Item(
          id: '', // Firestore generates the real ID via collection.add()
          userId: user.id,
          name: name.trim(),
          category: category,
          purchaseDate: purchaseDate,
          expiryDate: expiryDate,
          notes: notes,
          createdAt: DateTime.now(),
        )));
  }

  Future<void> updateItem(Item item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.updateItem(item));
  }

  Future<void> deleteItem(Item item) async {
    // H5: always derive userId from the Firebase Auth token — never from the
    // domain entity, which could carry a Firestore-sourced value.
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      state = AsyncError(
        const AuthException('Not signed in.'),
        StackTrace.current,
      );
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.deleteItem(itemId: item.id, userId: userId),
    );
  }
}
