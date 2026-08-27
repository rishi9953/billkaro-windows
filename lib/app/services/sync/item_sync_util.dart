import 'package:billkaro/app/services/Modals/addItem/addItem_modal.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/Modals/addItem/menu_item_variant.dart';

bool isLocalItemId(String? id) {
  if (id == null || id.isEmpty) return false;
  return id.startsWith('temp_') || id.startsWith('local_');
}

String newLocalItemId() =>
    'local_item_${DateTime.now().microsecondsSinceEpoch}';

class PendingCatalogItem {
  const PendingCatalogItem({
    required this.item,
    required this.isDeleted,
  });

  final ItemData item;
  final bool isDeleted;
}

class ItemSyncResult {
  const ItemSyncResult({
    this.synced = 0,
    this.failed = 0,
    this.pending = 0,
  });

  final int synced;
  final int failed;
  final int pending;

  bool get hasPendingWork => pending > 0;
}

ItemRequest itemRequestFromItem(ItemData item) {
  return ItemRequest(
    itemName: item.itemName,
    salePrice: item.salePrice,
    withTax: item.withTax,
    gst: item.gst.toDouble(),
    orderFrom: item.orderFrom ?? 'None',
    userId: item.userId,
    outletId: item.outletId,
    category: item.category,
    showItem: item.showItem,
    itemImage: item.itemImage,
    barcode: item.barcode,
    sku: item.sku,
    soldBy: item.soldBy,
    costPrice: item.costPrice,
    posColor: item.posColor,
    trackStock: item.trackStock,
    stockQuantity: item.stockQuantity,
    minStock: item.minStock,
    isRecommended: item.isRecommended,
    prepTimeMinutes: item.prepTimeMinutes,
    isCombo: item.isCombo,
    comboComponents: item.comboComponents,
    linkedRecipeItemId: item.linkedRecipeItemId,
    hasVariants: item.hasVariants,
    variants: item.variants
        .map(
          (variant) => MenuItemVariantInput(
            id: isLocalItemId(variant.id) ? null : variant.id,
            name: variant.name,
            sku: variant.sku,
            barcode: variant.barcode ?? '',
            salePrice: variant.salePrice,
            costPrice: variant.costPrice,
            trackStock: variant.trackStock,
            stockQuantity: variant.stockQuantity,
            minStock: variant.minStock,
            isDefault: variant.isDefault,
            isActive: variant.isActive,
            sortOrder: variant.sortOrder,
          ),
        )
        .toList(),
  );
}

ItemData itemDataFromRequest({
  required ItemRequest request,
  required String id,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now();
  final variants = request.variants
      .map(
        (variant) => MenuItemVariant(
          id: variant.id ?? '${id}_${variant.sortOrder}',
          itemId: id,
          outletId: request.outletId,
          userId: request.userId,
          name: variant.name,
          sku: variant.sku,
          barcode: variant.barcode,
          salePrice: variant.salePrice,
          costPrice: variant.costPrice,
          trackStock: variant.trackStock,
          stockQuantity: variant.stockQuantity,
          minStock: variant.minStock,
          isDefault: variant.isDefault,
          isActive: variant.isActive,
          sortOrder: variant.sortOrder,
          createdAt: now,
          updatedAt: now,
        ),
      )
      .toList();

  return ItemData(
    id: id,
    userId: request.userId,
    outletId: request.outletId,
    itemName: request.itemName,
    salePrice: request.salePrice,
    withTax: request.withTax,
    gst: request.gst.round(),
    category: request.category,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
    itemImage: request.itemImage,
    orderFrom: request.orderFrom,
    barcode: request.barcode,
    sku: request.sku,
    soldBy: request.soldBy,
    costPrice: request.costPrice,
    posColor: request.posColor,
    trackStock: request.trackStock,
    stockQuantity: request.stockQuantity,
    minStock: request.minStock,
    showItem: request.showItem,
    isRecommended: request.isRecommended ?? false,
    prepTimeMinutes: request.prepTimeMinutes,
    isCombo: request.isCombo,
    comboComponents: request.comboComponents,
    linkedRecipeItemId: request.linkedRecipeItemId,
    hasVariants: request.hasVariants ?? variants.isNotEmpty,
    variants: variants,
  );
}

ItemData? parseItemFromResponse(dynamic response, ItemData fallback) {
  if (response is! Map) return null;
  if (response['status']?.toString() != 'success') return null;

  final data = response['data'];
  if (data is Map) {
    try {
      final map = Map<String, dynamic>.from(data);
      map['id'] ??= fallback.id;
      map['outletId'] ??= fallback.outletId;
      map['userId'] ??= fallback.userId;
      return ItemData.fromJson(map);
    } catch (_) {}
  }

  return fallback;
}
