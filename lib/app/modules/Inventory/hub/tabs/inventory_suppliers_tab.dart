part of '../../inventory_hub_screen.dart';

extension _InventorySuppliersTab on _InventoryHubScreenState {
  Widget _suppliersTab(bool isWide, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _toolbar(
            loc: loc,
            hint: loc.search_suppliers,
            searchController: _supplierSearchCtrl,
            searchWidth: MediaQuery.of(context).size.width * 0.35,
            onSearch: (v) => controller.supplierSearchQuery.value = v,
            filter: Obx(() {
              final dateLabel = controller.supplierDateFilterLabel;
              final hasFilters = controller.hasSupplierFilters;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showAppDatePicker(
                          context: context,
                          initialDate:
                              controller.supplierDateFilter.value ?? now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: now,
                          helpText: 'Filter suppliers by day',
                        );
                        if (picked != null) {
                          controller.setSupplierDateFilter(picked);
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
                  if (controller.hasSupplierDateFilter) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Show all days',
                      onPressed: controller.clearSupplierDateFilter,
                      icon: const Icon(Icons.clear, size: 18),
                    ),
                  ],
                  if (hasFilters) ...[
                    const SizedBox(width: 6),
                    TextButton.icon(
                      onPressed: () {
                        controller.clearSupplierFilters();
                        _supplierSearchCtrl.clear();
                      },
                      icon: const Icon(Icons.filter_alt_off, size: 16),
                      label: const Text('Clear filters'),
                      style: TextButton.styleFrom(
                        foregroundColor: _inventoryAccent,
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
          const SizedBox(height: 10),
          Obx(() {
            final status = controller.supplierStatusFilter.value;
            Widget chip(String label, String value, Color activeColor) {
              final selected = status == value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: selected,
                  label: Text(label),
                  onSelected: (_) =>
                      controller.supplierStatusFilter.value = value,
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
                  chip('Active', 'ACTIVE', const Color(0xFF16A34A)),
                  chip('Inactive', 'INACTIVE', const Color(0xFFDC2626)),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Obx(() {
            final list = controller.filteredSuppliers;
            final _ = controller.suppliers.length;
            return Row(
              children: [
                Expanded(
                  child: _productStockSummaryCard(
                    'Suppliers',
                    '${list.length}',
                    Icons.local_shipping_outlined,
                    const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _productStockSummaryCard(
                    'Active',
                    '${controller.supplierActiveCount}',
                    Icons.check_circle_outline,
                    const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _productStockSummaryCard(
                    'Inactive',
                    '${controller.supplierInactiveCount}',
                    Icons.pause_circle_outline,
                    const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _productStockSummaryCard(
                    controller.hasSupplierDateFilter
                        ? controller.supplierDateFilterLabel
                        : 'Period',
                    controller.hasSupplierDateFilter ? 'Filtered' : 'All days',
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
              final allEmpty = controller.suppliers.isEmpty;
              final list = controller.filteredSuppliers;
              if (allEmpty) {
                return _emptyCard(loc.no_suppliers_yet);
              }
              if (list.isEmpty) {
                return _emptyCard('No suppliers match the selected filters.');
              }
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: isWide ? 210 : 190,
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
        color: _inventoryCardBg,
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
                backgroundColor: _inventoryAccent.withOpacity(0.15),
                child: Text(
                  s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    color: _inventoryAccent,
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
                      s.name.capitalize ?? '',
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
                onChanged: StaffAccess.canAdjustStock
                    ? (active) {
                        if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) {
                          return;
                        }
                        controller.setSupplierActive(s.id, active);
                      }
                    : null,
              ),
              if (StaffAccess.canAdjustStock)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  tooltip: loc.actions,
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                  onSelected: (value) {
                    if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) {
                      return;
                    }
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
          if (s.displayAddress.isNotEmpty)
            _supplierRow(Icons.location_on_outlined, s.displayAddress),
          if (s.gstNumber?.isNotEmpty == true)
            _supplierRow(
              Icons.receipt_long,
              loc.gst_number_display(s.gstNumber!),
            ),
          if (s.displayCompany.isNotEmpty)
            _supplierRow(
              Icons.business_outlined,
              s.displayCompany.capitalize ?? '',
            ),
          if (s.createdAt != null)
            _supplierRow(
              Icons.calendar_today_outlined,
              _formatDate(s.createdAt!.toIso8601String()),
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
}
