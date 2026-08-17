part of '../../inventory_hub_screen.dart';

extension _InventoryProductStockTab on _InventoryHubScreenState {
  Widget _productStockTab(bool isWide, AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _toolbar(
              loc: loc,
              hint: 'Search Item Stock',
              searchWidth: MediaQuery.of(context).size.width * 0.4,
              onSearch: (v) {
                controller.productStockSearch.value = v;
                controller.loadProductStock();
              },
              filter: Obx(() {
                // Ensure Obx tracks full category list from outlet + stock.
                final _ = controller.categories.length;
                final selectedCount =
                    controller.productStockItemIdFilter.length;
                final cats = controller.productStockCategories;
                final selectedCat = controller.productStockCategoryFilter.value;
                final catValue = cats.contains(selectedCat) ? selectedCat : '';
                if (selectedCat.isNotEmpty && catValue.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    controller.productStockCategoryFilter.value = '';
                  });
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SearchableCategoryDropdown(
                      categories: cats,
                      value: catValue,
                      includeAllOption: true,
                      allOptionLabel: 'All categories',
                      label: 'Category',
                      width: 200,
                      height: 44,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        filled: true,
                        fillColor: _inventoryCardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onChanged: (v) {
                        controller.productStockCategoryFilter.value = v ?? '';
                      },
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            showProductStockItemFilterDialog(controller),
                        icon: Badge(
                          isLabelVisible: selectedCount > 0,
                          label: Text('$selectedCount'),
                          child: const Icon(Icons.filter_list, size: 18),
                        ),
                        label: Text(
                          selectedCount > 0
                              ? 'Items ($selectedCount)'
                              : 'Filter Items',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: selectedCount > 0
                              ? _inventoryAccent
                              : Colors.grey.shade800,
                          side: BorderSide(
                            color: selectedCount > 0
                                ? _inventoryAccent
                                : Colors.grey.shade300,
                          ),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    if (selectedCount > 0) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Clear item filter',
                        onPressed: controller.clearProductStockItemFilter,
                        icon: const Icon(Icons.clear, size: 18),
                      ),
                    ],
                  ],
                );
              }),
            ),
            const SizedBox(height: 10),
            Obx(() {
              final status = controller.productStockStatusFilter.value;
              Widget chip(String label, String value, Color activeColor) {
                final selected = status == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: selected,
                    label: Text(label),
                    onSelected: (_) {
                      controller.productStockStatusFilter.value = value;
                      controller.showProductLowStockOnly.value = false;
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
              final items = controller.filteredProductStock;
              // Touch productStock so Obx rebuilds when list loads
              final _ = controller.productStock.length;
              final selectedCount = controller.productStockItemIdFilter.length;
              final totalValue = controller.productStockTotalValue;
              final lowCount = controller.productStockLowCount;
              final outCount = controller.productStockOutCount;
              return Row(
                children: [
                  Expanded(
                    child: _productStockSummaryCard(
                      selectedCount > 0
                          ? 'Selected Value'
                          : 'Total Stock Value',
                      '₹${_fmt(totalValue)}',
                      Icons.account_balance_wallet_outlined,
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _productStockSummaryCard(
                      selectedCount > 0 ? 'Selected Products' : 'Products',
                      '${items.length}',
                      Icons.inventory_2_outlined,
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _productStockSummaryCard(
                      'Low Stock',
                      '$lowCount',
                      Icons.warning_amber_rounded,
                      const Color(0xFFEA580C),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _productStockSummaryCard(
                      'Out of Stock',
                      '$outCount',
                      Icons.remove_shopping_cart_outlined,
                      const Color(0xFFDC2626),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                final items = controller.filteredProductStock;
                final _ = controller.productStock.length;
                if (controller.productStock.isEmpty) {
                  return _emptyCard(
                    'No Item Stock yet. Tap Add Item Stock to add stock for a menu item.',
                  );
                }
                if (items.isEmpty) {
                  return _emptyCard('No items match the selected filters.');
                }
                if (isWide) {
                  return _productStockTable(items, loc);
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _productStockCard(item, loc);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productStockSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _inventoryCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
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
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productStockTable(
    List<ProductStockData> items,
    AppLocalizations loc,
  ) {
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
            controller: _productStockHScrollCtrl,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SingleChildScrollView(
                controller: _productStockHScrollCtrl,
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
                                child: Text('Item Name', style: _headerStyle),
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
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (_, i) {
                              final item = items[i];
                              final thumb = parseHexColor(item.posColor);
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: SizedBox(
                                              width: 36,
                                              height: 36,
                                              child: item.itemImage.isNotEmpty
                                                  ? AppCachedNetworkImage(
                                                      imageUrl: item.itemImage,
                                                      fit: BoxFit.cover,
                                                      errorWidget:
                                                          (
                                                            _,
                                                            __,
                                                            ___,
                                                          ) => ColoredBox(
                                                            color:
                                                                thumb ??
                                                                Colors
                                                                    .grey
                                                                    .shade300,
                                                          ),
                                                    )
                                                  : ColoredBox(
                                                      color:
                                                          thumb ??
                                                          Colors.grey.shade300,
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              item.itemName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        item.category.isEmpty
                                            ? '--'
                                            : item.category,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        item.supplierName.isEmpty
                                            ? '--'
                                            : item.supplierName,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        item.sku.isEmpty ? '--' : item.sku,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        item.barcode.isEmpty
                                            ? '--'
                                            : item.barcode,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: _stockBadge(item)),
                                    Expanded(
                                      child: Text(
                                        '₹${_fmt(item.rate)}',
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '₹${_fmt(item.amount)}',
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        item.taxPercent > 0
                                            ? '${_fmt(item.taxPercent)}%'
                                            : '--',
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '₹${_fmt(item.total)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(flex: 2, child: _statusText(item)),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: _productStockActionsMenu(
                                          item,
                                          loc,
                                        ),
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

  Widget _productStockCard(ProductStockData item, AppLocalizations loc) {
    final thumb = parseHexColor(item.posColor);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: item.itemImage.isNotEmpty
                        ? AppCachedNetworkImage(
                            imageUrl: item.itemImage,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => ColoredBox(
                              color: thumb ?? Colors.grey.shade300,
                            ),
                          )
                        : ColoredBox(color: thumb ?? Colors.grey.shade300),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.itemName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _statusText(item),
                _productStockActionsMenu(item, loc),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _productStockMeta(
                  'Category',
                  item.category.isEmpty ? '--' : item.category,
                ),
                _productStockMeta(
                  'Supplier',
                  item.supplierName.isEmpty ? '--' : item.supplierName,
                ),
                _productStockMeta('SKU', item.sku.isEmpty ? '--' : item.sku),
                _productStockMeta(
                  'Barcode',
                  item.barcode.isEmpty ? '--' : item.barcode,
                ),
                _productStockMeta('Quantity', _qtyLabel(item.stockQuantity)),
                _productStockMeta('Rate', '₹${_fmt(item.rate)}'),
                _productStockMeta('Amount', '₹${_fmt(item.amount)}'),
                _productStockMeta(
                  'Tax',
                  item.taxPercent > 0 ? '${_fmt(item.taxPercent)}%' : '--',
                ),
                _productStockMeta('Total', '₹${_fmt(item.total)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _productStockActionsMenu(ProductStockData item, AppLocalizations loc) {
    if (!StaffAccess.canAdjustStock) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: loc.actions,
      offset: const Offset(0, 40),
      onSelected: (value) {
        if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return;
        if (value == 'edit') {
          showEditProductStockDrawer(controller, item);
        } else if (value == 'adjust') {
          showAdjustProductStockDialog(controller, item);
        } else if (value == 'delete') {
          _confirmDelete(
            item.itemName,
            () => controller.deleteProductStock(item.id),
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
        const PopupMenuItem(
          value: 'adjust',
          child: Row(
            children: [
              Icon(Icons.tune, size: 18),
              SizedBox(width: 8),
              Text('Adjust Stock'),
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

  Widget _productStockMeta(String label, String value) {
    return SizedBox(
      width: 120,
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
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _qtyLabel(double qty) => qty == qty.roundToDouble()
      ? qty.toInt().toString()
      : qty.toStringAsFixed(2);

  Widget _stockBadge(ProductStockData item) {
    final low = item.status == 'Low Stock' || item.status == 'Out of Stock';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: low ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          item.stockQuantity == item.stockQuantity.roundToDouble()
              ? item.stockQuantity.toInt().toString()
              : item.stockQuantity.toStringAsFixed(2),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: low ? const Color(0xFFDC2626) : const Color(0xFF166534),
          ),
        ),
      ),
    );
  }

  Widget _statusText(ProductStockData item) {
    final color = item.status == 'In Stock'
        ? const Color(0xFF166534)
        : item.status == 'Low Stock'
        ? const Color(0xFFD97706)
        : const Color(0xFFDC2626);
    return Text(
      item.status,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }

}
