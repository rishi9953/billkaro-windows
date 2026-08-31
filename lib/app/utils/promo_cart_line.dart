class PromoCartLine {
  const PromoCartLine._();

  static const prefix = 'promo::';

  static bool isPromo(String lineKey) => lineKey.startsWith(prefix);

  static String key({
    required String promotionId,
    required String itemId,
    String? variantId,
  }) {
    final base = '$prefix$promotionId::$itemId';
    if (variantId != null && variantId.isNotEmpty) {
      return '$base::$variantId';
    }
    return base;
  }

  static String? promotionId(String lineKey) {
    if (!isPromo(lineKey)) return null;
    final parts = lineKey.substring(prefix.length).split('::');
    return parts.isNotEmpty ? parts[0] : null;
  }

  static String itemId(String lineKey) {
    if (!isPromo(lineKey)) return lineKey;
    final parts = lineKey.substring(prefix.length).split('::');
    return parts.length >= 2 ? parts[1] : lineKey;
  }

  static String? variantId(String lineKey) {
    if (!isPromo(lineKey)) return null;
    final parts = lineKey.substring(prefix.length).split('::');
    return parts.length >= 3 ? parts[2] : null;
  }

  static String? findLineKey(
    Map<String, int> quantities,
    String promotionId,
  ) {
    for (final key in quantities.keys) {
      if (PromoCartLine.promotionId(key) == promotionId) return key;
    }
    return null;
  }
}
