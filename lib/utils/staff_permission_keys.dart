/// Canonical staff permission keys stored in `outlet_staff.permissions` (TEXT[]).
class StaffPermissionKeys {
  StaffPermissionKeys._();

  // Products
  static const viewProducts = 'view_products';
  static const createProducts = 'create_products';
  static const updateProducts = 'update_products';
  static const deleteProducts = 'delete_products';
  static const importExportProducts = 'import_export_products';

  // Categories
  static const viewCategories = 'view_categories';
  static const createCategories = 'create_categories';
  static const updateCategories = 'update_categories';
  static const deleteCategories = 'delete_categories';
  static const importExportCategories = 'import_export_categories';

  // Sales & POS
  static const viewSales = 'view_sales';
  static const createSales = 'create_sales';
  static const updateSales = 'update_sales';
  static const issueRefunds = 'issue_refunds';
  static const exportSales = 'export_sales';

  // Inventory
  static const viewInventory = 'view_inventory';
  static const adjustStock = 'adjust_stock';

  // Customers
  static const viewCustomers = 'view_customers';
  static const createCustomers = 'create_customers';
  static const updateCustomers = 'update_customers';
  static const deleteCustomers = 'delete_customers';
  static const importExportCustomers = 'import_export_customers';

  // Reports
  static const viewReports = 'view_reports';
  static const generateReports = 'generate_reports';

  // Staff
  static const viewStaff = 'view_staff';
  static const createStaff = 'create_staff';
  static const updateStaff = 'update_staff';
  static const deleteStaff = 'delete_staff';

  // Settings
  static const manageSettings = 'manage_settings';

  // Store day session
  static const openStore = 'open_store';
  static const closeStore = 'close_store';

  // Tables
  static const viewTables = 'view_tables';
  static const createTables = 'create_tables';
  static const updateTables = 'update_tables';
  static const deleteTables = 'delete_tables';

  // KOT
  static const viewKot = 'view_kot';
  static const printKot = 'print_kot';
  static const reprintKot = 'reprint_kot';
  static const kitchenDisplay = 'kitchen_display';

  /// Legacy keys still accepted when reading older staff records.
  static const legacyCreateBill = 'create_bill';
  static const legacyManageBills = 'manage_bills';
  static const legacyEditMenu = 'edit_menu';

  static const List<String> all = [
    viewProducts,
    createProducts,
    updateProducts,
    deleteProducts,
    importExportProducts,
    viewCategories,
    createCategories,
    updateCategories,
    deleteCategories,
    importExportCategories,
    viewSales,
    createSales,
    updateSales,
    issueRefunds,
    exportSales,
    viewInventory,
    adjustStock,
    viewCustomers,
    createCustomers,
    updateCustomers,
    deleteCustomers,
    // importExportCustomers,
    viewReports,
    generateReports,
    viewStaff,
    createStaff,
    updateStaff,
    deleteStaff,
    manageSettings,
    openStore,
    closeStore,
    viewTables,
    createTables,
    updateTables,
    deleteTables,
    viewKot,
    printKot,
    // reprintKot,
    kitchenDisplay,
  ];

  static const List<String> secondaryAdminDefaults = all;

  static const List<String> billerDefaults = [
    viewSales,
    createSales,
    issueRefunds,
    viewCustomers,
    createCustomers,
    viewTables,
    viewKot,
    printKot,
    // reprintKot,
    kitchenDisplay,
  ];
}

/// A single UI toggle that may grant one or more stored permission keys.
class StaffPermissionItem {
  const StaffPermissionItem({required this.keys, required this.label});

  /// Stored permission key(s) controlled by this toggle.
  final List<String> keys;
  final String label;

  /// True when every key in this toggle is present.
  bool isGranted(Iterable<String> selected) {
    final set = selected is Set<String> ? selected : selected.toSet();
    return keys.every(set.contains);
  }
}

StaffPermissionItem _perm(String key, String label) =>
    StaffPermissionItem(keys: [key], label: label);

StaffPermissionItem _pairedPerm(
  String productKey,
  String categoryKey,
  String label,
) => StaffPermissionItem(keys: [productKey, categoryKey], label: label);

class StaffPermissionGroup {
  const StaffPermissionGroup({required this.title, required this.items});

  final String title;
  final List<StaffPermissionItem> items;
}

