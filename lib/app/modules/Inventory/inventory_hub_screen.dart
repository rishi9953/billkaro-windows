import 'package:billkaro/app/modules/Inventory/inventory_controller.dart';
import 'package:billkaro/app/modules/Inventory/inventory_dialogs.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/config/config.dart';
import 'package:intl/intl.dart';

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

  static const _accent = Color(0xFFEF8819);
  static const _cardBg = Colors.white;

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
              indicatorColor: _accent,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: loc.tab_overview),
                Tab(text: loc.tab_raw_materials),
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
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () => showAddRawMaterialDialog(controller),
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_box_outlined),
              label: Text(loc.add_material),
            )
          : _tabController.index == 3
          ? FloatingActionButton.extended(
              onPressed: () => showAddSupplierDialog(controller),
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(loc.add_supplier),
            )
          : null,
    );
  }

  Widget _statsRow(bool isWide, AppLocalizations loc) {
    final d = controller.dashboard.value;
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _statCard(
            loc.stat_raw_materials,
            '${d?.totalRawMaterials ?? 0}',
            Icons.grain,
            const Color(0xFF3B82F6),
            isWide: isWide,
          ),
          _statCard(
            loc.stat_low_stock_alerts,
            '${d?.lowStockCount ?? 0}',
            Icons.warning_amber_rounded,
            const Color(0xFFEF4444),
            isWide: isWide,
          ),
          _statCard(
            loc.stat_stock_value,
            '₹${_fmt(d?.totalStockValue ?? 0)}',
            Icons.account_balance_wallet_outlined,
            const Color(0xFF10B981),
            isWide: isWide,
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    required bool isWide,
  }) {
    return Container(
      width: isWide ? 220 : (MediaQuery.of(context).size.width - 36) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewTab(bool isWide, AppLocalizations loc) {
    final d = controller.dashboard.value;
    final alerts = d?.lowStockMaterials ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statsRow(isWide, loc),

              _sectionTitle(
                loc.section_low_stock_alerts,
                Icons.notifications_active,
              ),
              const SizedBox(height: 12),
              if (alerts.isEmpty)
                _emptyCard(loc.all_materials_above_min)
              else
                ...alerts.map(
                  (m) => _alertTile(m.name, m.currentStock, m.minStock, m.unit),
                ),
              const SizedBox(height: 24),
              _sectionTitle(loc.section_quick_actions, Icons.flash_on),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _actionChip(loc.add_raw_material, Icons.add_box, () {
                    showAddRawMaterialDialog(controller);
                  }),
                  _actionChip(loc.add_supplier, Icons.person_add, () {
                    showAddSupplierDialog(controller);
                  }),
                  _actionChip(loc.add_recipe, Icons.restaurant_menu, () {
                    showAddRecipeDialog(controller);
                  }),
                  _actionChip(loc.view_stock_log, Icons.history, () {
                    _tabController.animateTo(2);
                  }),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _infoPanel(
                      loc.todays_consumption,
                      loc.todays_consumption_units(
                        (d?.todayConsumption ?? 0).toInt(),
                      ),
                      Icons.trending_down,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoPanel(
                      loc.active_suppliers,
                      '${d?.activeSuppliers ?? 0}',
                      Icons.store,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoPanel(
                      loc.tracked_menu_items,
                      '${d?.trackedMenuItems ?? 0}',
                      Icons.restaurant_menu,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rawMaterialsTab(bool isWide, AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _toolbar(
              loc: loc,
              hint: loc.search_raw_materials,
              searchWidth: MediaQuery.of(context).size.width * 0.467,
              onSearch: (v) {
                controller.searchQuery.value = v;
                controller.loadRawMaterials();
              },
              // Increase Height of Filter Chip to match TextField
              filter: Obx(() {
                final selected = controller.showLowStockOnly.value;

                return SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      controller.showLowStockOnly.toggle();
                      controller.loadRawMaterials();
                    },
                    icon: Icon(
                      Icons.filter_alt,
                      size: 18,
                      color: selected ? Colors.white : Colors.black,
                    ),
                    label: Text(
                      loc.low_stock_only,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selected ? Colors.red : Colors.white,
                      side: BorderSide(
                        color: selected ? Colors.red : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                final list = controller.rawMaterials;
                if (list.isEmpty) {
                  return _emptyCard(loc.no_raw_materials_yet);
                }
                return isWide
                    ? _materialsTable(list, loc)
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) => _materialCard(list[i], loc),
                      );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _materialsTable(List<RawMaterialData> list, AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columns: [
            DataColumn(
              label: Text(
                loc.material_column,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            DataColumn(label: Text(loc.category)),
            DataColumn(label: Text(loc.stock)),
            DataColumn(label: Text(loc.min)),
            DataColumn(label: Text(loc.unit)),
            DataColumn(label: Text(loc.value)),
            DataColumn(label: Text(loc.status)),
            DataColumn(label: Text(loc.actions)),
          ],
          rows: list.map((m) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    _capitalizeWords(m.name),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(
                  Text(m.category.isEmpty ? '—' : _capitalizeWords(m.category)),
                ),
                DataCell(Text('${m.currentStock}')),
                DataCell(Text('${m.minStock}')),
                DataCell(Text(_capitalizeWords(m.unit))),
                DataCell(Text('₹${_fmt(m.stockValue)}')),
                DataCell(
                  _statusBadge(
                    m.isLowStock ? loc.status_low : loc.status_ok,
                    m.isLowStock,
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: loc.edit_raw_material,
                        onPressed: () =>
                            showEditRawMaterialDialog(controller, m),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note, size: 20),
                        tooltip: loc.adjust_stock_tooltip,
                        onPressed: () => showStockAdjustDialog(controller, m),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDelete(
                          m.name,
                          () => controller.deleteRawMaterial(m.id),
                          loc,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _materialCard(RawMaterialData m, AppLocalizations loc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: m.isLowStock
              ? Colors.red.shade50
              : Colors.green.shade50,
          child: Icon(
            Icons.grain,
            color: m.isLowStock ? Colors.red : Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          _capitalizeWords(m.name),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          loc.material_stock_subtitle(
            '${m.currentStock}',
            _capitalizeWords(m.unit),
            '${m.minStock}',
            _fmt(m.purchasePrice),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusBadge(
              m.isLowStock ? loc.status_low : loc.status_ok,
              m.isLowStock,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: loc.edit_raw_material,
              onPressed: () => showEditRawMaterialDialog(controller, m),
            ),
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: loc.adjust_stock_tooltip,
              onPressed: () => showStockAdjustDialog(controller, m),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockLogTab(bool isWide, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final list = controller.transactions;
        if (list.isEmpty) {
          return _emptyCard(loc.no_stock_movements);
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final t = list[i];
            final isIn =
                t.type.contains('IN') ||
                t.type == 'PURCHASE' ||
                t.type == 'RETURN';
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isIn ? Colors.green : Colors.red).withOpacity(
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isIn ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isIn ? Colors.green : Colors.red,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.materialName(t.rawMaterialId),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${t.type.replaceAll('_', ' ')} · ${t.quantity} ${loc.stock_units_suffix}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (t.notes?.isNotEmpty == true)
                          Text(
                            t.notes!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        loc.stock_change_range(
                          '${t.stockBefore ?? '—'}',
                          '${t.stockAfter ?? '—'}',
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDate(t.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _suppliersTab(bool isWide, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _toolbar(
            loc: loc,
            hint: loc.search_suppliers,
            searchController: _supplierSearchCtrl,
            onSearch: (v) {
              controller.supplierSearchQuery.value = v;
              controller.loadSuppliers();
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              final list = controller.suppliers;
              if (list.isEmpty) {
                return _emptyCard(loc.no_suppliers_yet);
              }
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: isWide ? 200 : 180,
                ),
                itemCount: list.length,
                itemBuilder: (_, i) => _supplierCard(list[i], loc),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _supplierCard(SupplierData s, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: s.isActive ? Colors.grey.shade200 : Colors.red.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _accent.withOpacity(0.15),
                child: Text(
                  s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.isActive ? loc.status_active : loc.status_inactive,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: s.isActive
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: s.isActive,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (active) =>
                    controller.setSupplierActive(s.id, active),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                tooltip: loc.actions,
                icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                onSelected: (value) {
                  if (value == 'edit') {
                    showEditSupplierDialog(controller, s);
                  } else if (value == 'delete') {
                    _confirmDelete(
                      s.name,
                      () => controller.deleteSupplier(s.id),
                      loc,
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(loc.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          loc.delete,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (s.phone?.isNotEmpty == true) _supplierRow(Icons.phone, s.phone!),
          if (s.email?.isNotEmpty == true)
            _supplierRow(Icons.email_outlined, s.email!),
          if (s.gstNumber?.isNotEmpty == true)
            _supplierRow(
              Icons.receipt_long,
              loc.gst_number_display(s.gstNumber!),
            ),
        ],
      ),
    );
  }

  Widget _supplierRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recipesTab(bool isWide, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _toolbar(
            loc: loc,
            hint: loc.search_recipes,
            onSearch: (v) => controller.recipeSearchQuery.value = v,
            onAdd: () => showAddRecipeDialog(controller),
            addLabel: loc.add_recipe,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              final grouped = controller.recipesGroupedByItem;
              if (grouped.isEmpty) {
                return _emptyCard(loc.no_recipes_yet);
              }
              final itemIds = grouped.keys.toList()
                ..sort(
                  (a, b) => controller
                      .menuItemName(a)
                      .compareTo(controller.menuItemName(b)),
                );
              return ListView.separated(
                itemCount: itemIds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final itemId = itemIds[i];
                  final lines = grouped[itemId]!;
                  final itemName = lines.first.itemName.isNotEmpty
                      ? lines.first.itemName
                      : controller.menuItemName(itemId);
                  return Container(
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: const Icon(
                          Icons.restaurant_menu,
                          color: _accent,
                          size: 22,
                        ),
                        title: Text(
                          itemName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          loc.recipe_lines_count(lines.length),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        children: lines
                            .map(
                              (r) => ListTile(
                                dense: true,
                                title: Text(r.rawMaterialName),
                                subtitle: Text(
                                  '${r.quantity} ${r.rawMaterialUnit}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                      ),
                                      tooltip: loc.edit_recipe,
                                      onPressed: () =>
                                          showEditRecipeDialog(controller, r),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () => _confirmDelete(
                                        loc.this_recipe,
                                        () => controller.deleteRecipe(r.id),
                                        loc,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Shared widgets ───────────────────────────────────────────

  Widget _toolbar({
    required AppLocalizations loc,
    String? hint,
    double? searchWidth,
    TextEditingController? searchController,
    void Function(String)? onSearch,
    VoidCallback? onAdd,
    String? addLabel,
    Widget? filter,
  }) {
    final searchField = SizedBox(
      height: 44,
      child: TextField(
        controller: searchController ?? _searchCtrl,
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: hint ?? loc.search_default_hint,
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: _cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (onSearch != null)
          searchWidth != null
              ? SizedBox(width: searchWidth, child: searchField)
              : Expanded(child: searchField),
        if (filter != null) ...[const SizedBox(width: 10), filter],
        if (onAdd != null && addLabel != null) ...[
          const SizedBox(width: 10),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: Text(addLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _alertTile(String name, double current, double min, String unit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$current / $min $unit',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _accent.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: _accent),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _infoPanel(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, bool isWarning) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isWarning ? _accent : Colors.green).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isWarning ? _accent.withOpacity(0.8) : Colors.green.shade700,
        ),
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    String name,
    Future<bool> Function() onConfirm,
    AppLocalizations loc,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(loc.confirm_delete),
        content: Text(loc.delete_confirm_message(name)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await onConfirm();
              Get.back();
            },
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }

  String _fmt(num v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);

  String _capitalizeWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return text;
    return trimmed
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
