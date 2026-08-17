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

  /// Dots per QR module (solid black/white squares). Larger = clearer scan.
  int get qrModuleDots {
    switch (this) {
      case ThermalPaperSize.mm58:
        return 7;
      case ThermalPaperSize.mm80:
        return 9;
      case ThermalPaperSize.mm104:
        return 11;
    }
  }

  /// Max QR bitmap width so the code fits the printable area with side margin.
  /// Kept within typical ESC/POS buffer limits while staying large enough to scan.
  int get qrMaxDots {
    switch (this) {
      case ThermalPaperSize.mm58:
        return 320; // 58mm ≈ 384 dots
      case ThermalPaperSize.mm80:
        return 448; // 80mm ≈ 576 dots
      case ThermalPaperSize.mm104:
        return 560; // 104mm ≈ 832 dots
    }
  }

  /// Target QR bitmap width in printer dots (snapped to whole modules later).
  int get qrBitmapSize => qrMaxDots;

  /// Native ESC/POS QR module size (1–16; capped at 8 for cheap clone printers).
  int get escPosQrModuleSize {
    switch (this) {
      case ThermalPaperSize.mm58:
        return 6;
      case ThermalPaperSize.mm80:
        return 8;
      case ThermalPaperSize.mm104:
        return 8;
    }
  }

  /// Effective printable PDF page width for Windows/driver printing.
  double get pdfPageWidthMm {
    switch (this) {
      case ThermalPaperSize.mm58:
        return 54;
      case ThermalPaperSize.mm80:
        return 76;
      case ThermalPaperSize.mm104:
        return 100;
    }
  }

  /// On-page QR display size for PDF receipts.
  double get pdfQrDisplayMm {
    switch (this) {
      case ThermalPaperSize.mm58:
        return 32;
      case ThermalPaperSize.mm80:
        return 42;
      case ThermalPaperSize.mm104:
        return 52;
    }
  }
}
