import 'package:billkaro/app/modules/HomeMain/home_main_module.dart';
import 'package:billkaro/app/modules/Language/language_controller.dart';
import 'package:billkaro/app/modules/Theme/theme_controller.dart';
import 'package:billkaro/config/app_theme.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';

class HomeMainScreen extends StatelessWidget {
  const HomeMainScreen({super.key});

  static final HomeMainModule _homeMainModule = HomeMainModule();

  @override
  Widget build(BuildContext context) {
    final themeController = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : null;
    final languageController = Get.isRegistered<LanguageController>()
        ? Get.find<LanguageController>()
        : null;

    final selectedPrimary =
        themeController?.themeColor.value ?? AppColor.primary;

    return ModularApp(
      module: _homeMainModule,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'BillKaro',
        routerConfig: Modular.routerConfig,
        theme: AppTheme.lightThemeWithPrimary(selectedPrimary),
        darkTheme: AppTheme.darkThemeWithPrimary(selectedPrimary),
        themeMode: themeController?.themeMode.value ?? ThemeMode.light,
        locale: languageController?.appLocale.value ?? const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', ''), Locale('hi', '')],
      ),
    );
  }
}
