import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// Thermal roll widths supported in printer settings.
enum ThermalPaperSize {
  /// 2 inch (58 mm)
  mm58,

  /// 3 inch (80 mm)
  mm80,

  /// 4 inch (104 mm)
  mm104;

  static ThermalPaperSize fromStorageKey(String? key) {
    switch (key) {
      case '80':
        return ThermalPaperSize.mm80;
      case '104':
        return ThermalPaperSize.mm104;
      case '58':
      default:
        return ThermalPaperSize.mm58;
    }
  }
}

extension ThermalPaperSizeX on ThermalPaperSize {
  /// Monospace character width used by [PrintBuilder] and receipt layout.
  int get receiptWidthChars {
    switch (this) {
      case ThermalPaperSize.mm58:
        return 32;
      case ThermalPaperSize.mm80:
        return 48;
      case ThermalPaperSize.mm104:
        return 64;
    }
  }

  /// Closest ESC/POS paper profile (library has no 104 mm preset).
  PaperSize get escPosPaperSize {
    switch (this) {
      case ThermalPaperSize.mm58:
        return PaperSize.mm58;
      case ThermalPaperSize.mm80:
      case ThermalPaperSize.mm104:
        return PaperSize.mm80;
    }
  }

  String get storageKey {
    switch (this) {
      case ThermalPaperSize.mm58:
        return '58';
      case ThermalPaperSize.mm80:
        return '80';
      case ThermalPaperSize.mm104:
        return '104';
    }
  }

  ({int w, int item, int qty, int price, int amount}) invoiceColumns() {
    final w = receiptWidthChars;
    if (w >= 64) {
      return (w: w, item: 32, qty: 6, price: 10, amount: 16);
    }
    if (w >= 48) {
      return (w: w, item: 24, qty: 6, price: 8, amount: 10);
    }
    return (w: w, item: 12, qty: 4, price: 8, amount: 8);
  }
}
