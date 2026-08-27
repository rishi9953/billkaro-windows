import 'dart:async';

import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Theme/theme_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

class MenusController extends BaseController {
  var isSyncEnabled = false.obs;
  var busineesssName = ''.obs;
  var mobile = ''.obs;

  /// Ticks every second to refresh subscription time remaining.
  var subscriptionTick = 0.obs;
  Timer? _subscriptionTimer;

  void toggleSync(bool value) {
    isSyncEnabled.value = value;
    // Handle sync logic here
  }

  void onLogOut() async {
    final appPref = Get.find<AppPref>();

    // Clear user token first
    appPref.token = '';

    // Clear all database data
    final db = AppDatabase();
    await db.clearAllData();

    // Clear all SharedPreferences data
    await appPref.clearAllData();
    await ThemeController.resetAfterLogout();

    // Navigate to main screen (or wherever you want after manual logout)
    Get.offAllNamed(AppRoute.main);
  }

  void onSupportTap() {
    Modular.to.pushNamed(HomeMainRoutes.helpSetup);
  }

  @override
  void onInit() {
    getUserDetails();
    _subscriptionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      subscriptionTick.value++;
    });
    super.onInit();
  }

  @override
  void onClose() {
    _subscriptionTimer?.cancel();
    super.onClose();
  }

  void getUserDetails() {
    final user = appPref.user;
    final outlet = appPref.selectedOutlet;
    busineesssName.value = outlet!.businessName ?? '';
    mobile.value = outlet.phoneNumber ?? user!.mobile ?? '';
  }
}
