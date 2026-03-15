import 'package:billkaro/config/config.dart';

class ThemeController extends BaseController {
  static const String _themeKey = 'app_theme_mode';

  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedTheme();
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

  Future<void> toggleTheme() async {
    final current = themeMode.value;
    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    themeMode.value = next;
    await _persistTheme(next);
    Get.changeThemeMode(next);
  }

  Future<void> setSystemTheme() async {
    themeMode.value = ThemeMode.system;
    await _persistTheme(ThemeMode.system);
    Get.changeThemeMode(ThemeMode.system);
  }
}

