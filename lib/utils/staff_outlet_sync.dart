import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/Network/api_client.dart';
import 'package:billkaro/config/app_pref.dart';
import 'package:get/get.dart';

/// Applies a staff login/profile to [appPref] without loading owner outlets.
///
/// Staff may only access the outlet(s) returned by staff auth/profile APIs.
/// Do not call the owner `users/{id}` endpoint here — that returns every outlet
/// on the business account, not only where this staff member was added.
class StaffOutletSync {
  StaffOutletSync._();

  static Future<User> enrichAppPrefFromOwner({
    required AppPref appPref,
    required User staffUser,
    ApiClient? apiClient,
  }) async {
    if (staffUser.role != 'staff') {
      appPref.user = staffUser;
      return staffUser;
    }

    final staffOutlets = staffUser.outletData ?? [];
    if (staffOutlets.isEmpty) {
      appPref.user = staffUser;
      return staffUser;
    }

    final currentOutletId =
        appPref.selectedOutlet?.id ?? staffOutlets.firstOrNull?.id;
    final selectedOutlet = currentOutletId == null
        ? staffOutlets.first
        : staffOutlets.firstWhereOrNull((o) => o.id == currentOutletId) ??
            staffOutlets.first;

    appPref.selectedOutlet = selectedOutlet;
    appPref.user = staffUser;
    return staffUser;
  }
}
