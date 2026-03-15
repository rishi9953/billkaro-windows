import 'package:billkaro/config/config.dart';

class LanguageController extends BaseController {
  Rx<Locale> appLocale = const Locale('en').obs;
  RxString selectedLanguage = 'English'.obs;
  RxList<String> languages = <String>['English', 'हिन्दी'].obs;

  static const String _languageKey = 'language_code';

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = Get.find<SharedPreferences>();
    final code = prefs.getString(_languageKey) ?? 'en';
    appLocale.value = Locale(code);
    selectedLanguage.value = code == 'hi' ? 'हिन्दी' : 'English';
  }

  Future<void> changeLanguage(Locale locale) async {
    final prefs = Get.find<SharedPreferences>();
    final code = locale.languageCode;
    await prefs.setString(_languageKey, code);
    appLocale.value = locale;
    selectedLanguage.value = code == 'hi' ? 'हिन्दी' : 'English';
    Get.updateLocale(locale); // ✅ updates instantly
  }
}
