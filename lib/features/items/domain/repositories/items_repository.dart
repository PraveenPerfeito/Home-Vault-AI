import 'package:home_vault/features/items/domain/entities/item.dart';

abstract class ItemsRepository {
  /// Real-time stream of all items for [userId], newest first.
  Stream<List<Item>> watchItems({required String userId});

  Future<void> createItem(Item item);

  Future<void> updateItem(Item item);

  Future<void> deleteItem({required String itemId, required String userId});
}
