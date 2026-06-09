class TextHelper {
  static String padRight(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    return text.padRight(width);
  }

  static String padLeft(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    return text.padLeft(width);
  }

  static String formatRow(String left, String right, int width) {
    int availableSpace = width - left.length - right.length;
    if (availableSpace < 0) {
      return left.substring(0, width ~/ 2) + right.substring(0, width ~/ 2);
    }
    return left + ' ' * availableSpace + right;
  }

  /// Matches [ThermalKOTReceipt]: name left, qty right on one row.
  static List<String> kotNameQtyLines(
    String itemName,
    int quantity,
    int receiptWidth,
  ) {
    final qty = 'x$quantity';
    final firstLineNameMax = receiptWidth - qty.length;
    if (firstLineNameMax < 1) {
      return [formatRow(itemName, qty, receiptWidth)];
    }
    if (itemName.length <= firstLineNameMax) {
      return [formatRow(itemName, qty, receiptWidth)];
    }

    final lines = <String>[
      formatRow(itemName.substring(0, firstLineNameMax), qty, receiptWidth),
    ];
    var pos = firstLineNameMax;
    while (pos < itemName.length) {
      final end = (pos + receiptWidth).clamp(0, itemName.length);
      lines.add(itemName.substring(pos, end));
      pos = end;
    }
    return lines;
  }

  static String kotCategoryRemarkLine({String? category, String? remark}) {
    final cat = category?.trim() ?? '';
    final rem = remark?.trim() ?? '';
    return [
      if (cat.isNotEmpty) '($cat)',
      if (rem.isNotEmpty) '* $rem',
    ].join(' ');
  }

  /// Category and/or remark on lines below the item (indented).
  static List<String> kotSublineLines({
    required String? category,
    required String? remark,
    required int receiptWidth,
    String indent = '  ',
  }) {
    final lines = <String>[];
    final cat = category?.trim() ?? '';
    final rem = remark?.trim() ?? '';
    if (cat.isNotEmpty) {
      lines.addAll(_wrapIndented('($cat)', receiptWidth, indent));
    }
    if (rem.isNotEmpty) {
      lines.addAll(_wrapIndented('* $rem', receiptWidth, indent));
    }
    return lines;
  }

  static List<String> _wrapIndented(
    String text,
    int receiptWidth,
    String indent,
  ) {
    final lines = <String>[];
    var pos = 0;
    var first = true;
    while (pos < text.length) {
      final budget = first ? receiptWidth - indent.length : receiptWidth;
      if (budget < 1) break;
      final end = (pos + budget).clamp(0, text.length);
      lines.add(first ? '$indent${text.substring(pos, end)}' : text.substring(pos, end));
      pos = end;
      first = false;
    }
    return lines;
  }
}
