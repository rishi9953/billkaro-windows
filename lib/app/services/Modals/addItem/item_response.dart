import 'package:json_annotation/json_annotation.dart';

part 'item_response.g.dart';

@JsonSerializable()
class ItemResponse {
  final String status;
  final List<ItemData> data;
  final PaginationMeta? pagination;

  ItemResponse({
    required this.status,
    required this.data,
    this.pagination,
  });

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
  @JsonKey(defaultValue: true)
  final bool showItem;

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
    this.showItem = true,
  });

  factory ItemData.fromJson(Map<String, dynamic> json) =>
      _$ItemDataFromJson(json);

  Map<String, dynamic> toJson() => _$ItemDataToJson(this);
}
