import 'package:billkaro/config/config.dart';

/// App-wide color constants and helpers
abstract class AppColor {
  static const white = Color(0xFFFFFFFF);
  static const white12 = Color(0x1FFFFFFF);
  static const black = Color(0xFF000000);
  static const black12 = Colors.black12;
  static const black87 = Colors.black87;
  static const transparent = Color(0x00000000);

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);
  static const info = Color(0xFF0EA5E9);
  static const purple = Color(0xFF7C3AED);
  static const teal = Color(0xFF0D9488);

  static Color primary = const Color(0xFF0F172A);
  static const secondaryPrimary = Color(0xffef8819);
  static const lightgreen = Color(0xFF00BF6F);
  static const backGroundColor = Color(0xFFE8EEF7);
  static const cardSurface = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFD9E2EF);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const grey = Colors.grey;

  static const List<Color> chartPalette = [
    Color(0xFF0F172A),
    Color(0xFFEF8819),
    Color(0xFF16A34A),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFFE11D48),
    Color(0xFF0EA5E9),
    Color(0xFFC45C26),
  ];

  static void updatePrimary(Color color) {
    primary = color;
  }
}
