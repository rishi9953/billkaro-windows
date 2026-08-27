import 'package:billkaro/config/app_pref.dart';
import 'package:billkaro/utils/staff_permission_keys.dart';
import 'package:get/get.dart';

/// Staff / owner access checks for UI and actions.
class StaffAccess {
  StaffAccess._();

  static AppPref get _pref => Get.find<AppPref>();

  static bool get isStaffSession =>
      _pref.isStaffSession || _pref.user?.role == 'staff';

  static bool get isOwnerSession => !isStaffSession;

  /// Logged-in staff role from `staffRole` (falls back to `role`).
  static String get _staffRoleLabel {
    final staffRole = (_pref.user?.staffRole ?? '').trim();
    if (staffRole.isNotEmpty) {
      return staffRole.toLowerCase().replaceAll('_', ' ');
    }
    final role = (_pref.user?.role ?? '').trim().toLowerCase().replaceAll(
      '_',
      ' ',
    );
    if (role == 'biller' || role == 'secondary admin') return role;
    return '';
  }

  /// True when the current staff login is a Biller.
  static bool get isBillerSession =>
      isStaffSession && _staffRoleLabel == 'biller';

  /// True when the current staff login is a Secondary Admin.
  static bool get isSecondaryAdminSession =>
      isStaffSession && _staffRoleLabel == 'secondary admin';

  /// True when [role] is Secondary Admin (any API/UI spelling).
  static bool isSecondaryAdminRole(String? role) {
    final normalized = (role ?? '').trim().toLowerCase().replaceAll('_', ' ');
    return normalized == 'secondary admin';
  }

  /// True when this staff list row is the currently logged-in staff user.
  /// Used to hide self from the staff list (cannot update own account there).
  static bool isSelfStaffRecord({
    String? staffId,
    String? email,
    String? uniqueId,
  }) {
    if (!isStaffSession) return false;
    final user = _pref.user;
    if (user == null) return false;

    final myIds = <String>{
      user.id?.trim() ?? '',
      user.userId?.trim() ?? '',
    }..removeWhere((e) => e.isEmpty);

    final recordId = staffId?.trim() ?? '';
    if (recordId.isNotEmpty && myIds.contains(recordId)) return true;

    final myEmail = user.email?.trim().toLowerCase() ?? '';
    final recordEmail = email?.trim().toLowerCase() ?? '';
    if (myEmail.isNotEmpty &&
        recordEmail.isNotEmpty &&
        myEmail == recordEmail) {
      return true;
    }

    final myUniqueId = user.uniqueId?.trim() ?? '';
    final recordUniqueId = uniqueId?.trim() ?? '';
    if (myUniqueId.isNotEmpty &&
        recordUniqueId.isNotEmpty &&
        myUniqueId == recordUniqueId) {
      return true;
    }

    return false;
  }

  static Set<String> get _rawPermissionKeys {
    if (!isStaffSession) return const {};
    final live = _pref.user?.permissions;
    if (live != null && live.isNotEmpty) {
      return live.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    }
    return _pref.staffPermissions
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  static Set<String> get _permissions {
    if (!isStaffSession) return const {};
    return expandStaffPermissions(_rawPermissionKeys);
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
      canDeleteProducts ||
      canImportExportProducts;

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
      canDeleteCategories ||
      canImportExportCategories;

  /// Import / Export items & categories (paired permission).
  static bool get canShowImportExportItems =>
      canImportExportProducts || canImportExportCategories;

  /// Sidebar / drawer: Add Item (needs create_products).
  static bool get canShowAddMenuItemInShell => canCreateProducts;

  /// Sidebar / drawer: Add Category (needs create_categories).
  static bool get canShowAddCategoryInShell => canCreateCategories;

  /// Menu list AppBar ⋮ : Add item and/or Add category.
  static bool get canShowMenuListAddActions =>
      canCreateProducts || canCreateCategories;

  /// Per-item ⋮ : Edit / Delete.
  static bool get canShowMenuItemOverflowMenu =>
      canUpdateProducts || canDeleteProducts;

  /// Availability switch on an item card.
  static bool get canShowItemAvailabilityToggle => canUpdateProducts;

  /// Edit category (long-press / edit icon).
  static bool get canShowCategoryEditActions => canUpdateCategories;

  /// Delete category actions.
  static bool get canShowCategoryDeleteActions => canDeleteCategories;

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

  /// Create Order (sidebar, FAB, home, new table order).
  static bool get canShowCreateOrder => canCreateSales;

  /// Edit existing orders (hold / occupied table / closed soft-actions).
  static bool get canShowEditOrder => canUpdateSales;

  /// Closed + On Hold lists.
  static bool get canShowOrdersList => canAccessSales;

  /// Soft-deleted orders — owner only (hidden from staff).
  static bool get canAccessDeletedOrders => isOwnerSession;

  /// Stock summary — owner only (hidden from staff).
  static bool get canAccessStockSummary => isOwnerSession;

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

  static bool get canOpenStore => hasPermission(StaffPermissionKeys.openStore);

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
      canViewTables || canCreateTables || canUpdateTables || canDeleteTables;

  static bool get canViewKot => hasPermission(StaffPermissionKeys.viewKot);

  static bool get canPrintKot => hasPermission(StaffPermissionKeys.printKot);

  static bool get canReprintKot =>
      hasPermission(StaffPermissionKeys.reprintKot);

  static bool get canOpenKitchenDisplay =>
      hasPermission(StaffPermissionKeys.kitchenDisplay);

  static bool get canAccessKot =>
      canViewKot || canPrintKot || canReprintKot || canOpenKitchenDisplay;

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
    if (path.startsWith('/items')) {
      return canAccessProducts;
    }
    if (path.startsWith('/add-menu-item')) {
      return canCreateProducts || canUpdateProducts;
    }
    if (path.startsWith('/category')) {
      return canCreateCategories || canUpdateCategories;
    }
    if (path.startsWith('/create-order') || path.startsWith('/order-details')) {
      return canShowCreateOrder || canShowEditOrder;
    }
    if (path.startsWith('/closed-orders') || path.startsWith('/hold-orders')) {
      return canShowOrdersList;
    }
    if (path.startsWith('/deleted-orders')) {
      return canAccessDeletedOrders;
    }
    if (path.startsWith('/stock-summary')) {
      return canAccessStockSummary;
    }
    if (path.startsWith('/customers') ||
        path.startsWith('/customer-details') ||
        path.startsWith('/add-regular-customer')) {
      return canAccessCustomers;
    }
    if (path.startsWith('/app-settings')) return canManageSettings;
    if (path.startsWith('/tables')) return canAccessTables;
    if (path.startsWith('/kot-history') || path.startsWith('/kotHistory')) {
      return canViewKot || canReprintKot;
    }
    if (path.startsWith('/kot-receipt')) {
      return canViewKot || canReprintKot || canPrintKot;
    }
    if (path.startsWith('/kitchen-display')) {
      return canOpenKitchenDisplay;
    }
    return true;
  }
}
