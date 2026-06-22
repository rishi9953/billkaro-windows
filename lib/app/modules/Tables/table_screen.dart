import 'dart:async';

import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Tables/reserve_table_dialog.dart';
import 'package:billkaro/app/modules/Tables/table_form_dialog.dart';
import 'package:billkaro/app/modules/Tables/table_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/qr_menu_url_config.dart';
import 'package:billkaro/utils/qr_menu_url_editor.dart';
import 'package:flutter_modular/flutter_modular.dart';

class TableScreen extends StatefulWidget {
  TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
    final loc = AppLocalizations.of(context)!;

    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    final scrollPhysics = isWindows
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();

    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.promptAddTable,
        backgroundColor: AppColor.secondaryPrimary,
        foregroundColor: AppColor.white,
        elevation: 4,
        icon: Icon(Icons.add, size: 24),
        label: Text(
          loc.add_new_table,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        title: Obx(() {
          final count = controller.totalUsedSeats;
          final limit = controller.seatingCapacityLimit;
          final subtitle = limit > 0
              ? loc.tables_count_of_limit(count, limit)
              : loc.table_seats_count(count);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.tables),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColor.white.withValues(alpha: 0.82),
                ),
              ),
            ],
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.merge_type),
            onPressed: controller.openMergeTablesDialog,
            tooltip: loc.merge_tables,
          ),
          IconButton(
            icon: const Icon(Icons.event_seat),
            onPressed: () => _showReservationsSheet(context),
            tooltip: loc.reservations,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            onPressed: () => _showQrMenuOptions(context),
            tooltip: loc.qr_menu,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: () => _showResetAllTablesDialog(context),
            tooltip: loc.reset_all_tables,
          ),
          IconButton(
            tooltip: loc.refresh,
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
                  Obx(() {
                    final mergedGroups = controller.mergedTableGroupsCount;
                    if (mergedGroups <= 0) {
                      return const SizedBox.shrink();
                    }
                    return _MergedTablesBanner(
                      groupCount: mergedGroups,
                      tableCount: controller.mergedSecondaryTablesCount,
                    );
                  }),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.refresh,
                      child: filteredTables.isEmpty
                          ? _EmptyState(
                              controller: controller,
                              query: controller.searchQuery.value,
                              filter: controller.selectedFilter.value,
                              scrollController: _scrollController,
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
                                  controller: _scrollController,
                                  thumbVisibility: isWindows,
                                  child: GridView.builder(
                                    controller: _scrollController,
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
                                              ? 1.2
                                              : 1.1,
                                        ),
                                    itemBuilder: (_, index) {
                                      final tws = filteredTables[index];
                                      return _TableCard(
                                        enableHover: isWindows,
                                        tableWithStatus: tws,
                                        onTap: () => controller.onTableTap(tws),
                                        onLongPress: tws.table.hasMergedTables
                                            ? () => _showUnmergeDialog(
                                                context,
                                                tws,
                                              )
                                            : tws.isAvailable
                                            ? () => ReserveTableDialog.show(
                                                controller: controller,
                                                table: tws.table,
                                              )
                                            : null,
                                        onUnmerge: tws.table.hasMergedTables
                                            ? () => _showUnmergeDialog(
                                                context,
                                                tws,
                                              )
                                            : null,
                                        onReserve:
                                            tws.isAvailable &&
                                                !tws.table.hasMergedTables
                                            ? () => ReserveTableDialog.show(
                                                controller: controller,
                                                table: tws.table,
                                              )
                                            : null,
                                        onEdit:
                                            tws.isAvailable &&
                                                !tws.table.hasMergedTables &&
                                                tws.currentOrder == null
                                            ? () => TableFormDialog.show(
                                                controller: controller,
                                                editTable: tws.table,
                                              )
                                            : null,
                                        onQr: () => controller.showTableQr(tws.table),
                                        onDelete:
                                            tws.isAvailable &&
                                                !tws.table.hasMergedTables
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

  void _showQrMenuOptions(BuildContext context) {
    final controller = Get.find<TableController>();
    final appPref = Get.find<AppPref>();
    final menuBase = QrMenuUrlConfig.effectiveBaseUrl(appPref);
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.qr_code_2, color: AppColor.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.qr_menu,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(loc.qr_menu_description),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColor.backGroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    loc.qr_menu_current_url_base(menuBase),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          if (Get.isDialogOpen == true) Get.back();
                          await showQrMenuUrlEditor(context);
                        },
                        child: Text(loc.change_url),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          if (Get.isDialogOpen == true) Get.back();
                          await controller.generateAllQrsAndShow();
                        },
                        child: Text(loc.print_all_table_qr),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (Get.isDialogOpen == true) Get.back();
                    await controller.generateAllQrsAndPrint();
                  },
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: Text(loc.print_qr_menu),
                ),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(loc.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteTableDialog(BuildContext context, TableWithStatus tws) {
    final controller = Get.find<TableController>();
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    Get.dialog(
      AlertDialog(
        title: Text(loc.delete_table),
        content: Text(loc.delete_table_confirm_message(tws.table.displayName)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () async {
              final deleted = await controller.deleteTable(tws);
              if (!deleted) return;
              if (Get.isDialogOpen == true) {
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }

  void _showUnmergeDialog(BuildContext context, TableWithStatus tws) {
    final controller = Get.find<TableController>();
    final loc = AppLocalizations.of(context)!;
    Get.dialog(
      AlertDialog(
        title: Text(loc.unmerge_tables),
        content: Text(
          loc.unmerge_tables_confirm(tws.table.combinedDisplayName),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () async {
              final ok = await controller.unmergeTable(tws.table);
              if (ok && Get.isDialogOpen == true) Get.back();
            },
            child: Text(loc.unmerge_tables),
          ),
        ],
      ),
    );
  }

  void _showReservationsSheet(BuildContext context) {
    final controller = Get.find<TableController>();
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Get.bottomSheet(
      SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.event_seat_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.reservations,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Obx(() {
                            final count = controller.reservations.length;
                            return Text(
                              count == 0
                                  ? loc.no_reservations_today
                                  : '$count ${count == 1 ? 'reservation' : 'reservations'} today',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.55),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.onSurface.withOpacity(
                          0.06,
                        ),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // List
              Flexible(
                child: Obx(() {
                  final items = controller.reservations;

                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 48,
                            color: colorScheme.onSurface.withOpacity(0.25),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            loc.no_reservations_today,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.45),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final r = items[index];
                      final tableLabel = r.tableNumber ?? r.tableId;
                      final isWhatsApp = r.source.toLowerCase() == 'whatsapp';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            Get.back();
                            final tws = controller.tables.firstWhereOrNull(
                              (t) => t.table.id == r.tableId,
                            );
                            if (tws != null) {
                              await controller.onTableTap(tws);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant.withOpacity(
                                0.45,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Time column
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 48,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              r.reservationTime.split(':')[0],
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: colorScheme.primary,
                                                    height: 1,
                                                  ),
                                            ),
                                            Text(
                                              ':${r.reservationTime.split(':')[1]}',
                                              style: textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: colorScheme.primary
                                                        .withOpacity(0.75),
                                                    height: 1,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),

                                  // Main info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                r.customerName,
                                                style: textTheme.titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),

                                            // _WhatsAppBadge(),
                                            // ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.table_restaurant_rounded,
                                              size: 13,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.45),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Table $tableLabel',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.55),
                                                  ),
                                            ),
                                            const SizedBox(width: 10),
                                            Icon(
                                              Icons.people_outline_rounded,
                                              size: 13,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.45),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${r.partySize} guests',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.55),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Arrow
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (isWhatsApp) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF25D366,
                                            ).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xFF25D366,
                                              ).withOpacity(0.35),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,

                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  7,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF25D366,
                                                  ).withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Assets.svg.whatsapp.svg(
                                                  width: 20,
                                                  height: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'WhatsApp',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFF25D366,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.3),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _showResetAllTablesDialog(BuildContext context) {
    final controller = Get.find<TableController>();
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    Get.dialog(
      Builder(
        builder: (dialogContext) => AlertDialog(
          title: Text(loc.reset_all_tables),
          content: Text(loc.reset_all_tables_message),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
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
              child: Text(loc.reset_all),
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
    final loc = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;

        final search = SizedBox(
          width: wide ? 360 : null,
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: loc.search_table,
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
                label: loc.filter_all,
                selected: controller.selectedFilter.value == TableFilter.all,
                onTap: () => controller.setFilter(TableFilter.all),
              ),
              _FilterChip(
                label: loc.table_status_available,
                selected:
                    controller.selectedFilter.value == TableFilter.available,
                onTap: () => controller.setFilter(TableFilter.available),
              ),
              _FilterChip(
                label: loc.filter_reserved,
                selected:
                    controller.selectedFilter.value == TableFilter.reserved,
                onTap: () => controller.setFilter(TableFilter.reserved),
              ),
              _FilterChip(
                label: loc.home_occupied,
                selected:
                    controller.selectedFilter.value == TableFilter.occupied,
                onTap: () => controller.setFilter(TableFilter.occupied),
              ),
              _FilterChip(
                label: loc.home_billing,
                selected:
                    controller.selectedFilter.value == TableFilter.billing,
                onTap: () => controller.setFilter(TableFilter.billing),
              ),
              _FilterChip(
                label: loc.filter_merged,
                selected: controller.selectedFilter.value == TableFilter.merged,
                onTap: () => controller.setFilter(TableFilter.merged),
              ),
            ],
          ),
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() {
                final limit = controller.seatingCapacityLimit;
                if (limit <= 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    loc.tables_count_limit(controller.totalUsedSeats, limit),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }),
              wide
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
                  : Column(
                      children: [search, const SizedBox(height: 10), filters],
                    ),
            ],
          ),
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
  final TableController controller;
  final String query;
  final TableFilter filter;
  final ScrollController scrollController;

  const _EmptyState({
    required this.controller,
    required this.query,
    required this.filter,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    final scrollPhysics = isWindows
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();
    final textColor = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withOpacity(0.7);
    final hasFilter = query.trim().isNotEmpty || filter != TableFilter.all;

    if (hasFilter) {
      return Scrollbar(
        controller: scrollController,
        thumbVisibility: isWindows,
        child: ListView(
          controller: scrollController,
          physics: AlwaysScrollableScrollPhysics(parent: scrollPhysics),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Text(
                  loc.no_tables_match_filter,
                  style: TextStyle(fontSize: 15, color: textColor),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Obx(() {
      final limit = controller.seatingCapacityLimit;
      final canCreateAll = limit > 0 && controller.tables.isEmpty;

      return Scrollbar(
        controller: scrollController,
        thumbVisibility: isWindows,
        child: ListView(
          controller: scrollController,
          physics: AlwaysScrollableScrollPhysics(parent: scrollPhysics),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.table_restaurant_outlined,
                        size: 52,
                        color: AppColor.primary.withOpacity(0.45),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        loc.no_tables_yet,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        canCreateAll
                            ? loc.tables_count_limit(0, limit)
                            : loc.no_tables_available,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: textColor),
                      ),
                      if (canCreateAll) ...[
                        const SizedBox(height: 6),
                        Text(
                          controller.outletSeatingCapacityLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: textColor),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (canCreateAll)
                        FilledButton.icon(
                          onPressed: controller.createDefaultTablesForCapacity,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColor.secondaryPrimary,
                          ),
                          icon: const Icon(Icons.table_bar),
                          label: Text(loc.tables_count_of_limit(limit, limit)),
                        ),
                      if (canCreateAll) const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: controller.promptAddTable,
                          icon: const Icon(Icons.add),
                          label: Text(loc.add_new_table),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
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
            ElevatedButton(onPressed: onRetry, child: Text(loc.retry)),
          ],
        ),
      ),
    );
  }
}

class _MergedTablesBanner extends StatelessWidget {
  final int groupCount;
  final int tableCount;

  const _MergedTablesBanner({
    required this.groupCount,
    required this.tableCount,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColor.primary.withValues(alpha: 0.1),
              AppColor.secondaryPrimary.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.primary.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.merge_type, color: AppColor.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loc.merged_groups_banner(groupCount, tableCount),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColor.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableCard extends StatefulWidget {
  final TableWithStatus tableWithStatus;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onUnmerge;
  final VoidCallback? onReserve;
  final VoidCallback? onEdit;
  final VoidCallback onQr;
  final VoidCallback? onDelete;
  final bool enableHover;

  const _TableCard({
    required this.tableWithStatus,
    required this.onTap,
    required this.onQr,
    this.onLongPress,
    this.onUnmerge,
    this.onReserve,
    this.onEdit,
    this.onDelete,
    required this.enableHover,
  });

  @override
  State<_TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<_TableCard> {
  bool _hovered = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _TableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    final shouldRun = _occupiedStartTime != null;
    if (!shouldRun) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  DateTime? get _occupiedStartTime {
    final order = widget.tableWithStatus.currentOrder;
    if (order == null) return null;
    if (widget.tableWithStatus.status != TableStatus.occupied) return null;
    return DateTime.tryParse(order.createdAt);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final table = widget.tableWithStatus.table;
    final colorScheme = Theme.of(context).colorScheme;
    final isMerged = table.hasMergedTables;
    final totalMergedCount = 1 + table.mergedTableNumbers.length;

    late Color statusColor;
    late IconData icon;
    late String statusText;

    if (isMerged) {
      statusColor = AppColor.primary;
      icon = Icons.merge_type;
      statusText = loc.merged_tables_badge(totalMergedCount);
    } else {
      switch (widget.tableWithStatus.status) {
        case TableStatus.available:
          statusColor = AppColor.lightgreen;
          icon = Icons.table_restaurant;
          statusText = loc.table_status_available;
          break;
        case TableStatus.reserved:
          statusColor = Colors.blue;
          icon = Icons.event_seat;
          statusText = loc.table_status_reserved;
          break;
        case TableStatus.billing:
          statusColor = Colors.orange;
          icon = Icons.receipt_long;
          statusText = loc.home_billing;
          break;
        default:
          statusColor = AppColor.secondaryPrimary;
          icon = Icons.person;
          statusText = loc.home_occupied;
      }
    }

    final hovered = widget.enableHover && _hovered;
    final borderOpacity = isMerged
        ? 0.65
        : hovered
        ? 0.55
        : 0.35;
    final borderColor = isMerged ? AppColor.primary : statusColor;
    final borderWidth = isMerged
        ? 2.0
        : hovered
        ? 1.8
        : 1.4;

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
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(16),
          hoverColor: statusColor.withOpacity(0.10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor.withOpacity(borderOpacity),
                width: borderWidth,
              ),
              color: isMerged
                  ? AppColor.primary.withValues(alpha: hovered ? 0.1 : 0.06)
                  : hovered
                  ? statusColor.withOpacity(0.06)
                  : colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: isMerged
                      ? AppColor.primary.withValues(alpha: 0.12)
                      : Colors.black.withOpacity(hovered ? 0.10 : 0.05),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      loc.table_seats_count(table.seatingCapacity),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.end,
                    children: [
                      if (widget.onEdit != null)
                        _TableActionIcon(
                          tooltip: loc.edit_table,
                          icon: Icons.edit_outlined,
                          color: AppColor.primary,
                          background: AppColor.primary.withOpacity(0.12),
                          onTap: widget.onEdit!,
                        ),
                      if (widget.onReserve != null)
                        _TableActionIcon(
                          tooltip: loc.reserve_table,
                          icon: Icons.event_seat,
                          color: Colors.blue.shade700,
                          background: Colors.blue.withOpacity(0.12),
                          onTap: widget.onReserve!,
                        ),
                      if (widget.onUnmerge != null)
                        _TableActionIcon(
                          tooltip: loc.unmerge_tables,
                          icon: Icons.call_split,
                          color: AppColor.primary,
                          background: AppColor.primary.withOpacity(0.12),
                          onTap: widget.onUnmerge!,
                        ),
                      _TableActionIcon(
                        tooltip: loc.qr_menu,
                        icon: Icons.qr_code_2,
                        color: colorScheme.primary,
                        background: colorScheme.primary.withOpacity(0.12),
                        onTap: widget.onQr,
                      ),
                      if (widget.onDelete != null)
                        _TableActionIcon(
                          tooltip: loc.delete_table_tooltip,
                          icon: Icons.delete_outline,
                          color: colorScheme.error,
                          background: colorScheme.error.withOpacity(0.12),
                          onTap: widget.onDelete!,
                        ),
                    ],
                  ),
                ),
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
                if (isMerged) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _MergedTableChip(
                        label: table.displayName,
                        isPrimary: true,
                      ),
                      ...table.mergedTableNumbers.map(
                        (n) => _MergedTableChip(
                          label: n.toLowerCase().startsWith('table ')
                              ? n
                              : 'Table $n',
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                if (widget.tableWithStatus.currentOrder?.billNumber != null ||
                    _occupiedStartTime != null) ...[
                  if (widget.tableWithStatus.currentOrder?.billNumber != null)
                    Text(
                      loc.home_bill_number(
                        widget.tableWithStatus.currentOrder!.billNumber
                            .toString(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  if (_occupiedStartTime != null) ...[
                    if (widget.tableWithStatus.currentOrder?.billNumber != null)
                      const SizedBox(height: 4),
                    Text(
                      loc.home_occupied_duration(
                        _formatDuration(
                          DateTime.now().difference(_occupiedStartTime!),
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    isMerged
                        ? loc.merged_tables_hint
                        : widget.tableWithStatus.isAvailable
                        ? loc.reservation_tap_hint
                        : widget.tableWithStatus.isReserved
                        ? loc.reserved_by(
                            widget
                                    .tableWithStatus
                                    .upcomingReservation
                                    ?.customerName ??
                                '',
                            widget
                                    .tableWithStatus
                                    .upcomingReservation
                                    ?.reservationTime ??
                                '',
                          )
                        : loc.home_tap_continue_order,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
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

class _TableActionIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _TableActionIcon({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 15),
        ),
      ),
    );
  }
}

class _MergedTableChip extends StatelessWidget {
  final String label;
  final bool isPrimary;

  const _MergedTableChip({required this.label, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColor.primary.withValues(alpha: 0.18)
            : AppColor.secondaryPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimary
              ? AppColor.primary.withValues(alpha: 0.45)
              : AppColor.secondaryPrimary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPrimary) ...[
            Icon(Icons.star_rounded, size: 11, color: AppColor.primary),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isPrimary ? AppColor.primary : AppColor.secondaryPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
