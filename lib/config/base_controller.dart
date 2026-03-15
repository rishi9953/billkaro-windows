import 'dart:async';
import 'package:billkaro/config/config.dart';

class BaseController extends GetxController with WidgetsBindingObserver {
  late final AppPref appPref = Get.find<AppPref>();
  late final ApiClient apiClient = Get.find<ApiClient>();
  final streams = <StreamSubscription?>[];
  bool get isConnectedToNetwork => ConnectivityHelper.instance.isConnected;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final item in streams) {
      item?.cancel();
    }
    super.onClose();
  }

  void dismissLoadingDialog() {
    if (Get.isDialogOpen == true &&
        Get.rawRoute?.settings.name == 'progress_dialog_loading') {
      // Get.back(closeOverlays: true);
      Get.back();
    }
  }
}
