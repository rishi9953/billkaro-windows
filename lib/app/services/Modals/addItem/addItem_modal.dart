import 'package:json_annotation/json_annotation.dart';

part 'addItem_modal.g.dart';

@JsonSerializable()
class ItemRequest {
  final String itemName;
  final double salePrice;
  final bool withTax;
  final String orderFrom;
  final double gst;
  final String userId;
  final String outletId;
  final String category;
  final String itemImage;
  final bool showItem;

  ItemRequest({
    required this.itemName,
    required this.salePrice,
    required this.withTax,
    required this.gst,
    required this.orderFrom,
    required this.userId,
    required this.category,
    required this.outletId,
    required this.showItem,
    this.itemImage = '',
  });

  factory ItemRequest.fromJson(Map<String, dynamic> json) =>
      _$ItemRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ItemRequestToJson(this);
}
