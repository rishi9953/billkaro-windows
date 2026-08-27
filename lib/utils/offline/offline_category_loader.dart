import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/app/services/Modals/Categories/categories_response.dart';
import 'package:billkaro/utils/connectivity/connectivity_helper.dart';
import 'package:flutter/foundation.dart';

/// Loads categories from API when online (and caches to SQLite),
/// otherwise falls back to SQLite or derives from cached menu items.
class OfflineCategoryLoader {
  const OfflineCategoryLoader._();

  static Future<List<CategoryData>> load({
    required String outletId,
    required Future<CategoryResponse?> Function() fetchFromApi,
  }) async {
    final db = AppDatabase();
    final isOnline = await NetworkUtils.hasInternetConnection();

    if (isOnline) {
      try {
        final response = await fetchFromApi();
        if (response != null && response.status == 'success') {
          final categories = response.categories;
          await db.saveCategories(categories, outletId: outletId);
          debugPrint(
            '📂 Cached ${categories.length} categories for outlet $outletId',
          );
          return categories;
        }
      } catch (e, st) {
        debugPrint('⚠️ Category API fetch failed, using cache: $e\n$st');
      }
    }

    final cached = await db.getCategories(outletId: outletId);
    if (cached.isNotEmpty) {
      debugPrint('📴 Loaded ${cached.length} categories from SQLite');
      return cached;
    }

    final derived = await _deriveFromItems(outletId);
    if (derived.isNotEmpty) {
      debugPrint('📴 Derived ${derived.length} categories from cached items');
    }
    return derived;
  }

  static Future<List<CategoryData>> _deriveFromItems(String outletId) async {
    final page = await AppDatabase().getItemsPage(
      outletId: outletId,
      limit: 300,
    );
    final names = <String>{};
    final now = DateTime.now();
    final result = <CategoryData>[];

    for (final item in page.items) {
      final name = item.category.trim();
      if (name.isEmpty || name.toLowerCase() == 'none') continue;
      if (!names.add(name)) continue;

      result.add(
        CategoryData(
          id: 'local_cat_${name.hashCode.abs()}',
          userId: item.userId,
          outletId: outletId,
          categoryName: name,
          imageURL: '',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    result.sort((a, b) => a.categoryName.compareTo(b.categoryName));
    return result;
  }
}
