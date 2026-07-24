import 'package:json_annotation/json_annotation.dart';
import 'combo_component.dart';

part 'item_response.g.dart';

@JsonSerializable()
class ItemResponse {
  final String status;
  final List<ItemData> data;
  final PaginationMeta? pagination;

  ItemResponse({required this.status, required this.data, this.pagination});

  factory ItemResponse.fromJson(Map<String, dynamic> json) =>
      _$ItemResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ItemResponseToJson(this);
}

@JsonSerializable()
class PaginationMeta {
  final int? currentPage;
  final int? totalPages;
  final int? totalItems;
  final int? itemsPerPage;
  final bool? hasNextPage;
  final bool? hasPreviousPage;

  PaginationMeta({
    this.currentPage,
    this.totalPages,
    this.totalItems,
    this.itemsPerPage,
    this.hasNextPage,
    this.hasPreviousPage,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationMetaToJson(this);
}

@JsonSerializable()
class ItemData {
  final String id; // UUID
  final String userId;
  final String outletId;
  final String itemName;
  final double salePrice;
  final bool withTax;
  final int gst;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String itemImage;
  final String? orderFrom; // optional field
  @JsonKey(defaultValue: '')
  final String barcode;
  @JsonKey(defaultValue: '')
  final String sku;
  @JsonKey(defaultValue: 'Each')
  final String soldBy;
  @JsonKey(defaultValue: 0)
  final double costPrice;
  @JsonKey(defaultValue: '')
  final String posColor;
  @JsonKey(defaultValue: false)
  final bool trackStock;
  @JsonKey(defaultValue: 0)
  final double stockQuantity;
  @JsonKey(defaultValue: 0)
  final double minStock;
  @JsonKey(defaultValue: true)
  final bool showItem;
  @JsonKey(defaultValue: false)
  final bool isRecommended;
  @JsonKey(defaultValue: 15)
  final int prepTimeMinutes;
  @JsonKey(defaultValue: false)
  final bool isCombo;
  @JsonKey(defaultValue: [])
  final List<ComboComponent> comboComponents;

  ItemData({
    required this.id,
    required this.userId,
    required this.itemName,
    required this.salePrice,
    required this.withTax,
    required this.gst,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    required this.outletId,
    this.orderFrom,
    this.itemImage = '',
    this.barcode = '',
    this.sku = '',
    this.soldBy = 'Each',
    this.costPrice = 0,
    this.posColor = '',
    this.trackStock = false,
    this.stockQuantity = 0,
    this.minStock = 0,
    this.showItem = true,
    this.isRecommended = false,
    this.prepTimeMinutes = 15,
    this.isCombo = false,
    this.comboComponents = const [],
  });

  factory ItemData.fromJson(Map<String, dynamic> json) =>
      _$ItemDataFromJson(json);

  Map<String, dynamic> toJson() => _$ItemDataToJson(this);
}
