part of '../../inventory_hub_screen.dart';

extension _InventoryRawMaterialsTab on _InventoryHubScreenState {
  Widget _rawMaterialsTab(bool isWide, AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _toolbar(
              loc: loc,
              hint: loc.search_raw_materials,
              searchWidth: MediaQuery.of(context).size.width * 0.4,
              onSearch: (v) {
                controller.searchQuery.value = v;
                controller.loadRawMaterials();
              },
              filter: Obx(() {
                final selectedDate = controller.rawMaterialDateFilter.value;
                final dateLabel = controller.rawMaterialDateFilterLabel;
                final catCount = controller.displayRawMaterialCategoryItems.length;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _inventoryCardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 18,
                            color: _inventoryAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$catCount ${catCount == 1 ? 'Category' : 'Categories'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (StaffAccess.canAdjustStock)
                      SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (!StaffAccess.ensure(
                              StaffAccess.canAdjustStock,
                            )) {
                              return;
                            }
                            controller.showQuickAddCategoryDialog();
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(loc.add_category),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _inventoryAccent,
                            side: const BorderSide(color: _inventoryAccent),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showAppDatePicker(
                            context: context,
                            initialDate: selectedDate ?? now,
                            firstDate: DateTime(now.year - 5),
                            lastDate: now,
                            helpText: 'Filter by day',
                          );
                          if (picked != null) {
                            await controller.setRawMaterialDateFilter(picked);
                          }
                        },
                        icon: Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: _inventoryAccent,
                        ),
                        label: Text(dateLabel),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _inventoryAccent,
                          side: const BorderSide(color: _inventoryAccent),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    if (controller.hasRawMaterialDateFilter) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Show all days',
                        onPressed: controller.clearRawMaterialDateFilter,
                        icon: const Icon(Icons.clear, size: 18),
                      ),
                    ],
                  ],
                );
              }),
            ),
            const SizedBox(height: 10),
            Obx(() {
              final status = controller.rawMaterialStatusFilter.value;
              Widget chip(String label, String value, Color activeColor) {
                final selected = status == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: selected,
                    label: Text(label),
                    onSelected: (_) {
                      controller.rawMaterialStatusFilter.value = value;
                      controller.showLowStockOnly.value = false;
                    },
                    selectedColor: activeColor.withOpacity(0.18),
                    checkmarkColor: activeColor,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: selected ? activeColor : Colors.black87,
                    ),
                    side: BorderSide(
                      color: selected ? activeColor : Colors.grey.shade300,
                    ),
                    backgroundColor: Colors.white,
                  ),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    chip('All', 'ALL', _inventoryAccent),
                    chip('In Stock', 'In Stock', const Color(0xFF16A34A)),
                    chip('Low Stock', 'Low Stock', const Color(0xFFEA580C)),
                    chip(
                      'Out of Stock',
                      'Out of Stock',
                      const Color(0xFFDC2626),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Obx(() {
              final items = controller.filteredRawMaterials;
              final _ = controller.rawMaterials.length;
              final __ = controller.displayRawMaterialCategoryItems.length;
              return Row(
                children: [
                  Expanded(
                    child: _productStockSummaryCard(
                      controller.rawMaterialStockValueLabel,
                      '₹${_fmt(controller.rawMaterialTotalValue)}',
                      Icons.account_balance_wallet_outlined,
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _productStockSummaryCard(
                      'Materials',
                      '${items.length}',
                      Icons.grain,
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _productStockSummaryCard(
                      'Categories',
                      '${controller.displayRawMaterialCategoryItems.length}',
                      Icons.category_outlined,
                      _inventoryAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _productStockSummaryCard(
                      'Low Stock',
                      '${controller.rawMaterialLowCount}',
                      Icons.warning_amber_rounded,
                      const Color(0xFFEA580C),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            if (!isWide) ...[
              _rawMaterialCategoriesStrip(loc),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 280,
                          child: _rawMaterialCategoriesPanel(loc),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _rawMaterialsListBody(isWide, loc)),
                      ],
                    )
                  : _rawMaterialsListBody(isWide, loc),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rawMaterialsListBody(bool isWide, AppLocalizations loc) {
    return Obx(() {
      final items = controller.filteredRawMaterials;
      final _ = controller.rawMaterials.length;
      if (controller.rawMaterials.isEmpty) {
        return _emptyCard(loc.no_raw_materials_yet);
      }
      if (items.isEmpty) {
        final dateLabel = controller.rawMaterialDateFilterLabel;
        return _emptyCard(
          controller.hasRawMaterialDateFilter
              ? 'No raw material activity on $dateLabel.'
              : 'No materials match the current filters.',
        );
      }
      if (isWide) {
        return _materialsTable(items, loc);
      }
      return ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _materialCard(items[i], loc),
      );
    });
  }

  Widget _rawMaterialCategoriesPanel(AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: _inventoryCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _inventoryAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.category_outlined,
                    size: 18,
                    color: _inventoryAccent,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Categories',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                if (StaffAccess.canAdjustStock)
                  IconButton(
                    tooltip: loc.add_category,
                    onPressed: () {
                      if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) {
                        return;
                      }
                      controller.showQuickAddCategoryDialog();
                    },
                    icon: const Icon(Icons.add_circle_outline, color: _inventoryAccent),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: Obx(() {
              final cats = controller.displayRawMaterialCategoryItems;
              final selected = controller.rawMaterialCategoryFilter.value
                  .trim();
              if (cats.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 36,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No categories yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create categories to organize raw materials',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (StaffAccess.canAdjustStock) ...[
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () {
                            if (!StaffAccess.ensure(
                              StaffAccess.canAdjustStock,
                            )) {
                              return;
                            }
                            controller.showQuickAddCategoryDialog();
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(loc.add_category),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _inventoryAccent,
                            side: const BorderSide(color: _inventoryAccent),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                children: [
                  _rawMaterialCategoryTile(
                    label: 'All categories',
                    count: controller.rawMaterials.length,
                    selected: selected.isEmpty,
                    onTap: () =>
                        controller.rawMaterialCategoryFilter.value = '',
                    showDelete: false,
                  ),
                  ...cats.map((cat) {
                    final name = cat.categoryName;
                    final count = controller.rawMaterialCountForCategory(name);
                    final isSelected =
                        selected.toLowerCase() == name.toLowerCase();
                    return _rawMaterialCategoryTile(
                      label: _capitalizeWords(name),
                      count: count,
                      selected: isSelected,
                      onTap: () {
                        controller.rawMaterialCategoryFilter.value = isSelected
                            ? ''
                            : name;
                      },
                      showDelete:
                          StaffAccess.canAdjustStock && cat.id.isNotEmpty,
                      onDelete: () => _confirmDeleteCategory(cat, loc),
                    );
                  }),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _rawMaterialCategoriesStrip(AppLocalizations loc) {
    return Obx(() {
      final cats = controller.displayRawMaterialCategoryItems;
      final selected = controller.rawMaterialCategoryFilter.value.trim();
      return SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _rawMaterialCategoryChip(
              label: 'All',
              selected: selected.isEmpty,
              onTap: () => controller.rawMaterialCategoryFilter.value = '',
            ),
            ...cats.map((cat) {
              final name = cat.categoryName;
              final isSelected = selected.toLowerCase() == name.toLowerCase();
              return _rawMaterialCategoryChip(
                label: _capitalizeWords(name),
                count: controller.rawMaterialCountForCategory(name),
                selected: isSelected,
                onTap: () {
                  controller.rawMaterialCategoryFilter.value = isSelected
                      ? ''
                      : name;
                },
              );
            }),
            if (StaffAccess.canAdjustStock)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: ActionChip(
                  avatar: const Icon(Icons.add, size: 16, color: _inventoryAccent),
                  label: Text(loc.add_category),
                  onPressed: () {
                    if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return;
                    controller.showQuickAddCategoryDialog();
                  },
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _inventoryAccent),
                  labelStyle: const TextStyle(
                    color: _inventoryAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _rawMaterialCategoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    int? count,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(count == null ? label : '$label ($count)'),
        onSelected: (_) => onTap(),
        selectedColor: _inventoryAccent.withOpacity(0.18),
        checkmarkColor: _inventoryAccent,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: selected ? _inventoryAccent : Colors.black87,
        ),
        side: BorderSide(color: selected ? _inventoryAccent : Colors.grey.shade300),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _rawMaterialCategoryTile({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
    bool showDelete = false,
    VoidCallback? onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? _inventoryAccent.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? _inventoryAccent : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? _inventoryAccent.withOpacity(0.18)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.category_outlined,
                    size: 18,
                    color: selected ? _inventoryAccent : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: selected ? _inventoryAccent : Colors.black87,
                        ),
                      ),
                      Text(
                        '$count ${count == 1 ? 'material' : 'materials'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showDelete && onDelete != null)
                  IconButton(
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red.shade400,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCategory(
    RawMaterialCategoryData cat,
    AppLocalizations loc,
  ) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text(loc.delete),
        content: Text(
          'Delete category "${_capitalizeWords(cat.categoryName)}"? Raw materials keep their category text.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.deleteRawMaterialCategoryById(cat.id);
    }
  }

  Widget _materialsTable(List<RawMaterialData> list, AppLocalizations loc) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1520
            ? 1520.0
            : constraints.maxWidth;
        return ScrollbarTheme(
          data: ScrollbarThemeData(
            thumbColor: WidgetStateProperty.all(const Color(0xFF9CA3AF)),
            trackColor: WidgetStateProperty.all(const Color(0xFFE5E7EB)),
            trackBorderColor: WidgetStateProperty.all(Colors.transparent),
            thickness: WidgetStateProperty.all(10),
            radius: const Radius.circular(8),
            crossAxisMargin: 2,
            mainAxisMargin: 4,
          ),
          child: Scrollbar(
            controller: _rawMaterialsHScrollCtrl,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SingleChildScrollView(
                controller: _rawMaterialsHScrollCtrl,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  height: constraints.maxHeight > 14
                      ? constraints.maxHeight - 14
                      : constraints.maxHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _inventoryCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text('Material', style: _headerStyle),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Category', style: _headerStyle),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Supplier', style: _headerStyle),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('SKU', style: _headerStyle),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Barcode', style: _headerStyle),
                              ),
                              Expanded(
                                child: Text('Quantity', style: _headerStyle),
                              ),
                              Expanded(child: Text('UOM', style: _headerStyle)),
                              Expanded(
                                child: Text('Rate', style: _headerStyle),
                              ),
                              Expanded(
                                child: Text('Amount', style: _headerStyle),
                              ),
                              Expanded(child: Text('Tax', style: _headerStyle)),
                              Expanded(
                                child: Text('Total', style: _headerStyle),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Status', style: _headerStyle),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Actions', style: _headerStyle),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (_, i) {
                              final m = list[i];
                              final supplier = controller
                                  .rawMaterialSupplierName(m.supplierId);
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        _capitalizeWords(m.name),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        m.category.isEmpty
                                            ? '--'
                                            : _capitalizeWords(m.category),
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        supplier.isEmpty ? '--' : supplier,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        m.materialCode.isEmpty
                                            ? '--'
                                            : m.materialCode,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        m.barcode.isEmpty ? '--' : m.barcode,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: _rawMaterialStockBadge(m)),
                                    Expanded(
                                      child: Text(
                                        _capitalizeWords(m.unit),
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '₹${_fmt(m.purchasePrice)}',
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '₹${_fmt(m.amount)}',
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        m.taxRate > 0
                                            ? '${_fmt(m.taxRate)}%'
                                            : '--',
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '₹${_fmt(m.total)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: _rawMaterialStatusText(m),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: _rawMaterialActionsMenu(m, loc),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _materialCard(RawMaterialData m, AppLocalizations loc) {
    final supplier = controller.rawMaterialSupplierName(m.supplierId);
    final inStock = m.status == 'In Stock';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: inStock
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  child: Icon(
                    Icons.grain,
                    color: inStock
                        ? const Color(0xFF166534)
                        : const Color(0xFFDC2626),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _capitalizeWords(m.name),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (m.category.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _inventoryAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _capitalizeWords(m.category),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _inventoryAccent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _rawMaterialStatusText(m),
                _rawMaterialActionsMenu(m, loc),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _productStockMeta(
                  'Supplier',
                  supplier.isEmpty ? '--' : supplier,
                ),
                _productStockMeta(
                  'SKU',
                  m.materialCode.isEmpty ? '--' : m.materialCode,
                ),
                _productStockMeta(
                  'Barcode',
                  m.barcode.isEmpty ? '--' : m.barcode,
                ),
                _productStockMeta('Quantity', _qtyLabel(m.currentStock)),
                _productStockMeta('UOM', _capitalizeWords(m.unit)),
                _productStockMeta('Rate', '₹${_fmt(m.purchasePrice)}'),
                _productStockMeta('Amount', '₹${_fmt(m.amount)}'),
                _productStockMeta(
                  'Tax',
                  m.taxRate > 0 ? '${_fmt(m.taxRate)}%' : '--',
                ),
                _productStockMeta('Total', '₹${_fmt(m.total)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rawMaterialActionsMenu(RawMaterialData m, AppLocalizations loc) {
    if (!StaffAccess.canAdjustStock) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: loc.actions,
      offset: const Offset(0, 40),
      onSelected: (value) {
        if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return;
        if (value == 'edit') {
          showEditRawMaterialDialog(controller, m);
        } else if (value == 'adjust') {
          showStockAdjustDialog(controller, m);
        } else if (value == 'delete') {
          _confirmDelete(m.name, () => controller.deleteRawMaterial(m.id), loc);
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
          value: 'adjust',
          child: Row(
            children: [
              const Icon(Icons.tune, size: 18),
              const SizedBox(width: 8),
              Text(loc.adjust_stock_tooltip),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              const SizedBox(width: 8),
              Text(loc.delete, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Icon(Icons.more_vert, color: Colors.grey.shade700, size: 22),
      ),
    );
  }

  Widget _rawMaterialStockBadge(RawMaterialData m) {
    final low = m.status != 'In Stock';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: low ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _qtyLabel(m.currentStock),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: low ? const Color(0xFFDC2626) : const Color(0xFF166534),
          ),
        ),
      ),
    );
  }

  Widget _rawMaterialStatusText(RawMaterialData m) {
    final color = m.status == 'In Stock'
        ? const Color(0xFF166534)
        : m.status == 'Low Stock'
        ? const Color(0xFFD97706)
        : const Color(0xFFDC2626);
    return Text(
      m.status,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}
