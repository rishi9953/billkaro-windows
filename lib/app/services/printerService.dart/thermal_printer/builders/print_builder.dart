class PrintBuilder {
  final List<int> bytes = [];
  static const int paperWidth = 48;

  /// Receipt row width for 2" thermal (58mm ≈ 32 chars). Use for formatRow.
  static const int receiptWidth = 32;

  /// Width for separator line (same as receiptWidth so line doesn't wrap)
  static const int _lineWidth = 32;

  // ESC/POS Commands
  static const _ESC = 0x1B;
  static const _GS = 0x1D;
  static const _LF = 0x0A;

  PrintBuilder() {
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
