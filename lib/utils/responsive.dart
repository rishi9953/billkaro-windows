import 'package:flutter/material.dart';

class Responsive {
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  static int columns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 6;
    if (w >= 900) return 5;
    if (w >= 700) return 4;
    if (w >= 500) return 3;
    return 2;
  }

  static double titleSize(BuildContext context) {
    return isTablet(context) ? 18 : 14;
  }

  static double amountSize(BuildContext context) {
    return isTablet(context) ? 16 : 13;
  }
}
