import 'package:billkaro/app/modules/Tables/table_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TableScreen extends StatelessWidget {
  TableScreen({super.key});

  final TableController controller = Get.put(TableController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Tables',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: () => _showResetAllTablesDialog(context),
            tooltip: 'Reset All Tables',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTableDialog(context),
            tooltip: 'Add Table',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refresh(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.tables.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty &&
            controller.tables.isEmpty) {
          return _ErrorState(
            message: controller.errorMessage.value,
            onRetry: controller.refresh,
          );
        }

        final filteredTables = controller.filteredTables;

        return Column(
          children: [
            _TableHeader(controller: controller),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: filteredTables.isEmpty
                    ? _EmptyState(
                        query: controller.searchQuery.value,
                        filter: controller.selectedFilter.value,
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final maxExtent = width >= 1200
                              ? 260.0
                              : width >= 900
                              ? 240.0
                              : width >= 600
                              ? 220.0
                              : 180.0;

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: filteredTables.length,
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: maxExtent,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: width >= 900 ? 1.15 : 1.05,
                                ),
                            itemBuilder: (_, index) {
                              final tws = filteredTables[index];
                              return _TableCard(
                                tableWithStatus: tws,
                                onTap: () => controller.onTableTap(tws),
                                onDelete: tws.isAvailable
                                    ? () => _showDeleteTableDialog(context, tws)
                                    : null,
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showAddTableDialog(BuildContext context) {
    final tableController = TextEditingController();
    final limit = controller.seatingCapacityLimit;
    final currentCount = controller.tables.length;

    Get.dialog(
      AlertDialog(
        title: const Text('Add Table'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              limit > 0
                  ? 'Tables: $currentCount / $limit'
                  : 'Seating capacity is not set for this outlet.',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tableController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Table number',
                hintText: 'e.g. 13 or Table 13',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final added = await controller.addTable(tableController.text);
              if (!added) return;
              if (Get.isDialogOpen == true) {
                Get.back();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTableDialog(BuildContext context, TableWithStatus tws) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Table'),
        content: Text(
          'Are you sure you want to delete ${tws.table.displayName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final deleted = await controller.deleteTable(tws);
              if (!deleted) return;
              if (Get.isDialogOpen == true) {
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showResetAllTablesDialog(BuildContext context) {
    Get.dialog(
      Builder(
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reset All Tables'),
          content: const Text(
            'This will remove all tables from this outlet. Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reset = await controller.resetAllTables();
                if (!reset) return;
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reset All'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final TableController controller;

  const _TableHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search table',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            onChanged: controller.setSearchQuery,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: controller.selectedFilter.value == TableFilter.all,
                  onTap: () => controller.setFilter(TableFilter.all),
                ),
                _FilterChip(
                  label: 'Available',
                  selected:
                      controller.selectedFilter.value == TableFilter.available,
                  onTap: () => controller.setFilter(TableFilter.available),
                ),
                _FilterChip(
                  label: 'Occupied',
                  selected:
                      controller.selectedFilter.value == TableFilter.occupied,
                  onTap: () => controller.setFilter(TableFilter.occupied),
                ),
                _FilterChip(
                  label: 'Billing',
                  selected:
                      controller.selectedFilter.value == TableFilter.billing,
                  onTap: () => controller.setFilter(TableFilter.billing),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColor.primary.withOpacity(0.18),
        labelStyle: TextStyle(
          color: selected ? AppColor.primary : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  final TableFilter filter;

  const _EmptyState({required this.query, required this.filter});

  @override
  Widget build(BuildContext context) {
    final hasFilter = query.trim().isNotEmpty || filter != TableFilter.all;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Text(
              hasFilter
                  ? 'No tables match your search/filter'
                  : 'No tables available',
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 44, color: Colors.black45),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final TableWithStatus tableWithStatus;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _TableCard({
    required this.tableWithStatus,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final table = tableWithStatus.table;

    late Color statusColor;
    late IconData icon;
    late String statusText;

    switch (tableWithStatus.status) {
      case TableStatus.available:
        statusColor = AppColor.lightgreen;
        icon = Icons.table_restaurant;
        statusText = 'Available';
        break;
      case TableStatus.billing:
        statusColor = Colors.orange;
        icon = Icons.receipt_long;
        statusText = 'Billing';
        break;
      default:
        statusColor = AppColor.secondaryPrimary;
        icon = Icons.person;
        statusText = 'Occupied';
    }

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor, width: 1.6),
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: statusColor),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                Text(
                  table.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tableWithStatus.isAvailable
                      ? 'Tap to create new order'
                      : 'Tap to continue order',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (tableWithStatus.currentOrder?.billNumber != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Bill #${tableWithStatus.currentOrder!.billNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
