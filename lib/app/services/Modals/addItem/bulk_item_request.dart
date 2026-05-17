import 'package:json_annotation/json_annotation.dart';

part 'bulk_item_request.g.dart';

@JsonSerializable(explicitToJson: true)
class BulkItemRequest {
  final String userId;
  final String outletId;
  final List<BulkItemEntry> items;

  BulkItemRequest({
    required this.userId,
    required this.outletId,
    required this.items,
  });

  factory BulkItemRequest.fromJson(Map<String, dynamic> json) =>
      _$BulkItemRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BulkItemRequestToJson(this);
}

@JsonSerializable()
class BulkItemEntry {
  final String itemName;
  final double salePrice;
  final bool withTax;
  final String orderFrom;
  final String category;
  final double gst;
  final bool showItem;

  BulkItemEntry({
    required this.itemName,
    required this.salePrice,
    required this.withTax,
    required this.orderFrom,
    required this.category,
    required this.gst,
    required this.showItem,
  });

  factory BulkItemEntry.fromJson(Map<String, dynamic> json) =>
      _$BulkItemEntryFromJson(json);

  Map<String, dynamic> toJson() => _$BulkItemEntryToJson(this);
}
