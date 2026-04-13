import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/notification/sync_notification_service.dart';
import 'package:billkaro/app/services/permissionService.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/app/services/PrinterService2/printer_service2.dart';
import 'package:billkaro/config/config.dart';

class HomeMainController extends BaseController {
  // Add your controller logic here

  final Rx<OutletData?> selectedOutlet = Rx<OutletData?>(null);

  Future<void> getUserDetails() async {
    final response = await callApi(
      apiClient.getUserDetails(appPref.user!.id!),
      showLoader: false,
    );

    if (response?.status == 'success') {
      appPref.user = response!.data;

      // 🔁 Re-sync selected outlet from updated outlet list
      final currentSelectedId = appPref.selectedOutlet?.id;

      if (currentSelectedId != null) {
        final updatedOutlet = appPref.allOutlets.firstWhereOrNull(
          (o) => o.id == currentSelectedId,
        );

        if (updatedOutlet != null) {
          appPref.selectedOutlet = updatedOutlet;
          selectedOutlet.value = updatedOutlet;
        } else if (appPref.allOutlets.isNotEmpty) {
          // fallback if outlet was removed
          appPref.selectFirstOutlet();
          selectedOutlet.value = appPref.selectedOutlet;
        }
      } else if (appPref.allOutlets.isNotEmpty) {
        // No outlet selected yet
        appPref.selectFirstOutlet();
        selectedOutlet.value = appPref.selectedOutlet;
      }

      update(); // refresh UI
    }
  }

  @override
  void onReady() async {
    await getUserDetails();
    // Defer notification permission to next frame (avoids Android 16 crash when enabling)
    // SchedulerBinding.instance.addPostFrameCallback((_) {
    //   _requestNotificationPermissionAfterLogin();
    // });
    // Initialize Bluetooth/Printer only AFTER login (prevents startup permission popup)
    await _initPrinterServiceAfterLogin();
    super.onReady();
  }

  Future<void> _initPrinterServiceAfterLogin() async {
    try {
      if (Get.isRegistered<PrinterService2>()) {
        await PrinterService2.to.init();
      } else {
        // Fallback: register then init
        Get.put(PrinterService2(), permanent: true);
        await PrinterService2.to.init();
      }
      // BLE/USB thermal printer: auto-connect was skipped at cold start when logged out
      if (Get.isRegistered<ThermalPrinterService>()) {
        final thermal = ThermalPrinterService.instance;
        if (await thermal.isAutoConnectEnabled()) {
          await thermal.tryAutoConnect();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [PRINTER] PrinterService2 init skipped/failed: $e');
    }
  }

  /// Ask notification permission after user has logged in (Home Page)
  /// (Android 13+ requires POST_NOTIFICATIONS runtime permission)
  /// Deferred and with delayed init to avoid Android 16 crash when user enables permission.
  Future<void> _requestNotificationPermissionAfterLogin() async {
    try {
      debugPrint(
        '🔔 [PERMISSIONS] Requesting notification permission after login...',
      );
      final granted = await PermissionService.requestNotification();
      debugPrint(
        granted
            ? '✅ [PERMISSIONS] Notification permission granted'
            : '⚠️ [PERMISSIONS] Notification permission denied',
      );

      // Defer notification service init to avoid Android 16 crash: run after
      // permission result has been fully processed (activity/lifecycle stable).
      await Future.delayed(const Duration(milliseconds: 500));
      if (granted) {
        await SyncNotificationService().initialize();
      }
    } catch (e, stack) {
      debugPrint(
        '❌ [PERMISSIONS] Error requesting notification permission: $e',
      );
      debugPrint('$stack');
    }
  }
}
