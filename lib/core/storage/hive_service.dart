import 'package:hive_flutter/hive_flutter.dart';

/// Local storage service backed by Hive.
/// Phase 3: register type adapters and open boxes for offline item cache
/// and user preferences.
class HiveService {
  HiveService._();

  static Future<void> init() async {
    await Hive.initFlutter();
    // Phase 3: uncomment and add adapters when offline cache is needed.
    // Hive.registerAdapter(ItemModelAdapter());
    // await Hive.openBox<ItemModel>('items_cache');
    // await Hive.openBox('preferences');
  }

  static Future<void> dispose() async {
    await Hive.close();
  }
}