/// Number of toggles shown in the Add / Edit Staff permissions UI.
int get kStaffPermissionCatalogSize =>
    staffPermissionCatalogSize(includeTables: true);

/// Permission groups for the Add / Edit Staff picker.
///
/// Hides the Tables group when the outlet has no seating.
List<StaffPermissionGroup> staffPermissionGroups({
  required bool includeTables,
}) {
  if (includeTables) return kStaffPermissionGroups;
  return kStaffPermissionGroups
      .where((group) => group.title != 'Tables')
      .toList(growable: false);
}

int staffPermissionCatalogSize({required bool includeTables}) =>
    staffPermissionGroups(includeTables: includeTables).fold<int>(
      0,
      (sum, group) => sum + group.items.length,
    );

/// How many catalog toggles are fully granted for [selected] keys.
int countGrantedStaffPermissionItems(
  Iterable<String> selected, {
  bool includeTables = true,
}) {
  final set = selected is Set<String> ? selected : selected.toSet();
  var count = 0;
  for (final group in staffPermissionGroups(includeTables: includeTables)) {
    for (final item in group.items) {
      if (item.isGranted(set)) count++;
    }
  }
  return count;
}

/// Keys from toggles that are fully on — drops orphan keys (e.g. update_products
/// without update_categories) so the DB matches what the UI shows.
List<String> keysFromGrantedToggles(
  Iterable<String> selected, {
  bool includeTables = true,
}) {
  final set = selected is Set<String> ? selected : selected.toSet();
  final keys = <String>{};
  for (final group in staffPermissionGroups(includeTables: includeTables)) {
    for (final item in group.items) {
      if (item.isGranted(set)) {
        keys.addAll(item.keys);
      }
    }
  }
  return keys.toList()..sort();
}

/// All permission keys currently visible in the Add / Edit Staff picker.
List<String> allVisibleStaffPermissionKeys({required bool includeTables}) {
  final keys = <String>{};
  for (final group in staffPermissionGroups(includeTables: includeTables)) {
    for (final item in group.items) {
      keys.addAll(item.keys);
    }
  }
  return keys.toList()..sort();
}

/// UI catalog matching the Add Staff permissions section.
///
/// Items and categories are paired: each toggle grants both related keys.
final List<StaffPermissionGroup> kStaffPermissionGroups = [
  StaffPermissionGroup(
    title: 'Items & Categories',
    items: [
      _pairedPerm(
        StaffPermissionKeys.viewProducts,
        StaffPermissionKeys.viewCategories,
        'View items & categories',
      ),
      _pairedPerm(
        StaffPermissionKeys.createProducts,
        StaffPermissionKeys.createCategories,
        'Create items & categories',
      ),
      _pairedPerm(
        StaffPermissionKeys.updateProducts,
        StaffPermissionKeys.updateCategories,
        'Update items & categories',
      ),
      _pairedPerm(
        StaffPermissionKeys.deleteProducts,
        StaffPermissionKeys.deleteCategories,
        'Delete items & categories',
      ),
      _pairedPerm(
        StaffPermissionKeys.importExportProducts,
        StaffPermissionKeys.importExportCategories,
        'Import / Export items & categories',
      ),
    ],
  ),
  StaffPermissionGroup(
    title: 'Sales & POS',
    items: [
      _perm(StaffPermissionKeys.viewSales, 'View sales'),
      _perm(StaffPermissionKeys.createSales, 'Create sales'),
      _perm(StaffPermissionKeys.updateSales, 'Update sales'),
      // _perm(StaffPermissionKeys.issueRefunds, 'Issue refunds'),
      _perm(StaffPermissionKeys.exportSales, 'Export sales'),
    ],
  ),
  StaffPermissionGroup(
    title: 'Inventory',
    items: [
      _perm(StaffPermissionKeys.viewInventory, 'View inventory'),
      _perm(StaffPermissionKeys.adjustStock, 'Adjust stock'),
    ],
  ),
  StaffPermissionGroup(
    title: 'Customers',
    items: [
      _perm(StaffPermissionKeys.viewCustomers, 'View customers'),
      _perm(StaffPermissionKeys.createCustomers, 'Create customers'),
      _perm(StaffPermissionKeys.updateCustomers, 'Update customers'),
      _perm(StaffPermissionKeys.deleteCustomers, 'Delete customers'),
      // _perm(
      //   StaffPermissionKeys.importExportCustomers,
      //   'Import / Export customers',
      // ),
    ],
  ),
  StaffPermissionGroup(
    title: 'Reports',
    items: [
      _perm(StaffPermissionKeys.viewReports, 'View reports'),
      _perm(StaffPermissionKeys.generateReports, 'Generate reports'),
    ],
  ),
  StaffPermissionGroup(
    title: 'Staff',
    items: [
      _perm(StaffPermissionKeys.viewStaff, 'View staff'),
      _perm(StaffPermissionKeys.createStaff, 'Create staff'),
      _perm(StaffPermissionKeys.updateStaff, 'Update staff'),
      _perm(StaffPermissionKeys.deleteStaff, 'Delete staff'),
    ],
  ),
  StaffPermissionGroup(
    title: 'Settings',
    items: [_perm(StaffPermissionKeys.manageSettings, 'Manage settings')],
  ),
  StaffPermissionGroup(
    title: 'Store',
    items: [
      _perm(StaffPermissionKeys.openStore, 'Open store'),
      _perm(StaffPermissionKeys.closeStore, 'Close store'),
    ],
  ),
  StaffPermissionGroup(
    title: 'Tables',
    items: [
      _perm(StaffPermissionKeys.viewTables, 'View tables'),
      _perm(StaffPermissionKeys.createTables, 'Create tables'),
      _perm(StaffPermissionKeys.updateTables, 'Update tables'),
      _perm(StaffPermissionKeys.deleteTables, 'Delete tables'),
    ],
  ),
  StaffPermissionGroup(
    title: 'KOT',
    items: [
      _perm(StaffPermissionKeys.viewKot, 'View KOT history'),
      _perm(StaffPermissionKeys.printKot, 'Print KOT'),
      // _perm(StaffPermissionKeys.reprintKot, 'Reprint KOT'),
      _perm(StaffPermissionKeys.kitchenDisplay, 'Kitchen display'),
    ],
  ),
];

