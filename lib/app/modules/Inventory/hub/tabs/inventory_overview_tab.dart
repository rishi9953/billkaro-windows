part of '../../inventory_hub_screen.dart';

extension _InventoryOverviewTab on _InventoryHubScreenState {
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
        color: _inventoryCardBg,
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
                  if (StaffAccess.canAdjustStock)
                    _actionChip(loc.add_raw_material, Icons.add_box, () {
                      if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) {
                        return;
                      }
                      showAddRawMaterialDialog(controller);
                    }),
                  if (StaffAccess.canAdjustStock)
                    _actionChip(loc.add_supplier, Icons.person_add, () {
                      if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) {
                        return;
                      }
                      showAddSupplierDialog(controller);
                    }),
                  if (StaffAccess.canAdjustStock)
                    _actionChip(loc.add_recipe, Icons.restaurant_menu, () {
                      if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) {
                        return;
                      }
                      showAddRecipeDialog(controller);
                    }),
                  _actionChip(loc.view_stock_log, Icons.history, () {
                    _tabController.animateTo(2);
                  }),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  'Stock tracks raw materials. Link recipes to menu items so sales deduct ingredients automatically.',
                  style: TextStyle(fontSize: 13, height: 1.35),
                ),
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
                    child: InkWell(
                      onTap: () => _tabController.animateTo(1),
                      borderRadius: BorderRadius.circular(12),
                      child: _infoPanel(
                        'Raw Materials',
                        '${d?.totalRawMaterials ?? 0}',
                        Icons.inventory_2,
                        Colors.green,
                      ),
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
}
