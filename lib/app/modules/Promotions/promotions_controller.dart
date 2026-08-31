import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/Modals/promotions/promotion_response.dart';
import 'package:billkaro/app/services/sync/promotion_sync.dart';
import 'package:billkaro/app/utils/promotion_engine.dart';
import 'package:billkaro/app/utils/promotion_types.dart';
import 'package:billkaro/config/config.dart';

class PromotionsController extends BaseController {
  final promotions = <PromotionData>[].obs;
  final menuItems = <ItemData>[].obs;
  final isSaving = false.obs;
  final isLoadingItems = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPromotions();
    loadMenuItems();
  }

  Future<void> loadMenuItems() async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;

    isLoadingItems.value = true;
    try {
      final loaded = await _fetchAllMenuItems(outletId);
      menuItems.assignAll(loaded);
    } catch (e, st) {
      debugPrint('Failed to load menu items for promotions: $e\n$st');
    } finally {
      isLoadingItems.value = false;
    }
  }

  Future<List<ItemData>> _fetchAllMenuItems(String outletId) async {
    final db = AppDatabase();
    final isOnline = await NetworkUtils.hasInternetConnection();

    if (isOnline) {
      const pageSize = 100;
      final fetched = <ItemData>[];
      var page = 1;
      var hasMore = true;

      while (hasMore) {
        final response = await callApi(
          apiClient.getItems(
            outletId,
            page,
            pageSize,
            null,
            null,
            null,
            null,
          ),
          showLoader: false,
        );

        if (response?.status != 'success') break;

        final batch = response!.data;
        if (batch.isEmpty) break;

        for (final item in batch) {
          if (!fetched.any((existing) => existing.id == item.id)) {
            fetched.add(item);
          }
        }

        final pagination = response.pagination;
        if (pagination?.hasNextPage != null) {
          hasMore = pagination!.hasNextPage!;
        } else {
          hasMore = batch.length >= pageSize;
        }
        page++;
      }

      if (fetched.isNotEmpty) {
        await db.saveItems(fetched, outletId);
        return fetched;
      }
    }

    return db.getItems(outletId: outletId);
  }

  Future<void> loadPromotions() async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;

    try {
      final rules = await PromotionSync(apiClient: apiClient).load(
        outletId: outletId,
        activeOnly: false,
      );
      promotions.assignAll(rules);
      if (Get.isRegistered<AddOrderController>()) {
        await Get.find<AddOrderController>().reloadPromotions();
      }
    } catch (e) {
      showError(description: 'Failed to load offers');
    }
  }

  Future<void> savePromotion({
    PromotionData? existing,
    required String type,
    required String name,
    required bool active,
    double minOrderAmount = 0,
    int buyQuantity = 1,
    int getQuantity = 1,
    double flatAmount = 0,
    double percent = 0,
    String? categoryName,
    String? productItemId,
    String? startTime,
    String? endTime,
    List<PromotionFreeItem> freeItems = const [],
    bool sameAsTrigger = false,
  }) async {
    final outletId = appPref.selectedOutlet?.id;
    final userId = appPref.ordersApiUserId;
    if (outletId == null || userId == null) return;

    if (name.trim().isEmpty) {
      showError(description: 'Enter an offer name.');
      return;
    }

    final validationError = _validateOffer(
      type: type,
      minOrderAmount: minOrderAmount,
      buyQuantity: buyQuantity,
      flatAmount: flatAmount,
      percent: percent,
      categoryName: categoryName,
      productItemId: productItemId,
      startTime: startTime,
      endTime: endTime,
      freeItems: freeItems,
      sameAsTrigger: sameAsTrigger,
    );
    if (validationError != null) {
      showError(description: validationError);
      return;
    }

    final resolvedType = _resolveSaveType(type, categoryName);
    final conditions = <String, dynamic>{
      'amountBasis': 'subtotal',
      if (minOrderAmount > 0) 'minOrderAmount': minOrderAmount,
      if (buyQuantity > 0 && _needsBuyQuantity(type)) 'buyQuantity': buyQuantity,
      if (categoryName != null && categoryName.trim().isNotEmpty)
        'categoryName': categoryName.trim(),
      if (productItemId != null && productItemId.trim().isNotEmpty)
        'itemId': productItemId.trim(),
      if (startTime != null && startTime.trim().isNotEmpty)
        'startTime': startTime.trim(),
      if (endTime != null && endTime.trim().isNotEmpty)
        'endTime': endTime.trim(),
    };

    final rewards = <String, dynamic>{
      'deductStock': true,
      if (getQuantity > 0 && PromotionTypes.isFreeItemType(type))
        'getQuantity': getQuantity,
      if (flatAmount > 0) 'flatAmount': flatAmount,
      if (percent > 0) 'percent': percent,
      if (sameAsTrigger) 'sameAsTrigger': true,
      if (freeItems.isNotEmpty)
        'freeItems': freeItems.map((e) => e.toJson()).toList(),
      if (PromotionTypes.isFreeItemType(type)) 'rewardKind': 'free_item',
      if (PromotionTypes.isDiscountType(type) && flatAmount > 0)
        'rewardKind': 'flat_off',
      if (PromotionTypes.isDiscountType(type) && percent > 0 && flatAmount <= 0)
        'rewardKind': 'percent_off',
      if (PromotionTypes.isFreeItemType(type) && freeItems.length > 1)
        'choiceMode': 'pick_one',
    };

    isSaving.value = true;
    try {
      final body = {
        'userId': userId,
        'name': name.trim(),
        'type': resolvedType,
        'active': active,
        'conditions': conditions,
        'rewards': rewards,
      };

      if (existing == null) {
        await callApi(apiClient.createPromotion(outletId, body));
      } else {
        await callApi(apiClient.updatePromotion(outletId, existing.id, body));
      }

      await loadPromotions();
      Get.back();
      showSuccess(
        description: existing == null ? 'Offer created' : 'Offer updated',
      );
    } catch (e) {
      showError(description: 'Could not save offer');
    } finally {
      isSaving.value = false;
    }
  }

  String _resolveSaveType(String type, String? categoryName) {
    if (type == PromotionTypes.spendThresholdFreeItem) {
      final category = categoryName?.trim();
      if (category != null && category.isNotEmpty) {
        return PromotionTypes.categorySpendThresholdFreeItem;
      }
    }
    return type;
  }

  bool _needsBuyQuantity(String type) {
    return type == PromotionTypes.buyXGetY ||
        type == PromotionTypes.buyXPercentOff ||
        type == PromotionTypes.productSpecific;
  }

  String? _validateOffer({
    required String type,
    required double minOrderAmount,
    required int buyQuantity,
    required double flatAmount,
    required double percent,
    String? categoryName,
    String? productItemId,
    String? startTime,
    String? endTime,
    required List<PromotionFreeItem> freeItems,
    required bool sameAsTrigger,
  }) {
    switch (type) {
      case PromotionTypes.buyXGetY:
        if (buyQuantity < 1) return 'Buy quantity must be at least 1.';
        if (productItemId == null || productItemId.trim().isEmpty) {
          return 'Select the product for this offer.';
        }
        if (!sameAsTrigger && freeItems.isEmpty) {
          return 'Select at least one free item choice.';
        }
        return null;
      case PromotionTypes.amountThresholdDiscount:
        if (minOrderAmount <= 0) return 'Enter a minimum order amount.';
        if (flatAmount <= 0) return 'Enter the discount amount.';
        return null;
      case PromotionTypes.percentageThreshold:
        if (minOrderAmount <= 0) return 'Enter a minimum order amount.';
        if (percent <= 0) return 'Enter the discount percentage.';
        return null;
      case PromotionTypes.flatDiscount:
        if (flatAmount <= 0) return 'Enter the flat discount amount.';
        return null;
      case PromotionTypes.buyXPercentOff:
        if (buyQuantity < 1) return 'Buy quantity must be at least 1.';
        if (percent <= 0) return 'Enter the discount percentage.';
        return null;
      case PromotionTypes.productSpecific:
        if (buyQuantity < 1) return 'Buy quantity must be at least 1.';
        if (productItemId == null || productItemId.trim().isEmpty) {
          return 'Select a product for this offer.';
        }
        if (flatAmount <= 0) return 'Enter the discount amount.';
        return null;
      case PromotionTypes.categoryPercent:
        if (categoryName == null || categoryName.trim().isEmpty) {
          return 'Select a category.';
        }
        if (percent <= 0) return 'Enter the discount percentage.';
        return null;
      case PromotionTypes.timeBased:
        if (startTime == null ||
            startTime.trim().isEmpty ||
            endTime == null ||
            endTime.trim().isEmpty) {
          return 'Enter start and end time (HH:MM).';
        }
        if (flatAmount <= 0 && percent <= 0) {
          return 'Enter a flat amount or percentage discount.';
        }
        return null;
      case PromotionTypes.spendThresholdFreeItem:
        if (minOrderAmount <= 0) return 'Enter a minimum order amount.';
        if (freeItems.isEmpty) return 'Select at least one free item.';
        return null;
      default:
        return 'Unsupported offer type.';
    }
  }

  Future<void> deletePromotion(PromotionData promotion) async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete offer?'),
        content: Text('Remove "${promotion.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await callApi(apiClient.deletePromotion(outletId, promotion.id));
    await loadPromotions();
    showSuccess(description: 'Offer deleted');
  }

  Future<void> toggleActive(PromotionData promotion) async {
    final outletId = appPref.selectedOutlet?.id;
    final userId = appPref.ordersApiUserId;
    if (outletId == null || userId == null) return;

    await callApi(
      apiClient.updatePromotion(outletId, promotion.id, {
        'userId': userId,
        'active': !promotion.active,
      }),
    );
    await loadPromotions();
  }

  List<String> get availableCategories {
    final names = menuItems
        .map((item) => item.category.trim())
        .where((name) => name.isNotEmpty && name.toLowerCase() != 'none')
        .toSet()
        .toList();
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  String offerSummary(PromotionData promotion) {
    return PromotionEngine.summary(promotion);
  }

  String freeItemsLabel(PromotionData promotion) {
    if (promotion.rewards.freeItems.isEmpty) return 'No items';
    return promotion.rewards.freeItems
        .map((entry) {
          final item = menuItems.firstWhereOrNull((i) => i.id == entry.itemId);
          return entry.displayLabel(item?.itemName ?? entry.itemId);
        })
        .join(', ');
  }
}
