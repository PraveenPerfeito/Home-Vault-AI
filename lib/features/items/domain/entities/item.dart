import 'package:equatable/equatable.dart';

enum ItemCategory {
  food,
  medicine,
  cosmetics,
  babyProducts,
  electronics,
  household,
  other;

  String get displayName => switch (this) {
        ItemCategory.food => 'Food',
        ItemCategory.medicine => 'Medicine',
        ItemCategory.cosmetics => 'Cosmetics',
        ItemCategory.babyProducts => 'Baby Products',
        ItemCategory.electronics => 'Electronics',
        ItemCategory.household => 'Household',
        ItemCategory.other => 'Other',
      };

  // Icon codepoints chosen to avoid depending on a third-party icon package.
  String get emoji => switch (this) {
        ItemCategory.food => '🍎',
        ItemCategory.medicine => '💊',
        ItemCategory.cosmetics => '💄',
        ItemCategory.babyProducts => '🍼',
        ItemCategory.electronics => '📱',
        ItemCategory.household => '🏠',
        ItemCategory.other => '📦',
      };

  static ItemCategory fromString(String value) => ItemCategory.values
      .firstWhere((e) => e.name == value, orElse: () => ItemCategory.other);
}

class Item extends Equatable {
  final String id;
  final String userId;
  final String name;
  final ItemCategory category;
  final String? photoUrl;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final String? notes;
  final DateTime createdAt;

  const Item({
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

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  Item copyWith({
    String? id,
    String? userId,
    String? name,
    ItemCategory? category,
    String? photoUrl,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? notes,
    DateTime? createdAt,
  }) =>
      Item(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        category: category ?? this.category,
        photoUrl: photoUrl ?? this.photoUrl,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        expiryDate: expiryDate ?? this.expiryDate,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props =>
      [id, userId, name, category, photoUrl, purchaseDate, expiryDate, notes, createdAt];
}
