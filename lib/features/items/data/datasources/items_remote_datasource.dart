import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_vault/core/error/app_exception.dart';
import 'package:home_vault/features/items/data/models/item_model.dart';

abstract class ItemsRemoteDatasource {
  Stream<List<ItemModel>> watchItems({required String userId});
  Future<void> createItem(ItemModel item);
  Future<void> updateItem(ItemModel item);
  Future<void> deleteItem({required String itemId, required String userId});
}

class ItemsRemoteDatasourceImpl implements ItemsRemoteDatasource {
  final FirebaseFirestore _firestore;

  ItemsRemoteDatasourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _firestore.collection('users').doc(userId).collection('items');

  @override
  Stream<List<ItemModel>> watchItems({required String userId}) {
    return _col(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ItemModel.fromFirestore(d.data(), d.id)).toList());
  }

  @override
  Future<void> createItem(ItemModel item) async {
    try {
      // Let Firestore generate the document ID.
      await _col(item.userId).add(item.toFirestore());
    } catch (e) {
      throw StorageException('Failed to create item.', cause: e);
    }
  }

  @override
  Future<void> updateItem(ItemModel item) async {
    try {
      await _col(item.userId).doc(item.id).update(item.toFirestore());
    } catch (e) {
      throw StorageException('Failed to update item.', cause: e);
    }
  }

  @override
  Future<void> deleteItem({
    required String itemId,
    required String userId,
  }) async {
    try {
      await _col(userId).doc(itemId).delete();
    } catch (e) {
      throw StorageException('Failed to delete item.', cause: e);
    }
  }
}
