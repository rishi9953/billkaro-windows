import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/Home/showcase_controller.dart';
import 'package:billkaro/app/modules/OrderPrefrences/order_prefrences_controller.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/helpers/cash_drawer_helper.dart';
import 'package:billkaro/app/services/sync/sync_manager.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/download_path_util.dart';
import 'package:billkaro/utils/po_print_orientation.dart';
import 'package:file_selector/file_selector.dart';

class AppSettingsController extends BaseController {
  late final RxBool isListView;
  late final RxBool notificationsEnabled;
  late final RxBool showQrOnBill;
  late final RxBool _showAddDetailsOnCreateOrder;
  RxBool get showAddDetailsOnCreateOrder => _showAddDetailsOnCreateOrder;
  late final RxBool kotModeEnabled;
  late final RxBool autoSyncEnabled;
  late final RxBool cashDrawerEnabled;
  late final RxBool openCashDrawerOnCashPayment;
  late final RxString cashDrawerPin;
  late final RxString downloadPath;
  late final Rx<PoPrintOrientation> poPrintOrientation;

  @override
  void onInit() {
    super.onInit();
    isListView = appPref.isListView.obs;
    notificationsEnabled = appPref.notificationsEnabled.obs;
    showQrOnBill = appPref.showQrOnBill.obs;
    _showAddDetailsOnCreateOrder = appPref.showAddDetailsOnCreateOrder.obs;
    kotModeEnabled = appPref.isKOT.obs;
    autoSyncEnabled = appPref.autoSyncEnabled.obs;
    cashDrawerEnabled = appPref.cashDrawerEnabled.obs;
    openCashDrawerOnCashPayment = appPref.openCashDrawerOnCashPayment.obs;
    cashDrawerPin = appPref.cashDrawerPin.obs;
    downloadPath = appPref.downloadPath.obs;
    poPrintOrientation = appPref.poPrintOrientation.obs;
    _ensureDefaultDownloadPath();
  }

  Future<void> _ensureDefaultDownloadPath() async {
    if (downloadPath.value.trim().isNotEmpty) return;
    try {
      final defaultPath = await DownloadPathUtil.resolveSaveDirectory();
      appPref.downloadPath = defaultPath;
      downloadPath.value = defaultPath;
    } catch (_) {}
  }

  void setListView(bool value) {
    appPref.isListView = value;
    isListView.value = value;
  }

  void setNotificationsEnabled(bool value) {
    appPref.notificationsEnabled = value;
    notificationsEnabled.value = value;
  }

  void setShowQrOnBill(bool value) {
    appPref.showQrOnBill = value;
    showQrOnBill.value = value;
  }

  void setShowAddDetailsOnCreateOrder(bool value) {
    appPref.showAddDetailsOnCreateOrder = value;
    _showAddDetailsOnCreateOrder.value = value;
    if (Get.isRegistered<AddOrderController>()) {
      Get.find<AddOrderController>().showAddDetailsOnCreateOrder.value = value;
    }
  }

  void setKotMode(bool value) {
    appPref.isKOT = value;
    kotModeEnabled.value = value;

    if (Get.isRegistered<HomeScreenController>()) {
      Get.find<HomeScreenController>().isKOT.value = value;
    }
    if (Get.isRegistered<AddOrderController>()) {
      Get.find<AddOrderController>().isKOT.value = value;
    }
    if (Get.isRegistered<OrderPreferencesController>()) {
      Get.find<OrderPreferencesController>().kotModeEnabled.value = value;
    }
  }

  Future<void> setAutoSyncEnabled(bool value) async {
    appPref.autoSyncEnabled = value;
    autoSyncEnabled.value = value;

    if (value) {
      await SyncManager().enableAutoSync();
      await SyncManager().triggerSync(immediate: true, fromReconnect: false);
    } else {
      SyncManager().disableAutoSync();
    }
  }

  void setCashDrawerEnabled(bool value) {
    appPref.cashDrawerEnabled = value;
    cashDrawerEnabled.value = value;
  }

  void setOpenCashDrawerOnCashPayment(bool value) {
    appPref.openCashDrawerOnCashPayment = value;
    openCashDrawerOnCashPayment.value = value;
  }

  void setCashDrawerPin(CashDrawerPin pin) {
    final key = cashDrawerPinStorageKey(pin);
    appPref.cashDrawerPin = key;
    cashDrawerPin.value = key;
  }

  void setPoPrintOrientation(PoPrintOrientation value) {
    appPref.poPrintOrientation = value;
    poPrintOrientation.value = value;
  }

  void resetOnboarding() {
    if (Get.isRegistered<ShowcaseController>()) {
      Get.find<ShowcaseController>().resetShowcaseForReplay();
    } else {
      appPref.isShowcaseCompleted = false;
    }
  }

  Future<void> pickDownloadPath() async {
    try {
      final loc = AppLocalizations.of(Get.context!)!;
      final selectedPath = await getDirectoryPath(
        confirmButtonText: loc.select_folder,
        initialDirectory: downloadPath.value.isNotEmpty
            ? downloadPath.value
            : null,
      );
      if (selectedPath == null || selectedPath.trim().isEmpty) return;

      appPref.downloadPath = selectedPath;
      downloadPath.value = selectedPath;
      showSuccess(description: loc.download_path_updated);
    } catch (e) {
      final loc = AppLocalizations.of(Get.context!)!;
      showError(description: loc.unable_to_update_download_path);
    }
  }

}
