class TableDisplay {
  TableDisplay._();

  /// Strips a leading "Table " prefix so localized labels don't duplicate it.
  static String numberForLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.toLowerCase().startsWith('table ')) {
      return trimmed.substring(6).trim();
    }
    return trimmed;
  }
}
