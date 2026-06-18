import 'package:home_vault/features/items/data/datasources/items_remote_datasource.dart';
import 'package:home_vault/features/items/data/models/item_model.dart';
import 'package:home_vault/features/items/domain/entities/item.dart';
import 'package:home_vault/features/items/domain/repositories/items_repository.dart';

class ItemsRepositoryImpl implements ItemsRepository {
  final ItemsRemoteDatasource _datasource;

  ItemsRepositoryImpl({required ItemsRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Stream<List<Item>> watchItems({required String userId}) =>
      _datasource
          .watchItems(userId: userId)
          .map((models) => models.map((m) => m.toEntity()).toList());

  @override
  Future<void> createItem(Item item) =>
      _datasource.createItem(ItemModel.fromEntity(item));

  @override
  Future<void> updateItem(Item item) =>
      _datasource.updateItem(ItemModel.fromEntity(item));

  @override
  Future<void> deleteItem({
    required String itemId,
    required String userId,
  }) =>
      _datasource.deleteItem(itemId: itemId, userId: userId);
}
