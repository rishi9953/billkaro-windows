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
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:billkaro/utils/app_info.dart';
import 'package:billkaro/utils/exit_confirm_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:workmanager/workmanager.dart';

bool _isKeyboardStateAssertion(Object error) {
  final message = error.toString();
  return message.contains('hardware_keyboard.dart') &&
      message.contains('_pressedKeys.containsKey(event.physicalKey)');
}

void _clearHardwareKeyboardStateSafely() {
  try {
    // `clearState` is testing-only in API docs, but works at runtime.
    (HardwareKeyboard.instance as dynamic).clearState();
  } catch (_) {
    // Best-effort only; ignore if Flutter internals change.
  }
}

void main() async {
  // Setup log filtering to reduce noise from harmless warnings
  // LogFilter.setupLogFiltering(); // Uncomment if you want to filter logs

  // Wrap everything in error handling to prevent crashes (release + debug)
  FlutterError.onError = (FlutterErrorDetails details) {
    if (_isKeyboardStateAssertion(details.exception)) {
      _clearHardwareKeyboardStateSafely();
      return;
    }

    if (kDebugMode) {
      FlutterError.presentError(details);
    }
    debugPrint('❌ [FLUTTER ERROR] ${details.exception}');
    debugPrint('❌ [STACK TRACE] ${details.stack}');
  };

  // Handle async errors so app doesn't crash on unhandled async exceptions
  PlatformDispatcher.instance.onError = (error, stack) {
    if (_isKeyboardStateAssertion(error)) {
      _clearHardwareKeyboardStateSafely();
      return true;
    }

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

    // Initialize Dependencies before services that read login state (e.g. printer auto-connect)
    try {
      await initDependencies();
    } catch (e) {
      debugPrint('⚠️ [INIT] initDependencies failed: $e');
    }

    // Initialize Thermal Printer Service (onInit may auto-connect only when logged in)
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

    // Initialize WorkManager (Android/iOS only; not implemented on Windows)
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: kDebugMode,
        );
      } catch (e) {
        debugPrint('⚠️ [INIT] Workmanager initialization failed: $e');
      }
    } else {
      debugPrint('ℹ️ [INIT] Skipping Workmanager init (unsupported platform)');
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
    runApp(const _MyAppRoot());
    if (!kIsWeb && Platform.isWindows) {
      doWhenWindowReady(() {
        const initialSize = Size(1280, 720);
        appWindow.minSize = const Size(1024, 640);
        appWindow.size = initialSize;
        appWindow.alignment = Alignment.center;
        appWindow.title = 'Billkaro ChillKaro';
        appWindow.show();
      });
    }
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

/// Workaround for a Flutter framework assertion on desktop:
/// if a native file dialog steals focus, a key-up (often Alt) can be missed,
/// leaving `HardwareKeyboard` thinking the key is still pressed.
class _MyAppRoot extends StatefulWidget {
  const _MyAppRoot();

  @override
  State<_MyAppRoot> createState() => _MyAppRootState();
}

class _MyAppRootState extends State<_MyAppRoot> with WidgetsBindingObserver {
  bool _postFrameKeyboardClearScheduled = false;

  void _clearHardwareKeyboardState() {
    try {
      // `clearState` is marked testing-only in Flutter; calling via `dynamic`
      // avoids analyzer warnings while still working at runtime.
      (HardwareKeyboard.instance as dynamic).clearState();
    } catch (_) {
      // If the API changes, just ignore; this is a best-effort workaround.
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _clearHardwareKeyboardState();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Never clear keyboard state from build() — that can trigger framework
    // assertions. Schedule a one-time post-frame callback instead.
    if (!_postFrameKeyboardClearScheduled) {
      _postFrameKeyboardClearScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _clearHardwareKeyboardState();
      });
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        if (await ExitConfirmHelper.shouldExitAfterPrompt(context)) {
          await SystemNavigator.pop();
        }
      },
      child: const MyApp(),
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
            final selectedPrimary = themeController.themeColor.value;
            return GetMaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'BillKaro',
              initialRoute: AppRoute.initial,
              getPages: AppRoute.pages,
              theme: AppTheme.lightThemeWithPrimary(selectedPrimary),
              darkTheme: AppTheme.darkThemeWithPrimary(selectedPrimary),
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
