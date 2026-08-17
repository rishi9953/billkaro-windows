import 'package:billkaro/config/app_pref.dart';
import 'package:billkaro/utils/staff_permission_keys.dart';
import 'package:get/get.dart';

/// Staff / owner access checks for UI and actions.
class StaffAccess {
  StaffAccess._();

  static AppPref get _pref => Get.find<AppPref>();

  static bool get isStaffSession => _pref.isStaffSession;

  static bool get isOwnerSession => !_pref.isStaffSession;

  static Set<String> get _permissions {
    return expandStaffPermissions(_pref.staffPermissions);
  }

  static bool hasPermission(String permission) {
    if (isOwnerSession) return true;
    return _permissions.contains(permission);
  }

  static bool get canViewProducts =>
      hasPermission(StaffPermissionKeys.viewProducts);

  static bool get canCreateProducts =>
      hasPermission(StaffPermissionKeys.createProducts);

  static bool get canUpdateProducts =>
      hasPermission(StaffPermissionKeys.updateProducts);

  static bool get canDeleteProducts =>
      hasPermission(StaffPermissionKeys.deleteProducts);

  static bool get canImportExportProducts =>
      hasPermission(StaffPermissionKeys.importExportProducts);

  static bool get canAccessProducts =>
      canViewProducts ||
      canCreateProducts ||
      canUpdateProducts ||
      canDeleteProducts;

  static bool get canViewCategories =>
      hasPermission(StaffPermissionKeys.viewCategories);

  static bool get canCreateCategories =>
      hasPermission(StaffPermissionKeys.createCategories);

  static bool get canUpdateCategories =>
      hasPermission(StaffPermissionKeys.updateCategories);

  static bool get canDeleteCategories =>
      hasPermission(StaffPermissionKeys.deleteCategories);

  static bool get canImportExportCategories =>
      hasPermission(StaffPermissionKeys.importExportCategories);

  static bool get canAccessCategories =>
      canViewCategories ||
      canCreateCategories ||
      canUpdateCategories ||
      canDeleteCategories;

  static bool get canViewSales => hasPermission(StaffPermissionKeys.viewSales);

  static bool get canCreateSales =>
      hasPermission(StaffPermissionKeys.createSales);

  static bool get canUpdateSales =>
      hasPermission(StaffPermissionKeys.updateSales);

  static bool get canIssueRefunds =>
      hasPermission(StaffPermissionKeys.issueRefunds);

  static bool get canExportSales =>
      hasPermission(StaffPermissionKeys.exportSales);

  static bool get canAccessSales =>
      canViewSales || canCreateSales || canUpdateSales;

  /// Backward-compatible aliases used by older UI.
  static bool get canCreateBill => canCreateSales;

  static bool get canEditMenu => canUpdateProducts || canCreateProducts;

  static bool get canViewReports =>
      hasPermission(StaffPermissionKeys.viewReports);

  static bool get canGenerateReports =>
      hasPermission(StaffPermissionKeys.generateReports);

  /// Business overview, payment summary, and sales trends on the home dashboard.
  static bool get canViewDashboardInsights => isOwnerSession || canViewReports;

  static bool get canViewInventory =>
      hasPermission(StaffPermissionKeys.viewInventory);

  static bool get canAdjustStock =>
      hasPermission(StaffPermissionKeys.adjustStock);

  static bool get canViewCustomers =>
      hasPermission(StaffPermissionKeys.viewCustomers);

  static bool get canCreateCustomers =>
      hasPermission(StaffPermissionKeys.createCustomers);

  static bool get canUpdateCustomers =>
      hasPermission(StaffPermissionKeys.updateCustomers);

  static bool get canDeleteCustomers =>
      hasPermission(StaffPermissionKeys.deleteCustomers);

  static bool get canImportExportCustomers =>
      hasPermission(StaffPermissionKeys.importExportCustomers);

  static bool get canAccessCustomers =>
      canViewCustomers ||
      canCreateCustomers ||
      canUpdateCustomers ||
      canDeleteCustomers;

  /// Returns true when allowed; otherwise shows a snackbar and returns false.
  static bool ensure(
    bool allowed, {
    String message = 'You do not have permission to perform this action.',
  }) {
    if (allowed) return true;
    if (Get.isRegistered<AppPref>() || Get.context != null) {
      try {
        Get.snackbar(
          'Access denied',
          message,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } catch (_) {}
    }
    return false;
  }

  static bool get canViewStaff => hasPermission(StaffPermissionKeys.viewStaff);

  static bool get canCreateStaff =>
      hasPermission(StaffPermissionKeys.createStaff);

  static bool get canUpdateStaff =>
      hasPermission(StaffPermissionKeys.updateStaff);

  static bool get canDeleteStaff =>
      hasPermission(StaffPermissionKeys.deleteStaff);

  /// Only the outlet owner may invite or promote a Secondary Admin.
  static bool get canAssignSecondaryAdmin => isOwnerSession;

  static bool get canManageStaff =>
      isOwnerSession ||
      canViewStaff ||
      canCreateStaff ||
      canUpdateStaff ||
      canDeleteStaff;

  static bool get canManageSettings =>
      hasPermission(StaffPermissionKeys.manageSettings);

  static bool get canOpenStore =>
      hasPermission(StaffPermissionKeys.openStore);

  static bool get canCloseStore =>
      hasPermission(StaffPermissionKeys.closeStore);

  static bool get canViewTables =>
      hasPermission(StaffPermissionKeys.viewTables);

  static bool get canCreateTables =>
      hasPermission(StaffPermissionKeys.createTables);

  static bool get canUpdateTables =>
      hasPermission(StaffPermissionKeys.updateTables);

  static bool get canDeleteTables =>
      hasPermission(StaffPermissionKeys.deleteTables);

  static bool get canAccessTables =>
      canViewTables ||
      canCreateTables ||
      canUpdateTables ||
      canDeleteTables;

  static bool get canManageSubscriptions => isOwnerSession;

  static bool get canUseWhatsAppMarketing => isOwnerSession || canViewReports;

  /// Day open/close history — owner only (not visible to staff).
  static bool get canViewStoreHistory => isOwnerSession;

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
    if (path.startsWith('/inventory') || path.startsWith('/purchase-orders')) {
      return canViewInventory;
    }
    if (path.startsWith('/store-session-history')) return canViewStoreHistory;
    if (path.startsWith('/items') || path.startsWith('/add-menu-item')) {
      return canAccessProducts;
    }
    if (path.startsWith('/category')) return canAccessCategories;
    if (path.startsWith('/create-order')) return canCreateSales;
    if (path.startsWith('/order-details') ||
        path.startsWith('/closed-orders') ||
        path.startsWith('/hold-orders') ||
        path.startsWith('/deleted-orders') ||
        path.startsWith('/stock-summary')) {
      return canAccessSales;
    }
    if (path.startsWith('/customers') ||
        path.startsWith('/customer-details') ||
        path.startsWith('/add-regular-customer')) {
      return canAccessCustomers;
    }
    if (path.startsWith('/app-settings')) return canManageSettings;
    if (path.startsWith('/tables')) return canAccessTables;
    return true;
  }
}
