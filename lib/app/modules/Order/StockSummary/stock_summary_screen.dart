import 'dart:async';

import 'package:billkaro/app/modules/Order/StockSummary/stock_summary_controller.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/config/config.dart';

class StockSummaryScreen extends StatefulWidget {
  const StockSummaryScreen({super.key});

  @override
  State<StockSummaryScreen> createState() => _StockSummaryScreenState();
}

class _StockSummaryScreenState extends State<StockSummaryScreen> {
  late final StockSummaryController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<StockSummaryController>()
        ? Get.find<StockSummaryController>()
        : Get.put(StockSummaryController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadStock();
    });
  }

  @override
  void dispose() {
    if (Get.isRegistered<StockSummaryController>()) {
      Get.delete<StockSummaryController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          loc.stock_summary_title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => controller.loadStock(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: loc.refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 1200
                ? 1200.0
                : (constraints.maxWidth > 900 ? 1000.0 : constraints.maxWidth);
            final isWide = constraints.maxWidth >= 900;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SearchAndFilters(controller: controller, loc: loc),
                    _SummaryStrip(controller: controller, loc: loc),
                    Expanded(
                      child: _StockBody(
                        controller: controller,
                        loc: loc,
                        isWide: isWide,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchAndFilters extends StatefulWidget {
  const _SearchAndFilters({required this.controller, required this.loc});

  final StockSummaryController controller;
  final AppLocalizations loc;

  @override
  State<_SearchAndFilters> createState() => _SearchAndFiltersState();
}

class _SearchAndFiltersState extends State<_SearchAndFilters> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    widget.controller.setSearch(value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      widget.controller.loadStock(showLoader: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: loc.stock_summary_search_hint,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey.shade500,
                    ),
                    suffixIcon: Obx(() {
                      if (widget.controller.searchQuery.value.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey.shade500,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          widget.controller.setSearch('');
                          widget.controller.loadStock(showLoader: false);
                        },
                      );
                    }),
                    filled: true,
                    fillColor: AppColor.backGroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final selected = widget.controller.statusFilter.value;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: loc.all,
                  selected: selected == 'ALL',
                  onTap: () => widget.controller.setStatusFilter('ALL'),
                ),
                _FilterChip(
                  label: loc.stock_status_in_stock,
                  selected: selected == 'In Stock',
                  color: const Color(0xFF059669),
                  onTap: () => widget.controller.setStatusFilter('In Stock'),
                ),
                _FilterChip(
                  label: loc.stock_status_low_stock,
                  selected: selected == 'Low Stock',
                  color: const Color(0xFFEA580C),
                  onTap: () => widget.controller.setStatusFilter('Low Stock'),
                ),
                _FilterChip(
                  label: loc.stock_status_out_of_stock,
                  selected: selected == 'Out of Stock',
                  color: const Color(0xFFDC2626),
                  onTap: () =>
                      widget.controller.setStatusFilter('Out of Stock'),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColor.primary;
    return Material(
      color: selected ? accent.withOpacity(0.12) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent.withOpacity(0.35) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? accent : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.controller, required this.loc});

  final StockSummaryController controller;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final productCount = controller.totalCount;
      final stockValue = controller.totalStockValue;
      final inStock = controller.inStockCount;
      final lowStock = controller.lowStockCount;
      final outStock = controller.outOfStockCount;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useRow = constraints.maxWidth >= 720;
            final cards = [
              _SummaryCard(
                label: loc.stock_summary_products.capitalize ?? '',
                value: '$productCount',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF3B82F6),
              ),
              _SummaryCard(
                label: loc.stock_summary_value,
                value: '₹${_fmt(stockValue)}',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF059669),
              ),
              _SummaryCard(
                label: loc.stock_status_in_stock,
                value: '$inStock',
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF0D9488),
              ),
              _SummaryCard(
                label: loc.stock_status_low_stock,
                value: '$lowStock',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFEA580C),
              ),
              _SummaryCard(
                label: loc.stock_status_out_of_stock,
                value: '$outStock',
                icon: Icons.remove_shopping_cart_outlined,
                color: const Color(0xFFDC2626),
              ),
            ];

            if (useRow) {
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            }

            return SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => SizedBox(width: 160, child: cards[i]),
              ),
            );
          },
        ),
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockBody extends StatelessWidget {
  const _StockBody({
    required this.controller,
    required this.loc,
    required this.isWide,
  });

  final StockSummaryController controller;
  final AppLocalizations loc;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && !controller.hasLoaded.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final items = controller.filteredItems;
      if (items.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => controller.loadStock(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.45,
                child: _EmptyState(loc: loc),
              ),
            ],
          ),
        );
      }

      if (isWide) {
        return RefreshIndicator(
          onRefresh: () => controller.loadStock(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [_StockTable(items: items, loc: loc)],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadStock(),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _StockCard(item: items[index], loc: loc),
        ),
      );
    });
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            loc.stock_summary_empty,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              loc.stock_summary_empty_hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockTable extends StatelessWidget {
  const _StockTable({required this.items, required this.loc});

  final List<RawMaterialData> items;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width > 1200
                ? 1160
                : MediaQuery.sizeOf(context).width - 40,
          ),
          child: DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 64,
            headingRowColor: WidgetStateProperty.all(
              AppColor.backGroundColor.withOpacity(0.7),
            ),
            columns: [
              DataColumn(
                label: Text(loc.stock_summary_products, style: _headerStyle),
              ),
              DataColumn(label: Text('UOM', style: _headerStyle)),
              DataColumn(
                label: Text(loc.stock_summary_qty, style: _headerStyle),
              ),
              DataColumn(
                label: Text(loc.stock_summary_min, style: _headerStyle),
              ),
              DataColumn(
                label: Text(loc.stock_summary_rate, style: _headerStyle),
              ),
              DataColumn(
                label: Text(loc.stock_summary_value, style: _headerStyle),
              ),
              DataColumn(label: Text(loc.status, style: _headerStyle)),
            ],
            rows: [
              for (final item in items)
                DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.name.capitalize ?? item.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.category.isNotEmpty)
                            Text(
                              item.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        item.unit,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        ('${_qtyLabel(item.currentStock)} ${item.unit}').trim(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(item.status),
                        ),
                      ),
                    ),
                    DataCell(Text(_qtyLabel(item.minStock))),
                    DataCell(Text('₹${_fmt(item.purchasePrice)}')),
                    DataCell(
                      Text(
                        '₹${_fmt(item.stockValue)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(_StatusBadge(status: item.status, loc: loc)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.loc});

  final String status;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status, loc),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({required this.item, required this.loc});

  final RawMaterialData item;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusBadge(status: item.status, loc: loc),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetaTile(
                  label: loc.stock_summary_qty,
                  value: ('${_qtyLabel(item.currentStock)} ${item.unit}')
                      .trim(),
                  valueColor: statusColor,
                ),
              ),
              Expanded(
                child: _MetaTile(
                  label: loc.stock_summary_min,
                  value: _qtyLabel(item.minStock),
                ),
              ),
              Expanded(
                child: _MetaTile(
                  label: loc.stock_summary_rate,
                  value: '₹${_fmt(item.purchasePrice)}',
                ),
              ),
              Expanded(
                child: _MetaTile(
                  label: loc.stock_summary_value,
                  value: '₹${_fmt(item.stockValue)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? Colors.grey.shade900,
          ),
        ),
      ],
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'Low Stock':
      return const Color(0xFFEA580C);
    case 'Out of Stock':
      return const Color(0xFFDC2626);
    default:
      return const Color(0xFF059669);
  }
}

String _statusLabel(String status, AppLocalizations loc) {
  switch (status) {
    case 'Low Stock':
      return loc.stock_status_low_stock;
    case 'Out of Stock':
      return loc.stock_status_out_of_stock;
    default:
      return loc.stock_status_in_stock;
  }
}

String _qtyLabel(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _fmt(double value) {
  if (value >= 100000) return value.toStringAsFixed(0);
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}
