import 'dart:io';

import 'package:billkaro/app/Database/app_database.dart' as dbs;
import 'package:billkaro/app/modules/Language/language_controller.dart';
import 'package:billkaro/app/modules/Theme/theme_controller.dart';
import 'package:billkaro/app/services/Network/network_module.dart';
import 'package:billkaro/app/services/PrinterService2/printer_service2.dart';
import 'package:billkaro/app/services/Synchronisatioin/synchronisation.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/app/services/sync/sync_manager.dart';
import 'package:billkaro/config/app_binding.dart';
import 'package:billkaro/config/app_theme.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/app_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  // Setup log filtering to reduce noise from harmless warnings
  // LogFilter.setupLogFiltering(); // Uncomment if you want to filter logs

  // Wrap everything in error handling to prevent crashes (release + debug)
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
    debugPrint('❌ [FLUTTER ERROR] ${details.exception}');
    debugPrint('❌ [STACK TRACE] ${details.stack}');
  };

  // Handle async errors so app doesn't crash on unhandled async exceptions
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('❌ [PLATFORM ERROR] $error');
    debugPrint('❌ [STACK TRACE] $stack');
    return true; // mark as handled to prevent exit
  };

  try {
    HttpOverrides.global = MyHttpOverrides();
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('⚠️ [INIT] Failed to load .env file: $e');
      // Continue without .env file - keys will use defaults
    }

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    Get.put<SharedPreferences>(prefs, permanent: true);

    // Initialize AppInfo
    try {
      await AppInfoUtil.init();
    } catch (e) {
      debugPrint('⚠️ [INIT] AppInfoUtil.init failed: $e');
    }

    // Initialize Language Controller
    try {
      Get.put(LanguageController(), permanent: true);
    } catch (e) {
      debugPrint('⚠️ [INIT] LanguageController failed: $e');
    }

    // Initialize Theme Controller
    try {
      Get.put(ThemeController(), permanent: true);
    } catch (e) {
      debugPrint('⚠️ [INIT] ThemeController failed: $e');
    }

    // Initialize Thermal Printer Service
    try {
      Get.put(ThermalPrinterService(), permanent: true);
    } catch (e) {
      debugPrint('⚠️ [INIT] ThermalPrinterService failed: $e');
    }

    // Initialize Database (only once)
    try {
      if (!Get.isRegistered<dbs.AppDatabase>()) {
        Get.put<dbs.AppDatabase>(dbs.AppDatabase(), permanent: true);
      }
    } catch (e) {
      debugPrint('⚠️ [INIT] AppDatabase failed: $e');
    }

    // Initialize WorkManager (use kDebugMode so release behaves correctly)
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
    } catch (e) {
      debugPrint('⚠️ [INIT] Workmanager initialization failed: $e');
    }

    // Initialize Dependencies - must complete before runApp (avoids release crash)
    try {
      await initDependencies();
    } catch (e) {
      debugPrint('⚠️ [INIT] initDependencies failed: $e');
    }

    // Register PrinterService2 WITHOUT initializing Bluetooth at app launch.
    // (Bluetooth init triggers "Nearby devices" permission on Android 12+)
    try {
      if (!Get.isRegistered<PrinterService2>()) {
        Get.put(PrinterService2(), permanent: true);
      }
    } catch (e) {
      debugPrint('⚠️ [INIT] PrinterService2 registration failed: $e');
      // Continue without printer service
    }

    // Initialize Sync Manager for automatic synchronization
    try {
      await SyncManager().initialize();
    } catch (e) {
      debugPrint('⚠️ [INIT] SyncManager failed: $e');
      // Continue without sync manager
    }

    // Run the app
    runApp(const MyApp());
  } catch (e, stack) {
    debugPrint('❌ [MAIN] Critical error during initialization: $e');
    debugPrint('❌ [STACK] $stack');

    // Show error screen or fallback
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App initialization failed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please restart the app',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Try to restart
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      // Safely get LanguageController, with fallback
      Locale appLocale = const Locale('en');

      try {
        final hasLanguage = Get.isRegistered<LanguageController>();
        final hasTheme = Get.isRegistered<ThemeController>();

        if (hasLanguage && hasTheme) {
          final languageController = Get.find<LanguageController>();
          final themeController = Get.find<ThemeController>();

          return Obx(() {
            return GetMaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'BillKaro',
              initialRoute: AppRoute.initial,
              getPages: AppRoute.pages,
              theme: AppTheme.appTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeController.themeMode.value,
              initialBinding: AppBinding(),
              locale: languageController.appLocale.value,
              fallbackLocale: const Locale('en'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en', ''), Locale('hi', '')],
            );
          });
        }
      } catch (e) {
        debugPrint('⚠️ [MYAPP] Language/Theme controller error: $e');
      }

      // Fallback without reactive locale/theme
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BillKaro',
        initialRoute: AppRoute.initial,
        getPages: AppRoute.pages,
        theme: AppTheme.appTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        initialBinding: AppBinding(),
        locale: appLocale,
        fallbackLocale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', ''), Locale('hi', '')],
      );
    } catch (e, stack) {
      debugPrint('❌ [MYAPP] Critical error in build: $e');
      debugPrint('❌ [STACK] $stack');

      // Return a minimal error app
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App Error',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please restart the app',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

Future<void> initDependencies() async {
  debugPrint('Initating....');
  final prefInstance = await SharedPreferences.getInstance();
  Get
    ..lazyPut(() => AppPref(prefInstance), fenix: true)
    ..lazyPut(NetworkModule.prepareDio, fenix: true)
    ..lazyPut(NetworkModule.getApiClient, fenix: true);
  debugPrint('Initialized....');
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    final apiClient = NetworkModule.getApiClient();

    // 🔹 Database (background isolate instance)
    final db = dbs.AppDatabase();
    final syncService = Synchronisation(apiClient: apiClient);

    try {
      switch (task) {
        case 'syncOrdersTask':
        case SyncManager.periodicSyncTask:
        case SyncManager.connectivitySyncTask:
        case SyncManager.immediateSyncTask:
          debugPrint('🔄 [WORKMANAGER] Executing sync task: $task');
          // Show notification in background sync
          await syncService.syncPendingOrders(db, showNotification: true);
          debugPrint('✅ [WORKMANAGER] Sync task completed: $task');
          break;
        default:
          debugPrint('⚠️ [WORKMANAGER] Unknown task: $task');
      }
    } catch (e, stack) {
      debugPrint('❌ [WORKMANAGER] Error executing task $task: $e');
      debugPrint(stack.toString());
      return Future.value(false);
    }

    return Future.value(true);
  });
}
