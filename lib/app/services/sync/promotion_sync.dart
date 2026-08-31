import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/app/services/Modals/promotions/promotion_response.dart';
import 'package:billkaro/app/services/Network/api_client.dart';
import 'package:billkaro/utils/connectivity/connectivity_helper.dart';
import 'package:flutter/foundation.dart';

class PromotionSync {
  const PromotionSync({required this.apiClient, this.db});

  final ApiClient apiClient;
  final AppDatabase? db;

  Future<List<PromotionData>> load({
    required String outletId,
    bool activeOnly = true,
  }) async {
    final database = db ?? AppDatabase();
    final isOnline = await NetworkUtils.hasInternetConnection();

    if (isOnline) {
      try {
        final response = await apiClient.getPromotions(
          outletId,
          activeOnly ? 'true' : null,
        );
        if (response.status == 'success') {
          await database.savePromotions(response.data, outletId: outletId);
          debugPrint(
            '🎁 Cached ${response.data.length} promotion(s) for $outletId',
          );
          return activeOnly
              ? response.data.where((rule) => rule.active).toList()
              : response.data;
        }
      } catch (e, st) {
        debugPrint('⚠️ Promotion API fetch failed, using cache: $e\n$st');
      }
    }

    final cached = await database.getPromotions(
      outletId: outletId,
      activeOnly: activeOnly,
    );
    debugPrint('📴 Loaded ${cached.length} promotion(s) from SQLite');
    return cached;
  }
}