bool hasGranularProductPermission(Set<String> input) => input.any(
  (k) =>
      k == StaffPermissionKeys.viewProducts ||
      k == StaffPermissionKeys.createProducts ||
      k == StaffPermissionKeys.updateProducts ||
      k == StaffPermissionKeys.deleteProducts ||
      k == StaffPermissionKeys.importExportProducts,
);

/// Expands legacy permission keys into the granular set used by the UI.
Set<String> expandStaffPermissions(Iterable<String> raw) {
  final input = raw
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet();
  final result = <String>{};
  final hasGranularProducts = hasGranularProductPermission(input);

  for (final key in input) {
    if (StaffPermissionKeys.all.contains(key)) {
      result.add(key);
      continue;
    }
    switch (key) {
      case StaffPermissionKeys.legacyCreateBill:
      case StaffPermissionKeys.legacyManageBills:
        result.addAll([
          StaffPermissionKeys.viewSales,
          StaffPermissionKeys.createSales,
        ]);
        break;
      case StaffPermissionKeys.legacyEditMenu:
        // Ignore obsolete edit_menu when granular product keys exist
        // (e.g. view_products only) so view-only staff cannot create.
        if (!hasGranularProducts) {
          result.addAll([
            StaffPermissionKeys.viewProducts,
            StaffPermissionKeys.viewCategories,
            StaffPermissionKeys.createProducts,
            StaffPermissionKeys.createCategories,
            StaffPermissionKeys.updateProducts,
            StaffPermissionKeys.updateCategories,
          ]);
        }
        break;
      default:
        break;
    }
  }

  // Pre-migration: `view_reports` also unlocked inventory.
  final hasOtherGranular = input.any(
    (k) =>
        StaffPermissionKeys.all.contains(k) &&
        k != StaffPermissionKeys.viewReports,
  );
  if (input.contains(StaffPermissionKeys.viewReports) && !hasOtherGranular) {
    result.add(StaffPermissionKeys.viewInventory);
    result.add(StaffPermissionKeys.generateReports);
  }

  // Paired: Import / Export items & categories — if one key exists, grant both.
  if (result.contains(StaffPermissionKeys.importExportProducts) ||
      result.contains(StaffPermissionKeys.importExportCategories)) {
    result.add(StaffPermissionKeys.importExportProducts);
    result.add(StaffPermissionKeys.importExportCategories);
  }

  return result;
}
