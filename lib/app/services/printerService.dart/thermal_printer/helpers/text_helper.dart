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
}
