import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_vault/features/items/domain/entities/item.dart';

class ItemModel {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String? photoUrl;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final String? notes;
  final DateTime createdAt;

  const ItemModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.createdAt,
    this.photoUrl,
    this.purchaseDate,
    this.expiryDate,
    this.notes,
  });

  factory ItemModel.fromFirestore(Map<String, dynamic> data, String id) =>
      ItemModel(
        id: id,
        userId: (data['userId'] as String?) ?? '',
        name: (data['name'] as String?) ?? 'Unknown',
        category: (data['category'] as String?) ?? 'other',
        photoUrl: data['photoUrl'] as String?,
        purchaseDate: data['purchaseDate'] is Timestamp
            ? (data['purchaseDate'] as Timestamp).toDate()
            : null,
        expiryDate: data['expiryDate'] is Timestamp
            ? (data['expiryDate'] as Timestamp).toDate()
            : null,
        notes: data['notes'] as String?,
        createdAt: data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  factory ItemModel.fromEntity(Item item) => ItemModel(
        id: item.id,
        userId: item.userId,
        name: item.name,
        category: item.category.name,
        photoUrl: item.photoUrl,
        purchaseDate: item.purchaseDate,
        expiryDate: item.expiryDate,
        notes: item.notes,
        createdAt: item.createdAt,
      );

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'category': category,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (purchaseDate != null)
          'purchaseDate': Timestamp.fromDate(purchaseDate!),
        if (expiryDate != null)
          'expiryDate': Timestamp.fromDate(expiryDate!),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Item toEntity() => Item(
        id: id,
        userId: userId,
        name: name,
        category: ItemCategory.fromString(category),
        photoUrl: photoUrl,
        purchaseDate: purchaseDate,
        expiryDate: expiryDate,
        notes: notes,
        createdAt: createdAt,
      );
}
