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
    importExportCustomers,
    viewReports,
    generateReports,
    viewStaff,
    createStaff,
    updateStaff,
    deleteStaff,
    manageSettings,
  ];

  static const List<String> secondaryAdminDefaults = all;

  static const List<String> billerDefaults = [
    viewSales,
    createSales,
    issueRefunds,
    viewCustomers,
    createCustomers,
  ];
}

class StaffPermissionItem {
  const StaffPermissionItem({required this.key, required this.label});

  final String key;
  final String label;
}

class StaffPermissionGroup {
  const StaffPermissionGroup({required this.title, required this.items});

  final String title;
  final List<StaffPermissionItem> items;
}

/// UI catalog matching the Add Staff permissions section.
const List<StaffPermissionGroup> kStaffPermissionGroups = [
  StaffPermissionGroup(
    title: 'Products',
    items: [
      StaffPermissionItem(
        key: StaffPermissionKeys.viewProducts,
        label: 'View products',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.createProducts,
        label: 'Create products',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.updateProducts,
        label: 'Update products',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.deleteProducts,
        label: 'Delete products',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.importExportProducts,
        label: 'Import / Export products',
      ),
    ],
  ),
  StaffPermissionGroup(
    title: 'Categories',
    items: [
      StaffPermissionItem(
        key: StaffPermissionKeys.viewCategories,
        label: 'View categories',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.createCategories,
        label: 'Create categories',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.updateCategories,
        label: 'Update categories',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.deleteCategories,
        label: 'Delete categories',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.importExportCategories,
        label: 'Import / Export categories',
      ),
    ],
  ),
  StaffPermissionGroup(
    title: 'Sales & POS',
    items: [
      StaffPermissionItem(
        key: StaffPermissionKeys.viewSales,
        label: 'View sales',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.createSales,
        label: 'Create sales',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.updateSales,
        label: 'Update sales',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.issueRefunds,
        label: 'Issue refunds',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.exportSales,
        label: 'Export sales',
      ),
    ],
  ),
  StaffPermissionGroup(
    title: 'Inventory',
    items: [
      StaffPermissionItem(
        key: StaffPermissionKeys.viewInventory,
        label: 'View inventory',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.adjustStock,
        label: 'Adjust stock',
      ),
    ],
  ),
  StaffPermissionGroup(
    title: 'Customers',
    items: [
      StaffPermissionItem(
        key: StaffPermissionKeys.viewCustomers,
        label: 'View customers',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.createCustomers,
        label: 'Create customers',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.updateCustomers,
        label: 'Update customers',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.deleteCustomers,
        label: 'Delete customers',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.importExportCustomers,
        label: 'Import / Export customers',
      ),
    ],
  ),
  StaffPermissionGroup(
    title: 'Reports',
    items: [
      StaffPermissionItem(
        key: StaffPermissionKeys.viewReports,
        label: 'View reports',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.generateReports,
        label: 'Generate reports',
      ),
    ],
  ),
  StaffPermissionGroup(
    title: 'Staff',
    items: [
      StaffPermissionItem(
        key: StaffPermissionKeys.viewStaff,
        label: 'View staff',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.createStaff,
        label: 'Create staff',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.updateStaff,
        label: 'Update staff',
      ),
      StaffPermissionItem(
        key: StaffPermissionKeys.deleteStaff,
        label: 'Delete staff',
      ),
    ],
  ),
  StaffPermissionGroup(
    title: 'Settings',
    items: [
      StaffPermissionItem(
        key: StaffPermissionKeys.manageSettings,
        label: 'Manage settings',
      ),
    ],
  ),
];

/// Expands legacy permission keys into the granular set used by the UI.
Set<String> expandStaffPermissions(Iterable<String> raw) {
  final input = raw
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet();
  final result = <String>{};

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
      case StaffPermissionKeys.legacyEditMenu:
        result.addAll([
          StaffPermissionKeys.viewProducts,
          StaffPermissionKeys.createProducts,
          StaffPermissionKeys.updateProducts,
          StaffPermissionKeys.viewCategories,
        ]);
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

  return result;
}
