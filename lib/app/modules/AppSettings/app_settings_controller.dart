import 'package:billkaro/config/config.dart';

class AppSettingsController extends BaseController {
  late final RxBool isListView;
  late final RxBool isShowcaseCompleted;
  late final RxBool notificationsEnabled;
  late final RxBool soundEnabled;
  late final RxBool hapticEnabled;
  late final RxBool showQrOnBill;

  @override
  void onInit() {
    super.onInit();
    isListView = appPref.isListView.obs;
    isShowcaseCompleted = appPref.isShowcaseCompleted.obs;
    notificationsEnabled = appPref.notificationsEnabled.obs;
    soundEnabled = appPref.soundEnabled.obs;
    hapticEnabled = appPref.hapticEnabled.obs;
    showQrOnBill = appPref.showQrOnBill.obs;
  }

  void setListView(bool value) {
    appPref.isListView = value;
    isListView.value = value;
  }

  void setShowcaseCompleted(bool value) {
    appPref.isShowcaseCompleted = value;
    isShowcaseCompleted.value = value;
  }

  void setNotificationsEnabled(bool value) {
    appPref.notificationsEnabled = value;
    notificationsEnabled.value = value;
  }

  void setSoundEnabled(bool value) {
    appPref.soundEnabled = value;
    soundEnabled.value = value;
  }

  void setHapticEnabled(bool value) {
    appPref.hapticEnabled = value;
    hapticEnabled.value = value;
  }

  void setShowQrOnBill(bool value) {
    appPref.showQrOnBill = value;
    showQrOnBill.value = value;
  }

  void resetOnboarding() {
    appPref.isShowcaseCompleted = false;
    isShowcaseCompleted.value = false;
  }
}
