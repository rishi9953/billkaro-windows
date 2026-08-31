enum PromotionApplyKind { pickFreeItem, autoFreeLine, discount }

class PromotionApplyResult {
  const PromotionApplyResult({
    required this.promotionId,
    required this.promotionName,
    required this.kind,
    this.discountAmount = 0,
    this.freeQuantity = 1,
    this.sameAsTrigger = false,
  });

  final String promotionId;
  final String promotionName;
  final PromotionApplyKind kind;
  final double discountAmount;
  final int freeQuantity;
  final bool sameAsTrigger;

  bool get needsPicker => kind == PromotionApplyKind.pickFreeItem;
}

class PromotionCartContext {
  const PromotionCartContext({
    required this.itemQuantities,
    required this.linePrice,
    required this.lineCategory,
    required this.lineItemId,
    required this.lineVariantId,
    required this.subtotal,
    required this.totalTax,
    required this.now,
  });

  final Map<String, int> itemQuantities;
  final double Function(String lineKey) linePrice;
  final String? Function(String lineKey) lineCategory;
  final String? Function(String lineKey) lineItemId;
  final String? Function(String lineKey) lineVariantId;
  final double subtotal;
  final double totalTax;
  final DateTime now;
}
