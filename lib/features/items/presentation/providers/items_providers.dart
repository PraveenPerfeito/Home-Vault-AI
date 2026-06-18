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

// ── Derived stats ─────────────────────────────────────────────────────────

class ItemStats {
  final int total;
  final int expiringSoon; // within 7 days
  final int expired;

  const ItemStats({
    required this.total,
    required this.expiringSoon,
    required this.expired,
  });
}

final itemStatsProvider = Provider.autoDispose<ItemStats>((ref) {
  final items = ref.watch(itemsStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();

  int expiringSoon = 0;
  int expired = 0;

  for (final item in items) {
    if (item.expiryDate == null) continue;
    final days = item.expiryDate!.difference(now).inDays;
    if (days < 0) {
      expired++;
    } else if (days <= 7) {
      expiringSoon++;
    }
  }

  return ItemStats(
    total: items.length,
    expiringSoon: expiringSoon,
    expired: expired,
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
          name: name,
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
