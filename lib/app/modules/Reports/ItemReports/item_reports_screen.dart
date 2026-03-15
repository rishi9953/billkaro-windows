import 'package:billkaro/app/modules/Reports/ItemReports/item_reports_controller.dart';
import 'package:billkaro/config/config.dart';

class ItemReportsScreen extends StatelessWidget {
  ItemReportsScreen({super.key});
  final controller = Get.put(ItemReportsController());

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;
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
      body: Column(
        children: [
          // Filters Section
          _buildFiltersSection(loc),

          // Summary Cards
          _buildSummaryCards(loc),

          // Items List
          Expanded(child: _buildItemsList(loc)),
        ],
      ),
    );
  }

  // ---------------- FILTERS SECTION ----------------

  Widget _buildFiltersSection(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
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
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
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
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
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

  Widget _buildSummaryCards(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.inventory_2,
                iconColor: AppColor.primary,
                value: '${controller.totalItems}',
                label: 'Total Items',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
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

  Widget _buildItemsList(AppLocalizations loc) {
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
        String itemName = item.itemName ?? loc.unknown_item;

        if (groupedItems.containsKey(itemName)) {
          groupedItems[itemName]!['quantity'] += item.quantity ?? 0;
          groupedItems[itemName]!['totalAmount'] +=
              (item.quantity ?? 0) * (item.salePrice ?? 0);
        } else {
          groupedItems[itemName] = {
            'quantity': item.quantity ?? 0,
            'totalAmount': (item.quantity ?? 0) * (item.salePrice ?? 0),
            'category': item.category ?? '',
          };
        }
      }

      return RefreshIndicator(
        onRefresh: () async => controller.getItemsList(forceApiRefresh: true),
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
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
            );
          },
        ),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
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

  const _ItemCard({
    required this.index,
    required this.itemName,
    required this.quantity,
    required this.totalAmount,
    required this.category,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                fontSize: 18,
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
                  ),
                ),
                // Amount
                Expanded(
                  child: _InfoItem(
                    icon: Icons.currency_rupee,
                    label: loc.order_amount,
                    value: '₹${totalAmount.toStringAsFixed(2)}',
                    iconColor: const Color(0xFF10B981),
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

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
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
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }
}
