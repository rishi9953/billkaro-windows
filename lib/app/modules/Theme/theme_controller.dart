import 'package:billkaro/config/config.dart';

class ThemeController extends BaseController {
  static const String _themeKey = 'app_theme_mode';
  static const String _themeColorKey = 'app_theme_color';
  static const String _themeCustomColorsKey = 'app_theme_custom_colors';
  static const int _maxCustomThemeColors = 24;

  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;
  final Rx<Color> themeColor = const Color(0xFF083C6B).obs;

  /// Saved non-preset colors (ARGB ints), newest first. Shown in the theme picker.
  final RxList<int> customThemeColors = <int>[].obs;

  static const List<MapEntry<String, Color>> colorOptions = [
    MapEntry('Billkaro Blue', Color(0xFF083C6B)),
    MapEntry('Slate', Color(0xFF0F172A)),
    MapEntry('Orange', Color(0xFFFF6B35)),
    MapEntry('Blue', Color(0xFF2196F3)),
    MapEntry('Green', Color(0xFF4CAF50)),
    MapEntry('Purple', Color(0xFF9C27B0)),
    MapEntry('Red', Color(0xFFF44336)),
    MapEntry('Teal', Color(0xFF009688)),
    MapEntry('Indigo', Color(0xFF3F51B5)),
    MapEntry('Pink', Color(0xFFE91E63)),
    MapEntry('Brown', Color(0xFF795548)),
    MapEntry('Cyan', Color(0xFF00BCD4)),
  ];

  @override
  void onInit() {
    super.onInit();
    _loadSavedTheme();
    _loadCustomThemeColors();
    _loadSavedThemeColor();
  }

  Future<void> _loadSavedTheme() async {
    final prefs = Get.find<SharedPreferences>();
    final stored = prefs.getString(_themeKey) ?? 'light';
    switch (stored) {
      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;
      case 'system':
        themeMode.value = ThemeMode.system;
        break;
      case 'light':
      default:
        themeMode.value = ThemeMode.light;
        break;
    }
  }

  Future<void> _persistTheme(ThemeMode mode) async {
    final prefs = Get.find<SharedPreferences>();
    String value;
    switch (mode) {
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
      case ThemeMode.light:
        value = 'light';
        break;
    }
    await prefs.setString(_themeKey, value);
  }

  Future<void> _loadCustomThemeColors() async {
    final prefs = Get.find<SharedPreferences>();
    final raw = prefs.getStringList(_themeCustomColorsKey);
    if (raw == null || raw.isEmpty) return;
    final parsed = <int>[];
    for (final s in raw) {
      try {
        final v = int.parse(s);
        if (!_isBuiltInPreset(v & 0xFFFFFFFF)) {
          parsed.add(v);
        }
      } catch (_) {}
    }
    customThemeColors.assignAll(parsed);
  }

  Future<void> _persistCustomThemeColors() async {
    final prefs = Get.find<SharedPreferences>();
    await prefs.setStringList(
      _themeCustomColorsKey,
      customThemeColors.map((v) => v.toString()).toList(),
    );
  }

  bool _isBuiltInPreset(int argbNorm) {
    for (final e in colorOptions) {
      if ((e.value.value & 0xFFFFFFFF) == argbNorm) return true;
    }
    return false;
  }

  /// Adds [color] to the picker list if it is not a built-in preset. Newest first; duplicates move to top.
  Future<void> registerCustomThemeColor(Color color) async {
    final norm = color.value & 0xFFFFFFFF;
    if (_isBuiltInPreset(norm)) return;

    final idx = customThemeColors.indexWhere((e) => (e & 0xFFFFFFFF) == norm);
    if (idx >= 0) {
      customThemeColors.removeAt(idx);
    }
    customThemeColors.insert(0, color.value);
    while (customThemeColors.length > _maxCustomThemeColors) {
      customThemeColors.removeLast();
    }
    await _persistCustomThemeColors();
  }

  Future<void> _loadSavedThemeColor() async {
    final prefs = Get.find<SharedPreferences>();
    final stored = prefs.getInt(_themeColorKey);
    if (stored != null) {
      // SharedPreferences stores signed 32-bit ints on Android.
      // Normalize back to unsigned ARGB before creating Color.
      themeColor.value = Color(stored & 0xFFFFFFFF);
    }
    AppColor.updatePrimary(themeColor.value);
  }

  Future<void> setThemeColor(Color color) async {
    themeColor.value = color;
    AppColor.updatePrimary(color);
    final prefs = Get.find<SharedPreferences>();
    await prefs.setInt(_themeColorKey, color.value & 0xFFFFFFFF);
    Get.forceAppUpdate();
  }

  /// Default primary used after full logout (`clearAllData`).
  static Color get defaultThemeColor => colorOptions.first.value;

  Future<void> resetThemeColorToDefault() async {
    await setThemeColor(defaultThemeColor);
  }

  /// After full logout; safe if [ThemeController] is not registered yet.
  static Future<void> resetAfterLogout() async {
    if (!Get.isRegistered<ThemeController>()) return;
    await Get.find<ThemeController>().resetThemeColorToDefault();
  }

  /// Parses `#RGB`, `#RRGGBB`, or `#AARRGGBB` (also without `#`). Returns null if invalid.
  static Color? tryParseThemeHex(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 3) {
      final chars = s.split('');
      s = chars.map((c) => '$c$c').join();
    }
    if (s.length != 6 && s.length != 8) return null;
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(s)) return null;
    int value;
    try {
      value = s.length == 6
          ? int.parse('FF$s', radix: 16)
          : int.parse(s, radix: 16);
    } on FormatException {
      return null;
    }
    return Color(value & 0xFFFFFFFF);
  }

  static String hexRgbString(Color color) {
    return '#${color.red.toRadixString(16).padLeft(2, '0')}'
            '${color.green.toRadixString(16).padLeft(2, '0')}'
            '${color.blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  Future<bool> setThemeColorFromHex(String input) async {
    final parsed = tryParseThemeHex(input);
    if (parsed == null) return false;
    await registerCustomThemeColor(parsed);
    await setThemeColor(parsed);
    return true;
  }

  String get selectedThemeColorName {
    final selected = themeColor.value.value & 0xFFFFFFFF;
    for (final option in colorOptions) {
      if ((option.value.value & 0xFFFFFFFF) == selected) {
        return option.key;
      }
    }
    return hexRgbString(themeColor.value);
  }

  Future<void> toggleTheme() async {
    final current = themeMode.value;
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    themeMode.value = next;
    await _persistTheme(next);
    Get.forceAppUpdate();
  }

  Future<void> setSystemTheme() async {
    themeMode.value = ThemeMode.system;
    await _persistTheme(ThemeMode.system);
    Get.forceAppUpdate();
  }
}
