import 'package:billkaro/app/modules/OwnerPanel/models/outlet_metrics.dart';
import 'package:billkaro/app/modules/OwnerPanel/owner_panel_controller.dart';
import 'package:billkaro/config/config.dart';

class OwnerFilterBar extends StatelessWidget {
  const OwnerFilterBar({super.key, required this.controller});

  final OwnerPanelController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final outlets = controller.outlets;
      final types = controller.businessTypeOptions;
      final hasFilters = controller.hasActiveFilters;

      return Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.cardBorder.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: AppColor.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),
                if (hasFilters)
                  TextButton(
                    onPressed: controller.clearFilters,
                    child: const Text('Clear all'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(
                    label: 'Today',
                    selected: controller.selectedRange.value == OwnerDashRange.today,
                    onTap: () => controller.setRange(OwnerDashRange.today),
                  ),
                  _chip(
                    label: '7 days',
                    selected: controller.selectedRange.value == OwnerDashRange.week,
                    onTap: () => controller.setRange(OwnerDashRange.week),
                  ),
                  _chip(
                    label: '30 days',
                    selected:
                        controller.selectedRange.value == OwnerDashRange.month,
                    onTap: () => controller.setRange(OwnerDashRange.month),
                  ),
                  _divider(),
                  _chip(
                    label: 'All status',
                    selected:
                        controller.statusFilter.value == OwnerStatusFilter.all,
                    onTap: () =>
                        controller.setStatusFilter(OwnerStatusFilter.all),
                  ),
                  _chip(
                    label: 'Low stock',
                    selected: controller.statusFilter.value ==
                        OwnerStatusFilter.lowStock,
                    onTap: () =>
                        controller.setStatusFilter(OwnerStatusFilter.lowStock),
                    accent: AppColor.warning,
                  ),
                  _chip(
                    label: 'Low wallet',
                    selected: controller.statusFilter.value ==
                        OwnerStatusFilter.lowWallet,
                    onTap: () =>
                        controller.setStatusFilter(OwnerStatusFilter.lowWallet),
                    accent: AppColor.error,
                  ),
                  _chip(
                    label: 'Expiring sub',
                    selected: controller.statusFilter.value ==
                        OwnerStatusFilter.expiringSub,
                    onTap: () => controller
                        .setStatusFilter(OwnerStatusFilter.expiringSub),
                    accent: AppColor.secondaryPrimary,
                  ),
                  _chip(
                    label: 'No / expired sub',
                    selected: controller.statusFilter.value ==
                        OwnerStatusFilter.inactiveSub,
                    onTap: () => controller
                        .setStatusFilter(OwnerStatusFilter.inactiveSub),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DropdownShell(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        isExpanded: true,
                        value: controller.selectedOutletFilterId.value,
                        hint: const Text('All outlets', style: _ddStyle),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All outlets', style: _ddStyle),
                          ),
                          ...outlets
                              .where((o) => (o.id ?? '').isNotEmpty)
                              .map(
                                (o) => DropdownMenuItem<String?>(
                                  value: o.id,
                                  child: Text(
                                    (o.businessName ?? 'Outlet').trim(),
                                    style: _ddStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                        ],
                        onChanged: controller.setOutletFilter,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DropdownShell(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: controller.selectedBusinessType.value.isEmpty
                            ? ''
                            : controller.selectedBusinessType.value,
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('All types', style: _ddStyle),
                          ),
                          ...types.map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t, style: _ddStyle),
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            controller.setBusinessType(v ?? ''),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DropdownShell(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<OwnerSortBy>(
                        isExpanded: true,
                        value: controller.sortBy.value,
                        items: const [
                          DropdownMenuItem(
                            value: OwnerSortBy.salesHigh,
                            child: Text('Sales ↓', style: _ddStyle),
                          ),
                          DropdownMenuItem(
                            value: OwnerSortBy.salesLow,
                            child: Text('Sales ↑', style: _ddStyle),
                          ),
                          DropdownMenuItem(
                            value: OwnerSortBy.nameAz,
                            child: Text('Name A–Z', style: _ddStyle),
                          ),
                          DropdownMenuItem(
                            value: OwnerSortBy.lowStock,
                            child: Text('Low stock', style: _ddStyle),
                          ),
                          DropdownMenuItem(
                            value: OwnerSortBy.walletLow,
                            child: Text('Wallet low', style: _ddStyle),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) controller.setSortBy(v);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: controller.onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search outlets, GSTIN, address…',
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: controller.searchQuery.value.isEmpty
                    ? null
                    : IconButton(
                        onPressed: controller.clearSearch,
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                filled: true,
                fillColor: const Color(0xFFF7F4EF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _divider() => Container(
        width: 1,
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.grey.shade300,
      );

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? accent,
  }) {
    final color = accent ?? AppColor.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

const _ddStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

class _DropdownShell extends StatelessWidget {
  const _DropdownShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}
