import 'package:billkaro/config/app_pref.dart';
import 'package:get/get.dart';

/// Staff / owner access checks for UI and actions.
class StaffAccess {
  StaffAccess._();

  static AppPref get _pref => Get.find<AppPref>();

  static bool get isStaffSession => _pref.isStaffSession;

  static bool get isOwnerSession => !_pref.isStaffSession;

  static Set<String> get _permissions {
    return _pref.staffPermissions.map((p) => p.trim()).toSet();
  }

  static bool hasPermission(String permission) {
    if (isOwnerSession) return true;
    return _permissions.contains(permission);
  }

  static bool get canCreateBill =>
      hasPermission('create_bill') || hasPermission('manage_bills');

  static bool get canEditMenu => hasPermission('edit_menu');

  static bool get canViewReports => hasPermission('view_reports');

  static bool get canManageStaff => isOwnerSession;

  static bool get canManageSubscriptions => isOwnerSession;

  static bool get canUseWhatsAppMarketing =>
      isOwnerSession || canViewReports;
}
