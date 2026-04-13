import 'package:billkaro/app/modules/Reports/ItemReports/item_reports_controller.dart';
import 'package:billkaro/config/config.dart';

class ItemReportsScreen extends StatelessWidget {
  ItemReportsScreen({super.key});
  final controller = Get.put(ItemReportsController());

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    final scrollPhysics = isWindows
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          loc.item_Reports,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => controller.exportToExcel(),
            icon: Assets.svg.excel.svg(height: 24, width: 24),
            tooltip: 'Export to Excel',
          ),
          IconButton(
            onPressed: () => controller.exportToPdf(),
            icon: Assets.pdf.image(height: 24, width: 24),
            tooltip: 'Export to PDF',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              children: [
                // Filters Section
                _buildFiltersSection(loc, isWindows),
                // Summary Cards
                _buildSummaryCards(loc, isWindows),
                // Items List
                Expanded(
                  child: _buildItemsList(
                    loc,
                    isWindows: isWindows,
                    scrollPhysics: scrollPhysics,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- FILTERS SECTION ----------------

  Widget _buildFiltersSection(AppLocalizations loc, bool isWindows) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWindows ? 12 : 0),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Period and Date Range Row
          Row(
            children: [
              Expanded(child: _buildPeriodSelector(loc)),
              const SizedBox(width: 12),
              Expanded(child: _buildDateRangeSelector(loc)),
            ],
          ),
          const SizedBox(height: 12),
          // Category Selector
          _buildCategorySelector(loc),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(AppLocalizations loc) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterLabel(loc.period),
          const SizedBox(height: 6),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[350] ?? Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedTimePeriod.value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                items: controller.getLocalizedTimePeriods(loc).map((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      controller.getLocalizedTimePeriodLabel(value, loc),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    controller.selectedTimePeriod.value = newValue;
                    controller.filterByTimePeriod();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterLabel('Date Range'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: controller.selectCustomDateRange,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[350] ?? Colors.grey[300]!),
            ),
            child: Obx(
              () => Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.formattedDateRange,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Assets.svg.calendar.svg(
                    color: AppColor.grey,
                    height: 18,
                    width: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(AppLocalizations loc) {
    return Obx(() {
      final categories = controller.availableCategories;
      final current = controller.selectedCategory.value;
      final value = categories.contains(current) ? current : 'All';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterLabel('Category'),
          const SizedBox(height: 6),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[350] ?? Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                items: categories.map((String v) {
                  return DropdownMenuItem<String>(
                    value: v,
                    child: Text(v == 'All' ? loc.all : (v.capitalize ?? v)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    controller.selectedCategory.value = newValue;
                    controller.applyAllFilters();
                  }
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFilterLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[700],
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  // ---------------- SUMMARY CARDS ----------------

  Widget _buildSummaryCards(AppLocalizations loc, bool isWindows) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(
        () => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: isWindows ? 300 : null,
              child: _SummaryCard(
                icon: Icons.inventory_2,
                iconColor: AppColor.primary,
                value: '${controller.totalItems}',
                label: 'Total Items',
              ),
            ),
            SizedBox(
              width: isWindows ? 300 : null,
              child: _SummaryCard(
                icon: Icons.currency_rupee,
                iconColor: const Color(0xFF10B981),
                value: '₹${controller.totalAmount.toStringAsFixed(0)}',
                label: loc.total_sale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- ITEMS LIST ----------------

  Widget _buildItemsList(
    AppLocalizations loc, {
    required bool isWindows,
    required ScrollPhysics scrollPhysics,
  }) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredItemsList.isEmpty) {
        return _buildEmptyState(loc);
      }

      // Group items by name and calculate totals
      Map<String, Map<String, dynamic>> groupedItems = {};

      for (var item in controller.filteredItemsList) {
        String itemName = item.itemName;

        if (groupedItems.containsKey(itemName)) {
          groupedItems[itemName]!['quantity'] += item.quantity;
          groupedItems[itemName]!['totalAmount'] +=
              item.quantity * item.salePrice;
        } else {
          groupedItems[itemName] = {
            'quantity': item.quantity,
            'totalAmount': item.quantity * item.salePrice,
            'category': item.category,
          };
        }
      }

      final list = ListView.separated(
        physics: scrollPhysics,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: groupedItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          String itemName = groupedItems.keys.elementAt(index);
          var itemData = groupedItems[itemName]!;
          return _ItemCard(
            index: index,
            itemName: itemName,
            quantity: itemData['quantity'],
            totalAmount: itemData['totalAmount'],
            category: itemData['category'].toString().capitalizeFirst ?? '',
            loc: loc,
            compact: isWindows,
          );
        },
      );

      return RefreshIndicator(
        onRefresh: () async => controller.getItemsList(forceApiRefresh: true),
        child: Scrollbar(thumbVisibility: isWindows, child: list),
      );
    });
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/Emptybox.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Text(
            loc.no_Orders_Available,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              loc.you_havent_added_any_orders_Please_add_an_order_to_see_item_reports,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// ===================== SUMMARY CARD =====================
// =====================================================

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
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

// =====================================================
// ===================== ITEM CARD =====================
// =====================================================

class _ItemCard extends StatelessWidget {
  final int index;
  final String itemName;
  final int quantity;
  final double totalAmount;
  final String category;
  final AppLocalizations loc;
  final bool compact;

  const _ItemCard({
    required this.index,
    required this.itemName,
    required this.quantity,
    required this.totalAmount,
    required this.category,
    required this.loc,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Item Number Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 14,
                        color: AppColor.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '#${index + 1}',
                        style: TextStyle(
                          color: AppColor.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Category Badge
                if (category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Item Name
            Text(
              itemName.capitalizeFirst ?? itemName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Details Row
            Row(
              children: [
                // Quantity
                Expanded(
                  child: _InfoItem(
                    icon: Icons.shopping_cart,
                    label: loc.order_quantity,
                    value: '$quantity',
                    iconColor: AppColor.primary,
                    compact: compact,
                  ),
                ),
                // Amount
                Expanded(
                  child: _InfoItem(
                    icon: Icons.currency_rupee,
                    label: loc.order_amount,
                    value: '₹${totalAmount.toStringAsFixed(2)}',
                    iconColor: const Color(0xFF10B981),
                    compact: compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// ===================== INFO ITEM =====================
// =====================================================

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool compact;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 15 : 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }
}
