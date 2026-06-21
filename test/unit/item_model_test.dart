import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault/features/items/data/models/item_model.dart';
import 'package:home_vault/features/items/domain/entities/item.dart';

void main() {
  // Fixed timestamp to avoid DateTime.now() flakiness in tests
  final createdAt = DateTime(2026, 6, 21, 10, 0, 0);

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Item baseItem({
    String id = 'item-001',
    String userId = 'user-001',
    String name = 'Organic Oats',
    ItemCategory category = ItemCategory.food,
    String? photoUrl,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    String? notes,
  }) {
    return Item(
      id: id,
      userId: userId,
      name: name,
      category: category,
      photoUrl: photoUrl,
      purchaseDate: purchaseDate,
      expiryDate: expiryDate,
      notes: notes,
      createdAt: createdAt,
    );
  }

  // ---------------------------------------------------------------------------
  // fromEntity
  // ---------------------------------------------------------------------------

  group('ItemModel.fromEntity', () {
    test('maps all fields correctly', () {
      final expiryDate = DateTime(2027, 12, 31);
      final purchaseDate = DateTime(2026, 1, 15);
      final item = baseItem(
        photoUrl: 'https://example.com/photo.jpg',
        purchaseDate: purchaseDate,
        expiryDate: expiryDate,
        notes: 'Keep dry',
      );

      final model = ItemModel.fromEntity(item);

      expect(model.id, 'item-001');
      expect(model.userId, 'user-001');
      expect(model.name, 'Organic Oats');
      expect(model.category, ItemCategory.food.name);
      expect(model.photoUrl, 'https://example.com/photo.jpg');
      expect(model.purchaseDate, purchaseDate);
      expect(model.expiryDate, expiryDate);
      expect(model.notes, 'Keep dry');
      expect(model.createdAt, createdAt);
    });

    test('preserves null optional fields (purchaseDate, notes, photoUrl)', () {
      final item = baseItem();

      final model = ItemModel.fromEntity(item);

      expect(model.purchaseDate, isNull);
      expect(model.notes, isNull);
      expect(model.photoUrl, isNull);
    });

    test('maps every ItemCategory enum to its .name string', () {
      for (final category in ItemCategory.values) {
        final item = baseItem(category: category);
        final model = ItemModel.fromEntity(item);
        expect(model.category, category.name,
            reason: '$category should map to "${category.name}"');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // toEntity
  // ---------------------------------------------------------------------------

  group('ItemModel.toEntity', () {
    test('round-trip: fromEntity(item).toEntity() == item', () {
      final expiryDate = DateTime(2027, 6, 15);
      final purchaseDate = DateTime(2026, 1, 1);
      final item = baseItem(
        photoUrl: 'https://example.com/img.png',
        purchaseDate: purchaseDate,
        expiryDate: expiryDate,
        notes: 'Store in cool place',
      );

      final roundTripped = ItemModel.fromEntity(item).toEntity();

      expect(roundTripped.id, item.id);
      expect(roundTripped.userId, item.userId);
      expect(roundTripped.name, item.name);
      expect(roundTripped.category, item.category);
      expect(roundTripped.photoUrl, item.photoUrl);
      expect(roundTripped.purchaseDate, item.purchaseDate);
      expect(roundTripped.expiryDate, item.expiryDate);
      expect(roundTripped.notes, item.notes);
      expect(roundTripped.createdAt, item.createdAt);
    });

    test('maps category string back to correct enum', () {
      final item = baseItem(category: ItemCategory.electronics);
      final entity = ItemModel.fromEntity(item).toEntity();
      expect(entity.category, ItemCategory.electronics);
    });

    test('maps unknown category string to ItemCategory.other', () {
      final model = ItemModel(
        id: 'x',
        userId: 'u',
        name: 'Widget',
        category: 'nonexistent_category',
        photoUrl: null,
        purchaseDate: null,
        expiryDate: null,
        notes: null,
        createdAt: createdAt,
      );

      final entity = model.toEntity();
      expect(entity.category, ItemCategory.other);
    });
  });

  // ---------------------------------------------------------------------------
  // toFirestore
  // ---------------------------------------------------------------------------

  group('ItemModel.toFirestore', () {
    test('contains required keys: userId, name, category, createdAt, expiryDate',
        () {
      final expiryDate = DateTime(2028, 3, 10);
      final item = baseItem(expiryDate: expiryDate);
      final model = ItemModel.fromEntity(item);

      final map = model.toFirestore();

      expect(map.containsKey('userId'), isTrue);
      expect(map.containsKey('name'), isTrue);
      expect(map.containsKey('category'), isTrue);
      expect(map.containsKey('createdAt'), isTrue);
      expect(map.containsKey('expiryDate'), isTrue);
    });

    test('omits notes key when notes is null', () {
      final item = baseItem();
      final map = ItemModel.fromEntity(item).toFirestore();
      expect(map.containsKey('notes'), isFalse);
    });

    test('omits photoUrl key when photoUrl is null', () {
      final item = baseItem();
      final map = ItemModel.fromEntity(item).toFirestore();
      expect(map.containsKey('photoUrl'), isFalse);
    });

    test('expiryDate value is a Timestamp instance', () {
      final expiryDate = DateTime(2028, 6, 30);
      final item = baseItem(expiryDate: expiryDate);
      final map = ItemModel.fromEntity(item).toFirestore();

      expect(map['expiryDate'], isA<Timestamp>());
    });

    test('createdAt value is a Timestamp instance', () {
      final item = baseItem();
      final map = ItemModel.fromEntity(item).toFirestore();

      expect(map['createdAt'], isA<Timestamp>());
    });

    test('notes is included when not null', () {
      final item = baseItem(notes: 'Refrigerate after opening');
      final map = ItemModel.fromEntity(item).toFirestore();

      expect(map['notes'], 'Refrigerate after opening');
    });

    test('photoUrl is included when not null', () {
      final item =
          baseItem(photoUrl: 'https://storage.example.com/item.jpg');
      final map = ItemModel.fromEntity(item).toFirestore();

      expect(map['photoUrl'], 'https://storage.example.com/item.jpg');
    });
  });

  // ---------------------------------------------------------------------------
  // ItemCategory.fromString
  // ---------------------------------------------------------------------------

  group('ItemCategory.fromString', () {
    test('all valid category names return the correct enum value', () {
      for (final category in ItemCategory.values) {
        final result = ItemCategory.fromString(category.name);
        expect(result, category,
            reason:
                '"${category.name}" should return ItemCategory.${category.name}');
      }
    });

    test('unknown string returns ItemCategory.other', () {
      expect(ItemCategory.fromString('banana'), ItemCategory.other);
      expect(ItemCategory.fromString(''), ItemCategory.other);
      expect(ItemCategory.fromString('FOOD'), ItemCategory.other);
    });
  });

  // ---------------------------------------------------------------------------
  // ItemCategory display properties
  // ---------------------------------------------------------------------------

  group('ItemCategory display properties', () {
    test('all categories have non-empty displayName', () {
      for (final category in ItemCategory.values) {
        expect(category.displayName, isNotEmpty,
            reason: '$category.displayName must not be empty');
      }
    });

    test('all categories have a non-empty emoji', () {
      for (final category in ItemCategory.values) {
        expect(category.emoji, isNotEmpty,
            reason: '$category.emoji must not be empty');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Item entity computed properties
  // ---------------------------------------------------------------------------

  group('Item.isExpired', () {
    test('returns false for a future expiryDate', () {
      final item = baseItem(expiryDate: DateTime(2027, 1, 1));
      expect(item.isExpired, isFalse);
    });

    test('returns true for a past expiryDate', () {
      final item = baseItem(expiryDate: DateTime(2024, 1, 1));
      expect(item.isExpired, isTrue);
    });
  });

  group('Item.daysUntilExpiry', () {
    test('returns null when no expiryDate set', () {
      final item = baseItem();
      expect(item.daysUntilExpiry, isNull);
    });

    test('returns a positive int for a future expiryDate', () {
      final item = baseItem(expiryDate: DateTime(2027, 6, 21));
      expect(item.daysUntilExpiry, isNotNull);
      expect(item.daysUntilExpiry, greaterThan(0));
    });
  });
}
