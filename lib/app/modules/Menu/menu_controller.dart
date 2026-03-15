import 'dart:async';

import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/config/config.dart';
import 'package:url_launcher/url_launcher.dart';

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

    // Navigate to main screen (or wherever you want after manual logout)
    Get.offAllNamed(AppRoute.main);
  }

  void onSupportTap() {
    var loc = AppLocalizations.of(Get.context!)!;
    // Handle support action
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Gap(20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  loc.get_support,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Gap(20),

              ListTile(
                leading: Icon(Icons.call_outlined),
                title: Text(loc.call),
                onTap: () {
                  // Handle email support action
                  makePhoneCall('+919350413656');
                },
              ),
              ListTile(
                leading: Icon(Icons.message_outlined),
                title: Text('${loc.email} (support@billkro.com)'),
                onTap: () {
                  // Handle live chat action
                  sendEmailWithSubject(
                    'support@billkaro.com',
                    loc.support_request,
                  );
                },
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(double.infinity, 48),
                ),
                onPressed: () {},
                child: Text(loc.cancel, style: TextStyle(color: Colors.black)),
              ),
              Gap(20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  Future<void> sendEmailWithSubject(String email, String subject) async {
    final String encodedSubject = Uri.encodeComponent(subject);
    final Uri launchUri = Uri.parse('mailto:$email?subject=$encodedSubject');
    await launchUrl(launchUri);
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
