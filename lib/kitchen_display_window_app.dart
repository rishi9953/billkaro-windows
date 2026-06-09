import 'dart:io';

import 'package:billkaro/app/Widgets/windows_desktop_title_bar.dart';
import 'package:billkaro/app/modules/KitchenDisplay/kitchen_display_screen.dart';
import 'package:billkaro/app/modules/Theme/theme_controller.dart';
import 'package:billkaro/utils/kitchen_display_window_launcher.dart';
import 'package:billkaro/config/app_theme.dart';
import 'package:billkaro/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

/// Standalone app shell for the Kitchen Display secondary window.
class KitchenDisplayWindowApp extends StatelessWidget {
  const KitchenDisplayWindowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasTheme = Get.isRegistered<ThemeController>();
    final themeController = hasTheme ? Get.find<ThemeController>() : null;

    if (themeController != null) {
      return Obx(() {
        final primary = themeController.themeColor.value;
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Kitchen Display',
          theme: AppTheme.lightThemeWithPrimary(primary),
          darkTheme: AppTheme.darkThemeWithPrimary(primary),
          themeMode: themeController.themeMode.value,
          locale: const Locale('en'),
          fallbackLocale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', ''), Locale('hi', '')],
          home: const _KitchenDisplayWindowShell(),
        );
      });
    }

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kitchen Display',
      theme: AppTheme.appTheme,
      locale: const Locale('en'),
      fallbackLocale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('hi', '')],
      home: const _KitchenDisplayWindowShell(),
    );
  }
}

class _KitchenDisplayWindowShell extends StatefulWidget {
  const _KitchenDisplayWindowShell();

  @override
  State<_KitchenDisplayWindowShell> createState() =>
      _KitchenDisplayWindowShellState();
}

class _KitchenDisplayWindowShellState extends State<_KitchenDisplayWindowShell> {
  @override
  void dispose() {
    if (!kIsWeb && Platform.isWindows) {
      KitchenDisplayWindowLauncher.releaseLock();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (!kIsWeb && Platform.isWindows)
            WindowsDesktopTitleBar(
              title: 'Billkaro — Kitchen Display',
              confirmOnClose: false,
              onBeforeClose: KitchenDisplayWindowLauncher.releaseLock,
            ),
          const Expanded(child: KitchenDisplayScreen()),
        ],
      ),
    );
  }
}
