import 'package:billkaro/app/modules/OrderPrefrences/KOT_Mode_bottomsheet.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/config/config.dart';

class OrderPreferencesController extends BaseController {
  var kotModeEnabled = false.obs;
  var paymentModesEnabled = true.obs;
  var isListView = false.obs;

  late AppPref appPref;

  @override
  void onInit() {
    super.onInit();
    appPref = AppPref(Get.find());

    // Load saved KOT mode
    kotModeEnabled.value = appPref.isKOT;

    // Load saved billing view preference
    isListView.value = appPref.isListView;

    // Load saved payment mode (if storing later)
    // paymentModesEnabled.value = appPref.paymentModes;
  }

  void toggleKotMode(bool value) {
    kotModeEnabled.value = value;
    appPref.isKOT = value; // ⬅ save to SharedPreferences

    // Push change into other live controllers so UI updates everywhere immediately.
    if (Get.isRegistered<HomeScreenController>()) {
      Get.find<HomeScreenController>().isKOT.value = value;
    }
    if (Get.isRegistered<AddOrderController>()) {
      Get.find<AddOrderController>().isKOT.value = value;
    }
  }

  void togglePaymentModes(bool value) {
    paymentModesEnabled.value = value;
    // If you want to store this also, add to AppPref
  }

  void selectBillingView(bool isListViewValue) {
    isListView.value = isListViewValue;
    appPref.isListView = isListViewValue; // Save to SharedPreferences

    // Push change into AddOrderController so UI updates immediately
    if (Get.isRegistered<AddOrderController>()) {
      Get.find<AddOrderController>().isListView.value = isListViewValue;
    }
  }

  /// Call when user pops (back) so Add Order screen updates without manual refresh.
  void syncPreferencesToAddOrderOnPop() {
    if (Get.isRegistered<AddOrderController>()) {
      final addOrder = Get.find<AddOrderController>();
      addOrder.isListView.value = appPref.isListView;
      addOrder.isKOT.value = appPref.isKOT;
      addOrder.isListView.refresh();
      addOrder.isKOT.refresh();
    }
  }

  void showKotModeBottomSheet() {
    Get.bottomSheet(
      const KotModeBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
    );
  }
}
