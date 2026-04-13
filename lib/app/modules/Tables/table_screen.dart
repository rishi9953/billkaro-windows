import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Tables/table_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:get/get.dart';

class TableScreen extends StatelessWidget {
  TableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!HomeMainRoutes.outletShowsTables()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Modular.to.navigate(HomeMainRoutes.home);
      });
      return const Scaffold(
        backgroundColor: AppColor.backGroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!Get.isRegistered<TableController>()) {
      Get.put(TableController());
    }
    final controller = Get.find<TableController>();

    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    final scrollPhysics = isWindows
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();

    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Tables'),
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

        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
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
                                final maxExtent = width >= 900
                                    ? 260.0
                                    : width >= 760
                                    ? 240.0
                                    : width >= 600
                                    ? 220.0
                                    : 180.0;

                                return Scrollbar(
                                  thumbVisibility: isWindows,
                                  child: GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      16,
                                    ),
                                    physics: scrollPhysics,
                                    itemCount: filteredTables.length,
                                    gridDelegate:
                                        SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: maxExtent,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: width >= 900
                                              ? 1.15
                                              : 1.05,
                                        ),
                                    itemBuilder: (_, index) {
                                      final tws = filteredTables[index];
                                      return _TableCard(
                                        enableHover: isWindows,
                                        tableWithStatus: tws,
                                        onTap: () => controller.onTableTap(tws),
                                        onDelete: tws.isAvailable
                                            ? () => _showDeleteTableDialog(
                                                context,
                                                tws,
                                              )
                                            : null,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showAddTableDialog(BuildContext context) {
    final controller = Get.find<TableController>();
    final tableController = TextEditingController();
    final limit = controller.seatingCapacityLimit;
    final currentCount = controller.tables.length;
    final colorScheme = Theme.of(context).colorScheme;

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
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
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
    final controller = Get.find<TableController>();
    final colorScheme = Theme.of(context).colorScheme;
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
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showResetAllTablesDialog(BuildContext context) {
    final controller = Get.find<TableController>();
    final colorScheme = Theme.of(context).colorScheme;
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
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
              ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;

        final search = SizedBox(
          width: wide ? 360 : null,
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search table',
              filled: true,
              fillColor: colorScheme.surfaceVariant.withOpacity(0.22),
            ),
            onChanged: controller.setSearchQuery,
          ),
        );

        final filters = SizedBox(
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
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: wide
              ? Row(
                  children: [
                    search,
                    const SizedBox(width: 16),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: filters,
                      ),
                    ),
                  ],
                )
              : Column(children: [search, const SizedBox(height: 10), filters]),
        );
      },
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColor.primary.withOpacity(0.18),
        labelStyle: TextStyle(
          color: selected ? AppColor.primary : colorScheme.onSurfaceVariant,
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
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    final scrollPhysics = isWindows
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();
    final textColor = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withOpacity(0.7);
    final hasFilter = query.trim().isNotEmpty || filter != TableFilter.all;
    return Scrollbar(
      thumbVisibility: isWindows,
      child: ListView(
        physics: AlwaysScrollableScrollPhysics(parent: scrollPhysics),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Text(
                hasFilter
                    ? 'No tables match your search/filter'
                    : 'No tables available',
                style: TextStyle(fontSize: 15, color: textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withOpacity(0.7);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 44, color: textColor),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _TableCard extends StatefulWidget {
  final TableWithStatus tableWithStatus;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool enableHover;

  const _TableCard({
    required this.tableWithStatus,
    required this.onTap,
    this.onDelete,
    required this.enableHover,
  });

  @override
  State<_TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<_TableCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final table = widget.tableWithStatus.table;
    final colorScheme = Theme.of(context).colorScheme;

    late Color statusColor;
    late IconData icon;
    late String statusText;

    switch (widget.tableWithStatus.status) {
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

    final hovered = widget.enableHover && _hovered;
    final borderOpacity = hovered ? 0.55 : 0.35;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!widget.enableHover) return;
        setState(() => _hovered = true);
      },
      onExit: (_) {
        if (!widget.enableHover) return;
        setState(() => _hovered = false);
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: statusColor.withOpacity(0.10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statusColor.withOpacity(borderOpacity),
                width: hovered ? 1.8 : 1.4,
              ),
              color: hovered
                  ? statusColor.withOpacity(0.06)
                  : colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(hovered ? 0.10 : 0.05),
                  blurRadius: hovered ? 16 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
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
                    if (widget.onDelete != null) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Delete table',
                        child: InkWell(
                          onTap: widget.onDelete,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: colorScheme.error.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: colorScheme.error,
                              size: 16,
                            ),
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
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.tableWithStatus.isAvailable
                      ? 'Tap to create new order'
                      : 'Tap to continue order',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
                if (widget.tableWithStatus.currentOrder?.billNumber !=
                    null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Bill #${widget.tableWithStatus.currentOrder!.billNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
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
