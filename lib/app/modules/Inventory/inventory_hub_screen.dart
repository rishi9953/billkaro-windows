import 'package:billkaro/app/modules/Inventory/inventory_controller.dart';
import 'package:billkaro/app/modules/Inventory/dialogs/inventory_dialogs.dart';
import 'package:billkaro/app/modules/Inventory/dialogs/product_stock_dialogs.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/app/Widgets/app_date_picker.dart';
import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:intl/intl.dart';

part 'hub/tabs/inventory_overview_tab.dart';
part 'hub/tabs/inventory_product_stock_tab.dart';
part 'hub/tabs/inventory_raw_materials_tab.dart';
part 'hub/tabs/inventory_stock_log_tab.dart';
part 'hub/tabs/inventory_suppliers_tab.dart';
part 'hub/tabs/inventory_recipes_tab.dart';
part 'hub/inventory_hub_shared.dart';

const Color _inventoryAccent = Color(0xFFEF8819);
const Color _inventoryCardBg = Colors.white;

const TextStyle _headerStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: Color(0xFF6B7280),
);

class InventoryHubScreen extends StatefulWidget {
  const InventoryHubScreen({super.key});

  @override
  State<InventoryHubScreen> createState() => _InventoryHubScreenState();
}

class _InventoryHubScreenState extends State<InventoryHubScreen>
    with SingleTickerProviderStateMixin {
  final controller = Get.put(InventoryController());
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  final _supplierSearchCtrl = TextEditingController();
  final _stockLogSearchCtrl = TextEditingController();
  final _recipeSearchCtrl = TextEditingController();
  final _productStockHScrollCtrl = ScrollController();
  final _rawMaterialsHScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        controller.selectedTab.value = _tabController.index;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _supplierSearchCtrl.dispose();
    _stockLogSearchCtrl.dispose();
    _recipeSearchCtrl.dispose();
    _productStockHScrollCtrl.dispose();
    _rawMaterialsHScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.inventory_management,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                Text(
                  loc.inventory_subtitle,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: loc.refresh,
            onPressed: controller.loadAll,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Theme.of(context).primaryColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: _inventoryAccent,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: loc.tab_overview),
                Tab(text: 'Stock'),
                Tab(text: loc.tab_stock_log),
                Tab(text: loc.tab_suppliers),
                Tab(text: loc.tab_recipes),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.dashboard.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _tabController,
                children: [
                  _overviewTab(isWide, loc),
                  _rawMaterialsTab(isWide, loc),
                  _stockLogTab(isWide, loc),
                  _suppliersTab(isWide, loc),
                  _recipesTab(isWide, loc),
                ],
              ),
            ),
          ],
        );
      }),
      floatingActionButton: !StaffAccess.canAdjustStock
          ? null
          : _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return;
                showAddRawMaterialDialog(controller);
              },
              backgroundColor: _inventoryAccent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_box_outlined),
              label: Text(loc.add_material),
            )
          : _tabController.index == 3
          ? FloatingActionButton.extended(
              onPressed: () {
                if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return;
                showAddSupplierDialog(controller);
              },
              backgroundColor: _inventoryAccent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(loc.add_supplier),
            )
          : _tabController.index == 4
          ? FloatingActionButton.extended(
              onPressed: () {
                if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return;
                showAddRecipeDialog(controller);
              },
              backgroundColor: _inventoryAccent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.restaurant_menu),
              label: Text(loc.add_recipe),
            )
          : null,
    );
  }
}
