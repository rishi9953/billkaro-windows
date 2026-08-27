import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/Modals/user/user_response.dart';
import 'package:billkaro/app/services/Network/api_client.dart';
import 'package:billkaro/app/services/Network/api_handler.dart';
import 'package:billkaro/config/app_pref.dart';
import 'package:get/get.dart';

/// Enriches the staff session with full outlet details from the owner,
/// but keeps only outlets the staff is assigned to.
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
      return _saveStaffUser(appPref, staffUser);
    }

    final ownerRes = await callApi<UserResponse>(
      client.getUserDetails(ownerId),
      showLoader: false,
    );
    if (ownerRes?.status != 'success') {
      return _saveStaffUser(appPref, staffUser);
    }

    final ownerUser = ownerRes!.data;
    final ownerOutlets = ownerUser.outletData ?? [];
    final staffOutlets = _staffOnlyOutlets(
      staffAssigned: staffUser.outletData ?? [],
      ownerOutlets: ownerOutlets,
    );

    if (staffOutlets.isEmpty) {
      return _saveStaffUser(appPref, staffUser);
    }

    appPref.selectedOutlet = _pickSelectedOutlet(
      preferredId: appPref.selectedOutlet?.id ??
          staffUser.outletData?.firstOrNull?.id,
      staffOutlets: staffOutlets,
    );

    final merged = User(
      createdAt: staffUser.createdAt,
      updatedAt: staffUser.updatedAt,
      id: staffUser.id,
      brandName: staffUser.brandName,
      email: staffUser.email,
      address: staffUser.address ?? ownerUser.address,
      city: staffUser.city ?? ownerUser.city,
      state: staffUser.state ?? ownerUser.state,
      zipcode: staffUser.zipcode ?? ownerUser.zipcode,
      country: ownerUser.country ?? staffUser.country,
      firstName: staffUser.firstName ?? staffUser.userName,
      lastName: staffUser.lastName,
      title: ownerUser.title ?? staffUser.title,
      mobile: staffUser.mobile,
      isTrial: staffUser.isTrial,
      outletData: staffOutlets,
      role: staffUser.role,
      staffRole: staffUser.staffRole,
      permissions: staffUser.permissions,
      userId: staffUser.userId ?? ownerUser.userId ?? ownerUser.id,
      userName: staffUser.userName ?? staffUser.firstName,
      uniqueId: staffUser.uniqueId,
      district: staffUser.district,
      pincode: staffUser.pincode,
      dateOfBirth: staffUser.dateOfBirth,
      gender: staffUser.gender,
      profileImage: staffUser.profileImage,
      activated: staffUser.activated,
    );

    appPref.user = merged;
    appPref.isStaffSession = true;
    if (merged.permissions != null) {
      appPref.staffPermissions = merged.permissions!;
    }
    return merged;
  }

  /// Staff may only see outlets they were added to.
  /// Prefer full owner records; fall back to staff login payload.
  static List<OutletData> _staffOnlyOutlets({
    required List<OutletData> staffAssigned,
    required List<OutletData> ownerOutlets,
  }) {
    final allowedIds = staffAssigned
        .map((o) => o.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    if (allowedIds.isEmpty) return staffAssigned;

    final enriched = ownerOutlets
        .where((o) => o.id != null && allowedIds.contains(o.id))
        .toList();

    return enriched.isNotEmpty ? enriched : staffAssigned;
  }

  static OutletData _pickSelectedOutlet({
    required String? preferredId,
    required List<OutletData> staffOutlets,
  }) {
    if (preferredId != null) {
      final match =
          staffOutlets.firstWhereOrNull((o) => o.id == preferredId);
      if (match != null) return match;
    }
    return staffOutlets.first;
  }

  static User _persistStaffSession(AppPref appPref, User staffUser) {
    appPref.user = staffUser;
    appPref.isStaffSession = true;
    if (staffUser.permissions != null) {
      appPref.staffPermissions = staffUser.permissions!;
    }
    final outlets = staffUser.outletData ?? [];
    if (outlets.isNotEmpty) {
      final selectedId = appPref.selectedOutlet?.id;
      appPref.selectedOutlet = outlets.firstWhereOrNull(
            (o) => o.id == selectedId,
          ) ??
          outlets.first;
    }
    return staffUser;
  }

  static User _saveStaffUser(AppPref appPref, User staffUser) {
    return _persistStaffSession(appPref, staffUser);
  }
}
