import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/Home/showcase_controller.dart';
import 'package:billkaro/app/modules/OrderPrefrences/order_prefrences_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/download_path_util.dart';
import 'package:file_selector/file_selector.dart';

class AppSettingsController extends BaseController {
  late final RxBool isListView;
  late final RxBool notificationsEnabled;
  late final RxBool showQrOnBill;
  late final RxBool _showAddDetailsOnCreateOrder;
  RxBool get showAddDetailsOnCreateOrder => _showAddDetailsOnCreateOrder;
  late final RxBool kotModeEnabled;
  late final RxString downloadPath;

  @override
  void onInit() {
    super.onInit();
    isListView = appPref.isListView.obs;
    notificationsEnabled = appPref.notificationsEnabled.obs;
    showQrOnBill = appPref.showQrOnBill.obs;
    _showAddDetailsOnCreateOrder = appPref.showAddDetailsOnCreateOrder.obs;
    kotModeEnabled = appPref.isKOT.obs;
    downloadPath = appPref.downloadPath.obs;
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

  void resetOnboarding() {
    if (Get.isRegistered<ShowcaseController>()) {
      Get.find<ShowcaseController>().resetShowcaseForReplay();
    } else {
      appPref.isShowcaseCompleted = false;
    }
  }

  Future<void> pickDownloadPath() async {
    try {
      final selectedPath = await getDirectoryPath(
        confirmButtonText: 'Select folder',
        initialDirectory: downloadPath.value.isNotEmpty
            ? downloadPath.value
            : null,
      );
      if (selectedPath == null || selectedPath.trim().isEmpty) return;

      appPref.downloadPath = selectedPath;
      downloadPath.value = selectedPath;
      showSuccess(description: 'Download path updated');
    } catch (e) {
      showError(description: 'Unable to update download path');
    }
  }

}
