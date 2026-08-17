part of '../../inventory_hub_screen.dart';

extension _InventoryStockLogTab on _InventoryHubScreenState {
  Widget _stockLogTab(bool isWide, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _toolbar(
            loc: loc,
            hint: 'Search by material, type, notes...',
            searchController: _stockLogSearchCtrl,
            searchWidth: MediaQuery.of(context).size.width * 0.35,
            onSearch: (v) => controller.stockLogSearchQuery.value = v,
            filter: Obx(() {
              final materials = controller.rawMaterials.toList()
                ..sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );
              final selectedMaterial =
                  controller.stockLogMaterialIdFilter.value;
              final materialValue =
                  materials.any((m) => m.id == selectedMaterial)
                  ? selectedMaterial
                  : '';
              if (selectedMaterial.isNotEmpty && materialValue.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.stockLogMaterialIdFilter.value = '';
                });
              }
              final dateLabel = controller.stockLogDateFilterLabel;
              final hasFilters = controller.hasStockLogFilters;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: isWide ? 220 : 180,
                    height: 44,
                    child: AppDropdownFormField2<String>(
                      value: materialValue,
                      isExpanded: true,
                      hint: const Text('All materials'),
                      decoration: InputDecoration(
                        labelText: 'Material',
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
                      items: [
                        const DropdownItem(
                          value: '',
                          child: Text('All materials'),
                        ),
                        ...materials.map(
                          (m) => DropdownItem(
                            value: m.id,
                            child: Text(
                              m.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        controller.stockLogMaterialIdFilter.value = v ?? '';
                      },
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
                          initialDate:
                              controller.stockLogDateFilter.value ?? now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: now,
                          helpText: 'Filter stock log by day',
                        );
                        if (picked != null) {
                          controller.setStockLogDateFilter(picked);
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
                  if (controller.hasStockLogDateFilter) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Show all days',
                      onPressed: controller.clearStockLogDateFilter,
                      icon: const Icon(Icons.clear, size: 18),
                    ),
                  ],
                  if (hasFilters) ...[
                    const SizedBox(width: 6),
                    TextButton.icon(
                      onPressed: () {
                        controller.clearStockLogFilters();
                        _stockLogSearchCtrl.clear();
                      },
                      icon: const Icon(Icons.filter_alt_off, size: 16),
                      label: const Text('Clear filters'),
                      style: TextButton.styleFrom(foregroundColor: _inventoryAccent),
                    ),
                  ],
                ],
              );
            }),
          ),
          const SizedBox(height: 10),
          Obx(() {
            final direction = controller.stockLogDirectionFilter.value;
            Widget chip(String label, String value, Color activeColor) {
              final selected = direction == value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: selected,
                  label: Text(label),
                  onSelected: (_) =>
                      controller.stockLogDirectionFilter.value = value,
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
                  chip('Stock In', 'IN', const Color(0xFF16A34A)),
                  chip('Stock Out', 'OUT', const Color(0xFFDC2626)),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Obx(() {
            final type = controller.stockLogTypeFilter.value;
            Widget chip(String label, String value, Color activeColor) {
              final selected = type == value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: selected,
                  label: Text(label),
                  onSelected: (_) =>
                      controller.stockLogTypeFilter.value = value,
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
                  chip('All types', 'ALL', _inventoryAccent),
                  chip('Purchase', 'PURCHASE', const Color(0xFF2563EB)),
                  chip('Sale', 'SALE', const Color(0xFFDC2626)),
                  chip('Wastage', 'WASTAGE', const Color(0xFFEA580C)),
                  chip('Adjust In', 'ADJUSTMENT_IN', const Color(0xFF16A34A)),
                  chip('Adjust Out', 'ADJUSTMENT_OUT', const Color(0xFFB91C1C)),
                  chip('Return', 'RETURN', const Color(0xFF0891B2)),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Obx(() {
            final list = controller.filteredTransactions;
            final _ = controller.transactions.length;
            return Row(
              children: [
                Expanded(
                  child: _productStockSummaryCard(
                    'Movements',
                    '${list.length}',
                    Icons.history,
                    const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _productStockSummaryCard(
                    'Stock In',
                    '${controller.stockLogInCount}',
                    Icons.arrow_downward,
                    const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _productStockSummaryCard(
                    'Stock Out',
                    '${controller.stockLogOutCount}',
                    Icons.arrow_upward,
                    const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _productStockSummaryCard(
                    controller.hasStockLogDateFilter
                        ? controller.stockLogDateFilterLabel
                        : 'Period',
                    controller.hasStockLogDateFilter ? 'Filtered' : 'All days',
                    Icons.calendar_today_outlined,
                    _inventoryAccent,
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              final all = controller.transactions;
              final list = controller.filteredTransactions;
              if (all.isEmpty) {
                return _emptyCard(loc.no_stock_movements);
              }
              if (list.isEmpty) {
                return _emptyCard(
                  'No stock movements match the selected filters.',
                );
              }
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final t = list[i];
                  final isIn = InventoryController.isStockInType(t.type);
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _inventoryCardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isIn ? Colors.green : Colors.red)
                                .withOpacity(0.1),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${t.type.replaceAll('_', ' ')} · ${t.quantity} ${loc.stock_units_suffix}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (t.reference?.isNotEmpty == true)
                                Text(
                                  t.reference!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              if (t.notes?.isNotEmpty == true)
                                Text(
                                  t.notes!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (isIn ? Colors.green : Colors.red)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isIn ? 'IN' : 'OUT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isIn
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
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
          ),
        ],
      ),
    );
  }
}
