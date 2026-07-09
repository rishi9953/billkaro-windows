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

  /// Business overview, payment summary, and sales trends on the home dashboard.
  static bool get canViewDashboardInsights =>
      isOwnerSession || canViewReports;

  static bool get canViewInventory => isOwnerSession || canViewReports;

  static bool canAccessRoute(String path) {
    if (path.startsWith('/staff')) return canManageStaff;
    if (path.startsWith('/subscriptions')) return canManageSubscriptions;
    if (path.startsWith('/wallet')) return isOwnerSession;
    if (path.startsWith('/whatsaap-marketing')) return canUseWhatsAppMarketing;
    if (path.startsWith('/reports') ||
        path.startsWith('/order-report') ||
        path.startsWith('/item-report')) {
      return canViewReports;
    }
    if (path.startsWith('/inventory')) return canViewInventory;
    if (path.startsWith('/store-session-history')) return canViewStoreHistory;
    return true;
  }

  static bool get canManageStaff => isOwnerSession;

  static bool get canManageSubscriptions => isOwnerSession;

  static bool get canUseWhatsAppMarketing =>
      isOwnerSession || canViewReports;

  /// Day open/close history — owner only (not visible to staff).
  static bool get canViewStoreHistory => isOwnerSession;
}
