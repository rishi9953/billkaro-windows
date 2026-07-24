// ignore_for_file: unnecessary_library_name

library add_item_modal;

import 'package:json_annotation/json_annotation.dart';
import 'combo_component.dart';

part 'addItem_modal.g.dart';

@JsonSerializable(includeIfNull: false)
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
  final String barcode;
  final String sku;
  final String soldBy;
  final double costPrice;
  final String posColor;
  final bool trackStock;
  final double stockQuantity;
  final double minStock;
  final bool showItem;
  @JsonKey(includeIfNull: false)
  final bool? isRecommended;
  final int prepTimeMinutes;
  final bool isCombo;
  final List<ComboComponent> comboComponents;

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
    this.barcode = '',
    this.sku = '',
    this.soldBy = 'Each',
    this.costPrice = 0,
    this.posColor = '',
    this.trackStock = false,
    this.stockQuantity = 0,
    this.minStock = 0,
    this.isRecommended,
    this.prepTimeMinutes = 15,
    this.isCombo = false,
    this.comboComponents = const [],
  });

  factory ItemRequest.fromJson(Map<String, dynamic> json) =>
      _$ItemRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ItemRequestToJson(this);
}
