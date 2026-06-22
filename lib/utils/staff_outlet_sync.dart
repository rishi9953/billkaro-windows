import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/Modals/user/user_response.dart';
import 'package:billkaro/app/services/Network/api_client.dart';
import 'package:billkaro/app/services/Network/api_handler.dart';
import 'package:billkaro/config/app_pref.dart';
import 'package:get/get.dart';

/// Keeps staff sessions using the owner's full outlet record (seating, etc.).
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

    final client = apiClient ?? Get.find<ApiClient>();
    final ownerId = staffUser.userId ?? appPref.ownerUserId;
    if (ownerId == null || ownerId.isEmpty) {
      appPref.user = staffUser;
      return staffUser;
    }

    final ownerRes = await callApi<UserResponse>(
      client.getUserDetails(ownerId),
      showLoader: false,
    );
    if (ownerRes?.status != 'success') {
      appPref.user = staffUser;
      return staffUser;
    }

    final ownerOutlets = ownerRes!.data.outletData ?? [];
    if (ownerOutlets.isEmpty) {
      appPref.user = staffUser;
      return staffUser;
    }

    final currentOutletId =
        appPref.selectedOutlet?.id ?? staffUser.outletData?.firstOrNull?.id;
    final fullOutlet = currentOutletId == null
        ? ownerOutlets.first
        : ownerOutlets.firstWhereOrNull((o) => o.id == currentOutletId) ??
            ownerOutlets.first;

    appPref.selectedOutlet = fullOutlet;

    final ownerUser = ownerRes.data;
    final merged = User(
      createdAt: staffUser.createdAt,
      updatedAt: staffUser.updatedAt,
      id: staffUser.id,
      brandName: staffUser.brandName,
      email: staffUser.email,
      address: ownerUser.address ?? staffUser.address,
      city: ownerUser.city ?? staffUser.city,
      state: ownerUser.state ?? staffUser.state,
      zipcode: ownerUser.zipcode ?? staffUser.zipcode,
      country: ownerUser.country ?? staffUser.country,
      firstName: staffUser.firstName,
      lastName: staffUser.lastName,
      title: ownerUser.title ?? staffUser.title,
      mobile: staffUser.mobile,
      isTrial: staffUser.isTrial,
      outletData: ownerOutlets,
      role: staffUser.role,
      staffRole: staffUser.staffRole,
      permissions: staffUser.permissions,
      userId: staffUser.userId ?? ownerUser.userId ?? ownerUser.id,
    );
    appPref.user = merged;
    return merged;
  }
}
