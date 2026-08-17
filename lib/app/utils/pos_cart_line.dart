class PosCartLine {
  const PosCartLine({
    required this.itemId,
    this.variantId,
  });

  final String itemId;
  final String? variantId;

  String get key =>
      variantId == null || variantId!.isEmpty ? itemId : '$itemId::$variantId';

  static PosCartLine fromKey(String key) {
    const separator = '::';
    final index = key.indexOf(separator);
    if (index < 0) {
      return PosCartLine(itemId: key);
    }
    return PosCartLine(
      itemId: key.substring(0, index),
      variantId: key.substring(index + separator.length),
    );
  }

  static String displayName({
    required String itemName,
    String? variantName,
  }) {
    final variant = variantName?.trim();
    if (variant == null || variant.isEmpty) return itemName;
    return '$itemName - $variant';
  }

  static String invoiceLineName({
    required String itemName,
    String? variantName,
  }) {
    return displayName(itemName: itemName, variantName: variantName);
  }

  static String reportGroupKey({
    required String itemName,
    String? variantName,
    String? variantId,
  }) {
    final variant = variantName?.trim();
    if (variant != null && variant.isNotEmpty) {
      return '$itemName::$variant';
    }
    if (variantId != null && variantId.isNotEmpty) {
      return '$itemName::$variantId';
    }
    return itemName;
  }
}
