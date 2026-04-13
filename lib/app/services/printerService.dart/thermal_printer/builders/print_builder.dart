class PrintBuilder {
  final List<int> bytes = [];
  static const int paperWidth = 48;

  /// Receipt row width for monospace ESC/POS text.
  /// Common defaults:
  /// - 58mm (2"): ~32 chars
  /// - 80mm (3"): ~48 chars
  final int receiptWidth;
  final int _lineWidth;

  // ESC/POS Commands
  static const _ESC = 0x1B;
  static const _GS = 0x1D;
  static const _LF = 0x0A;

  PrintBuilder({int receiptWidth = 32})
    : receiptWidth = receiptWidth,
      _lineWidth = receiptWidth {
    bytes.addAll([_ESC, 0x40]); // Initialize printer
  }

  PrintBuilder text(String text) {
    bytes.addAll(text.codeUnits);
    return this;
  }

  PrintBuilder bold(String text) {
    bytes.addAll([_ESC, 0x45, 0x01]); // Bold on
    bytes.addAll(text.codeUnits);
    bytes.addAll([_ESC, 0x45, 0x00]); // Bold off
    return this;
  }

  PrintBuilder boldDoubleHeight(String text) {
    bytes.addAll([_ESC, 0x45, 0x01]); // Bold on
    bytes.addAll([_ESC, 0x21, 0x10]); // Double height
    bytes.addAll(text.codeUnits);
    bytes.addAll([_ESC, 0x21, 0x00]); // Normal size
    bytes.addAll([_ESC, 0x45, 0x00]); // Bold off
    return this;
  }

  PrintBuilder boldNormal(String text) {
    bytes.addAll([_ESC, 0x21, 0x00]); // Normal size
    if (text.isNotEmpty) bytes.addAll(text.codeUnits);
    return this;
  }

  PrintBuilder left() {
    bytes.addAll([_ESC, 0x61, 0x00]);
    return this;
  }

  PrintBuilder center() {
    bytes.addAll([_ESC, 0x61, 0x01]);
    return this;
  }

  PrintBuilder right() {
    bytes.addAll([_ESC, 0x61, 0x02]);
    return this;
  }

  PrintBuilder line() {
    bytes.addAll(('-' * _lineWidth).codeUnits);
    bytes.add(_LF);
    return this;
  }

  PrintBuilder feed(int lines) {
    for (int i = 0; i < lines; i++) bytes.add(_LF);
    return this;
  }

  PrintBuilder cut() {
    bytes.addAll([_GS, 0x56, 0x00]);
    return this;
  }
}
