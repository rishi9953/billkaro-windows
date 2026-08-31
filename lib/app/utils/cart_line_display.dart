class CartLineDisplay {
  const CartLineDisplay({
    required this.lineKey,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.remark = '',
    this.imageUrl = '',
    this.isPromo = false,
    this.offerName,
    this.offerDetail,
    this.pendingKot = 0,
    this.comboIncludes,
  });

  final String lineKey;
  final String name;
  final double unitPrice;
  final int quantity;
  final String remark;
  final String imageUrl;
  final bool isPromo;
  final String? offerName;
  final String? offerDetail;
  final int pendingKot;
  final String? comboIncludes;

  double get lineTotal => unitPrice * quantity;

  bool get hasOfferInfo =>
      isPromo && ((offerName?.isNotEmpty ?? false) || (offerDetail?.isNotEmpty ?? false));
}
