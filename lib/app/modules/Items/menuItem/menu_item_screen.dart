import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/Widgets/horizontal_scroll_with_arrows.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/responsive.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:shimmer/shimmer.dart';

String? _resolveItemImageUrl(String raw) {
  final url = resolvedMediaUrl(raw);
  return url.isEmpty ? null : url;
}

int _menuItemGridColumns(double availableWidth) {
  if (availableWidth < 1100) return 2;
  return (availableWidth / 320).floor().clamp(3, 4);
}

bool _menuItemUseCompactCard(double tileWidth) => tileWidth < 340;

double _menuItemGridAspectRatio({
  required double tileWidth,
  required bool compact,
}) {
  if (compact) {
    return tileWidth / (tileWidth * 0.72 + 88);
  }
  return (tileWidth / 112).clamp(2.0, 4.5);
}

class MenuItemScreen extends StatefulWidget {
  MenuItemScreen({super.key});

  @override
  State<MenuItemScreen> createState() => _MenuItemScreenState();
}

class _MenuItemScreenState extends State<MenuItemScreen> {
  final controller = Get.put(MenuItemController());
  final ScrollController scrollController = ScrollController();
  final ScrollController categoriesScrollController = ScrollController();

  bool _isWindows(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   checkDeveloperOptionsAndShowSheet();
    // });
  }

  void _setupScrollListener() {
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Load more when not searching (category filter is handled by the API)
    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 300) {
      if (controller.searchQuery.value.isEmpty) {
        controller.loadMoreItems();
      }
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    categoriesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isTablet = Responsive.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 950;
    final contentMaxWidth = isDesktop ? 1100.0 : double.infinity;

    return Obx(() {
      // Show loader until first fetch completes
      if (!controller.initialLoadDone.value &&
          controller.allItems.isEmpty &&
          controller.categories.isEmpty) {
        return Scaffold(
          backgroundColor: AppColor.backGroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppColor.primary,
            title: Text(
              loc.menu_items,
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: Colors.white,
              ),
            ),
            actions: [
              // Refresh
              IconButton(
                tooltip: loc.refresh,
                onPressed: controller.refreshItems,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                ),
                SizedBox(height: isTablet ? 24 : 16),
                Text(
                  loc.loading_menu,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Empty state when no items/categories after load
      // if (controller.allItems.isEmpty || controller.categories.isEmpty) {
      //   return ItemDetailsScreen();
      // }

      return Scaffold(
        backgroundColor: AppColor.backGroundColor,
        appBar: _buildAppBar(loc, isTablet),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop)
                  _buildDesktopToolbar(loc)
                else ...[
                  // Search Bar - Always visible
                  _buildSearchBar(loc, isTablet),
                  // Category Filter Chips
                  _buildCategoryFilters(loc, isTablet, screenWidth),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 16,
                    ),
                    child: Text(
                      loc.note_hold_category_to_edit,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  _buildActionButtons(loc, isTablet),
                ],

                // Items
                Expanded(
                  child: isDesktop
                      ? _buildDesktopContent(loc, screenWidth)
                      : _buildItemsList(loc, isTablet, screenWidth),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations loc, bool isTablet) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColor.primary,
      automaticallyImplyLeading: false,
      leading: Obx(() {
        if (!controller.isSelectionMode.value) {
          return const SizedBox.shrink();
        }
        return IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: controller.exitSelectionMode,
        );
      }),
      title: Obx(() {
        if (controller.isSelectionMode.value) {
          final count = controller.selectedItemIds.length;
          return Text(
            count == 0 ? loc.select_items : loc.items_selected_count(count),
            style: TextStyle(
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: Colors.white,
            ),
          );
        }
        return Text(
          loc.menu_items,
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        );
      }),
      actions: [
        Obx(() {
          if (!controller.isSelectionMode.value) {
            return IconButton(
              tooltip: loc.select_items_to_delete,
              icon: const Icon(Icons.checklist, color: Colors.white),
              onPressed: controller.toggleSelectionMode,
            );
          }
          final allSelected =
              controller.items.isNotEmpty &&
              controller.selectedItemIds.length == controller.items.length;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: controller.items.isEmpty
                    ? null
                    : allSelected
                    ? controller.clearItemSelection
                    : controller.selectAllVisibleItems,
                child: Text(
                  allSelected ? loc.clear_all : loc.select_all,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                tooltip: loc.delete_selected,
                icon: controller.isDeletingItems.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.delete_outline, color: Colors.white),
                onPressed:
                    controller.selectedItemIds.isEmpty ||
                        controller.isDeletingItems.value
                    ? null
                    : controller.deleteSelectedItems,
              ),
            ],
          );
        }),
        // Refresh
        IconButton(
          tooltip: loc.refresh,
          onPressed: controller.refreshItems,
          icon: const Icon(Icons.refresh, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildDesktopToolbar(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: Obx(
                () => TextField(
                  controller: controller.searchController,
                  decoration: InputDecoration(
                    hintText: loc.search_dishes,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => controller.clearSearch(),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColor.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onChanged: (value) =>
                      controller.filterItemsBySearch(value.trim()),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (StaffAccess.canDeleteProducts)
            Obx(
              () => SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: controller.toggleSelectionMode,
                  icon: Icon(
                    controller.isSelectionMode.value
                        ? Icons.close
                        : Icons.checklist,
                  ),
                  label: Text(
                    controller.isSelectionMode.value
                        ? loc.cancel
                        : loc.select_items,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: controller.isSelectionMode.value
                        ? Colors.red.shade700
                        : AppColor.primary,
                    side: BorderSide(
                      color: controller.isSelectionMode.value
                          ? Colors.red.shade700
                          : AppColor.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          Obx(
            () =>
                controller.isSelectionMode.value &&
                    controller.selectedItemIds.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: controller.isDeletingItems.value
                            ? null
                            : controller.deleteSelectedItems,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          loc.delete_count(controller.selectedItemIds.length),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),

          // SizedBox(
          //   height: 44,
          //   child: OutlinedButton.icon(
          //     onPressed: controller.importFromFile,
          //     icon: const Icon(Icons.upload_file_outlined),
          //     label: Text(loc.import_from_file),
          //     style: OutlinedButton.styleFrom(
          //       foregroundColor: AppColor.primary,
          //       side: BorderSide(color: AppColor.primary),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //     ),
          //   ),
          // ),
          if (StaffAccess.canCreateProducts)
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => Modular.to.pushNamed(
                  HomeMainRoutes.addItem,
                  arguments: controller.buildAddItemArgs(),
                ),
                icon: const Icon(Icons.add),
                label: Text(loc.add_item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (StaffAccess.canImportExportProducts) ...[
            const SizedBox(width: 8),
            PopupMenuButton(
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    onTap: controller.importFromFile,
                    child: Row(
                      spacing: 10,
                      children: [
                        Assets.svg.download.svg(),
                        Text('Import Items'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: controller.exportToFile,
                    child: Row(
                      spacing: 10,
                      children: [Assets.svg.export.svg(), Text('Export Items')],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: controller.downloadProductsTemplate,
                    child: Row(
                      spacing: 10,
                      children: [
                        Assets.svg.file.svg(),
                        Text('Download Template'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopContent(AppLocalizations loc, double screenWidth) {
    final categoryWidth = screenWidth < 1200 ? 240.0 : 300.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: categoryWidth, child: _buildDesktopCategories(loc)),
          const SizedBox(width: 16),
          Expanded(child: _buildItemsGrid(loc, screenWidth)),
        ],
      ),
    );
  }

  Widget _buildDesktopCategories(AppLocalizations loc) {
    return Obx(() {
      final categoriesList = controller.categories;
      final selectedId = controller.selectedCategoryId.value;
      final selectedCategory = (selectedId == null || selectedId == 'none')
          ? null
          : categoriesList
                .where(
                  (c) =>
                      c.categoryName.toLowerCase() == selectedId.toLowerCase(),
                )
                .firstOrNull;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  loc.categories_label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                if (selectedCategory != null && StaffAccess.canUpdateCategories)
                  Tooltip(
                    message: loc.edit_selected_category,
                    child: IconButton(
                      onPressed: () {
                        final appPref = Get.find<AppPref>();
                        if (!hasTrialOrSubscription(appPref)) {
                          checkSubscription();
                          return;
                        }
                        Modular.to.pushNamed(
                          HomeMainRoutes.category,
                          arguments: {
                            'screen': 'item',
                            'isEdit': true,
                            'category': selectedCategory,
                          },
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      splashRadius: 18,
                      color: AppColor.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (StaffAccess.canCreateCategories)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // if (!hasTrialOrSubscription(appPref)) {
                    //   checkSubscription();
                    //   return;
                    // }
                    Modular.to.pushNamed(
                      HomeMainRoutes.category,
                      arguments: {'screen': 'item', 'isEdit': false},
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text(loc.add_category),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    side: BorderSide(color: AppColor.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: Scrollbar(
                controller: categoriesScrollController,
                thumbVisibility: _isWindows(context),
                trackVisibility: _isWindows(context),
                interactive: true,
                thickness: 8,
                radius: const Radius.circular(8),
                child: ListView(
                  controller: categoriesScrollController,
                  children: [
                    _DesktopCategoryTile(
                      title: loc.all,
                      selected: selectedId == 'none',
                      onTap: () => controller.selectCategory('none'),
                      image: '',
                    ),
                    const SizedBox(height: 6),
                    ...categoriesList.map((category) {
                      final id = category.categoryName.toLowerCase();
                      final isSelected = selectedId == id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _DesktopCategoryTile(
                          title:
                              category.categoryName.capitalize ??
                              category.categoryName,
                          selected: isSelected,
                          onTap: () => controller.selectCategory(id),
                          image: category.imageURL,
                          onLongPress: StaffAccess.canUpdateCategories
                              ? () {
                                  final appPref = Get.find<AppPref>();
                                  if (!hasTrialOrSubscription(appPref)) {
                                    checkSubscription();
                                    return;
                                  }
                                  Modular.to.pushNamed(
                                    HomeMainRoutes.category,
                                    arguments: {
                                      'screen': 'item',
                                      'isEdit': true,
                                      'category': category,
                                    },
                                  );
                                }
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.tip_right_click_category_edit,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildItemsGrid(AppLocalizations loc, double screenWidth) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final columns = _menuItemGridColumns(availableWidth);
        const spacing = 12.0;
        final tileWidth = (availableWidth - (columns - 1) * spacing) / columns;
        final compact = _menuItemUseCompactCard(tileWidth);
        final childAspectRatio = _menuItemGridAspectRatio(
          tileWidth: tileWidth,
          compact: compact,
        );

        return Obx(() {
          final displayItems = controller.items;
          final searchQuery = controller.searchQuery.value;
          final isCategoryLoading = controller.isCategoryLoading.value;

          if (isCategoryLoading && displayItems.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
              ),
            );
          }

          if (displayItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 72,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.no_items_found,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    searchQuery.isNotEmpty
                        ? loc.try_different_search_term
                        : loc.add_items_to_this_category,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final showScroller = _isWindows(context);
          return Scrollbar(
            controller: scrollController,
            thumbVisibility: showScroller,
            trackVisibility: showScroller,
            interactive: true,
            thickness: 8,
            radius: const Radius.circular(8),
            child: RefreshIndicator(
              onRefresh: () => controller.getItems(forceApiRefresh: true),
              child: GridView.builder(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: displayItems.length + 1,
                itemBuilder: (context, index) {
                  if (index == displayItems.length) {
                    return _buildBottomLoader(false);
                  }
                  final item = displayItems[index];
                  return _ItemCard(
                    item: item,
                    isTablet: true,
                    compact: compact,
                  );
                },
              ),
            ),
          );
        });
      },
    );
  }

  // ---------------- SEARCH BAR ----------------
  Widget _buildSearchBar(AppLocalizations loc, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(
        () => TextField(
          controller: controller.searchController,
          style: TextStyle(fontSize: isTablet ? 16 : 14),
          decoration: InputDecoration(
            hintText: loc.search_dishes,
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[600],
              size: isTablet ? 24 : 20,
            ),
            suffixIcon: controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[600],
                      size: isTablet ? 24 : 20,
                    ),
                    onPressed: () => controller.clearSearch(),
                  )
                : null,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 18 : 14,
            ),
          ),
          onChanged: (value) => controller.filterItemsBySearch(value.trim()),
        ),
      ),
    );
  }

  // ---------------- CATEGORY FILTERS ----------------
  Widget _buildCategoryFilters(
    AppLocalizations loc,
    bool isTablet,
    double screenWidth,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 16 : 12,
        horizontal: isTablet ? 20 : 16,
      ),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        final categoriesList = controller.categories;
        final selectedId = controller.selectedCategoryId.value;

        return Row(
          children: [
            if (StaffAccess.canCreateCategories)
              _AddCategoryChip(
                onTap: () {
                  final appPref = Get.find<AppPref>();
                  if (!hasTrialOrSubscription(appPref)) {
                    checkSubscription();
                    return;
                  }
                  Modular.to.pushNamed(
                    HomeMainRoutes.category,
                    arguments: {'screen': 'item', 'isEdit': false},
                  );
                  // Get.toNamed(
                  //   AppRoute.addCategory,
                  //   arguments: {'screen': 'item'},
                  // );
                },
                isTablet: isTablet,
                loc: loc,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: HorizontalScrollWithArrows(
                arrowButtonSize: isTablet ? 36 : 32,
                child: Row(
                  children: [
                    _CategoryChip(
                      label: loc.all,
                      isSelected: selectedId == 'none',
                      onTap: () => controller.selectCategory('none'),
                      isTablet: isTablet,
                      loc: loc,
                    ),
                    const SizedBox(width: 8),
                    ...categoriesList.map((category) {
                      final isSelected =
                          selectedId == category.categoryName.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Row(
                          children: [
                            _CategoryChip(
                              label:
                                  category.categoryName.capitalize ??
                                  category.categoryName,
                              isSelected: isSelected,
                              onTap: () => controller.selectCategory(
                                category.categoryName.toLowerCase(),
                              ),
                              onLongPress: StaffAccess.canUpdateCategories
                                  ? () {
                                      final appPref = Get.find<AppPref>();
                                      if (!hasTrialOrSubscription(appPref)) {
                                        checkSubscription();
                                        return;
                                      }
                                      Get.toNamed(
                                        AppRoute.addCategory,
                                        arguments: {
                                          'screen': 'item',
                                          'isEdit': true,
                                          'category': category,
                                        },
                                      );
                                    }
                                  : null,
                              isTablet: isTablet,
                              loc: loc,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ---------------- ACTION BUTTONS ----------------
  Widget _buildActionButtons(AppLocalizations loc, bool isTablet) {
    final radius = BorderRadius.circular(isTablet ? 16 : 12);
    final verticalPad = isTablet ? 16.0 : 14.0;
    final horizontalPad = isTablet ? 20.0 : 16.0;
    final iconSize = isTablet ? 22.0 : 20.0;
    final fontSize = isTablet ? 16.0 : 14.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 12 : 10,
      ),
      child: Column(
        children: [
          Obx(() {
            if (!controller.isSelectionMode.value) {
              return const SizedBox.shrink();
            }
            final allSelected =
                controller.items.isNotEmpty &&
                controller.selectedItemIds.length == controller.items.length;
            return Padding(
              padding: EdgeInsets.only(bottom: isTablet ? 10 : 8),
              child: Row(
                children: [
                  if (StaffAccess.canDeleteProducts)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.items.isEmpty
                            ? null
                            : allSelected
                            ? controller.clearItemSelection
                            : controller.selectAllVisibleItems,
                        icon: const Icon(Icons.select_all),
                        label: Text(
                          allSelected ? loc.clear_all : loc.select_all,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColor.primary,
                          side: BorderSide(color: AppColor.primary),
                          shape: RoundedRectangleBorder(borderRadius: radius),
                        ),
                      ),
                    ),
                  SizedBox(width: isTablet ? 12 : 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          controller.selectedItemIds.isEmpty ||
                              controller.isDeletingItems.value
                          ? null
                          : controller.deleteSelectedItems,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        loc.delete_count(controller.selectedItemIds.length),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: radius),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Row(
            children: [
              if (StaffAccess.canImportExportProducts)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: controller.importFromFile,
                      borderRadius: radius,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPad,
                          vertical: verticalPad,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: radius,
                          border: Border.all(
                            color: AppColor.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file_outlined,
                              color: AppColor.primary,
                              size: iconSize,
                            ),
                            SizedBox(width: isTablet ? 10 : 8),
                            Flexible(
                              child: Text(
                                loc.import_from_file,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (StaffAccess.canImportExportProducts &&
                  StaffAccess.canCreateProducts)
                SizedBox(width: isTablet ? 12 : 10),
              if (StaffAccess.canCreateProducts)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Modular.to.pushNamed(
                        HomeMainRoutes.addItem,
                        arguments: controller.buildAddItemArgs(),
                      ),
                      borderRadius: radius,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPad,
                          vertical: verticalPad,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.primary,
                          borderRadius: radius,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              color: Colors.white,
                              size: iconSize,
                            ),
                            SizedBox(width: isTablet ? 10 : 8),
                            Flexible(
                              child: Text(
                                loc.add_new_item,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- ITEMS LIST ----------------
  Widget _buildItemsList(
    AppLocalizations loc,
    bool isTablet,
    double screenWidth,
  ) {
    return Obx(() {
      final displayItems = controller.items;
      final searchQuery = controller.searchQuery.value;
      final isCategoryLoading = controller.isCategoryLoading.value;

      if (isCategoryLoading && displayItems.isEmpty) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
          ),
        );
      }

      if (displayItems.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: isTablet ? 80 : 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: isTablet ? 24 : 16),
              Text(
                loc.no_items_found,
                style: TextStyle(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                searchQuery.isNotEmpty
                    ? loc.try_different_search_term
                    : loc.add_items_to_this_category,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      final showScroller = _isWindows(context);
      return Scrollbar(
        controller: scrollController,
        thumbVisibility: showScroller,
        trackVisibility: showScroller,
        interactive: true,
        thickness: 8,
        radius: const Radius.circular(8),
        child: RefreshIndicator(
          onRefresh: () => controller.getItems(forceApiRefresh: true),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              const spacing = 12.0;
              final columns = 2;
              final safeWidth = availableWidth > 0
                  ? availableWidth
                  : screenWidth;
              final tileWidth =
                  (safeWidth - (isTablet ? 32 : 24) - spacing) / columns;
              final compact = true;
              final childAspectRatio = _menuItemGridAspectRatio(
                tileWidth: tileWidth,
                compact: compact,
              );

              return GridView.builder(
                physics: const BouncingScrollPhysics(),
                controller: scrollController,
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: isTablet ? 12 : 10,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: displayItems.length + 1, // +1 for bottom loader
                itemBuilder: (context, index) {
                  if (index == displayItems.length) {
                    return _buildBottomLoader(isTablet);
                  }
                  final item = displayItems[index];
                  return _ItemCard(
                    item: item,
                    isTablet: isTablet,
                    compact: compact,
                  );
                },
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildBottomLoader(bool isTablet) {
    final loc = AppLocalizations.of(context)!;
    return Obx(() {
      // Show loader/messages when not searching
      final isSearching = controller.searchQuery.value.isNotEmpty;
      final isLoading = controller.isLoadingMore.value;
      final hasMore = controller.hasMoreItems.value;
      final itemsCount = controller.items.length;

      if (isSearching) {
        return SizedBox.shrink();
      }

      if (isLoading) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: isTablet ? 24 : 20),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
            ),
          ),
        );
      }

      if (!hasMore && itemsCount > 0) {
        return SizedBox();
        // Padding(
        //   padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
        //   child: Center(
        //     child: Text(
        //       loc.no_more_items,
        //       style: TextStyle(
        //         fontSize: isTablet ? 14 : 12,
        //         color: Colors.grey[600],
        //         fontWeight: FontWeight.w500,
        //       ),
        //     ),
        //   ),
        // );
      }

      if (hasMore && itemsCount > 0) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
          child: Center(
            child: Text(
              loc.scroll_for_more,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: Colors.grey[400],
              ),
            ),
          ),
        );
      }

      return SizedBox.shrink();
    });
  }
}

class _DesktopCategoryTile extends StatelessWidget {
  const _DesktopCategoryTile({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.image,
    this.onLongPress,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String image;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColor.primary.withOpacity(0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColor.primary.withOpacity(0.35)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              if (selected)
                Icon(Icons.check_circle, size: 16, color: AppColor.primary)
              else
                Icon(
                  Icons.circle_outlined,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    if (title != AppLocalizations.of(context)!.all &&
                        image.isNotEmpty)
                      AppCachedNetworkImage(
                        imageUrl: image,

                        width: 32,
                        height: 32,
                        errorWidget: (context, url, error) => Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.image_not_supported,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    const SizedBox(width: 10),

                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: selected
                            ? AppColor.primary
                            : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// ===================== CATEGORY CHIP =====================
// =====================================================

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isTablet;
  final AppLocalizations loc;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
    required this.isTablet,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 12 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColor.primary : Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 10 : 10),
            border: Border.all(
              color: isSelected ? AppColor.primary : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 15 : 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : AppColor.primary.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
    if (onLongPress != null) {
      return Tooltip(message: loc.long_press_edit_category, child: child);
    }
    return child;
  }
}

// =====================================================
// ===================== ADD CATEGORY CHIP =====================
// =====================================================

class _AddCategoryChip extends StatelessWidget {
  final VoidCallback onTap;
  final bool isTablet;
  final AppLocalizations loc;

  const _AddCategoryChip({
    required this.onTap,
    required this.isTablet,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 12 : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
            border: Border.all(
              color: AppColor.primary,
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: isTablet ? 20 : 18,
                color: AppColor.primary,
              ),
              SizedBox(width: isTablet ? 6 : 4),
              Text(
                loc.category_chip_label,
                style: TextStyle(
                  fontSize: isTablet ? 15 : 13,
                  fontWeight: FontWeight.w600,
                  color: AppColor.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// ===================== ITEM CARD =====================
// =====================================================

class _ItemCard extends StatelessWidget {
  final ItemData item;
  final bool isTablet;
  final bool compact;

  const _ItemCard({
    required this.item,
    required this.isTablet,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MenuItemController>();
    final loc = AppLocalizations.of(context)!;
    final imageUrl = _resolveItemImageUrl(item.itemImage);

    return Obx(() {
      final selectionMode = controller.isSelectionMode.value;
      final isSelected = controller.isItemSelected(item.id);

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (selectionMode) {
              controller.toggleItemSelection(item.id);
              return;
            }
            if (!StaffAccess.ensure(StaffAccess.canUpdateProducts)) return;
            Modular.to.pushNamed(
              HomeMainRoutes.addItem,
              arguments: {'item': item, 'isEdit': true},
            );
          },
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColor.primary.withOpacity(0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
              border: selectionMode && isSelected
                  ? Border.all(color: AppColor.primary.withOpacity(0.45))
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: isTablet ? 12 : 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? 10 : (isTablet ? 16 : 12)),
              child: compact
                  ? _buildCompactContent(
                      context,
                      loc,
                      controller,
                      imageUrl,
                      selectionMode,
                      isSelected,
                    )
                  : _buildWideContent(
                      context,
                      loc,
                      controller,
                      imageUrl,
                      selectionMode,
                      isSelected,
                    ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildItemImage(String? imageUrl, {double? size}) {
    final imageSize = size ?? (isTablet ? 80.0 : 70.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
      child: SizedBox(
        width: imageSize,
        height: imageSize,
        child: _buildImageContent(imageUrl),
      ),
    );
  }

  Widget _buildImageContent(String? imageUrl) {
    final fallbackIconSize = compact ? 28.0 : (isTablet ? 32.0 : 28.0);

    return ColoredBox(
      color: Colors.grey[200]!,
      child: imageUrl != null
          ? AppCachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              memCacheWidth: 240,
              memCacheHeight: 240,
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: const ColoredBox(color: Colors.white),
              ),
              errorWidget: (context, url, error) => Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: fallbackIconSize,
                  color: Colors.grey[500],
                ),
              ),
            )
          : Center(
              child: Icon(
                Icons.image_outlined,
                size: fallbackIconSize,
                color: Colors.grey[500],
              ),
            ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    AppLocalizations loc,
    MenuItemController controller, {
    bool compact = false,
  }) {
    if (controller.isSelectionMode.value) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: compact ? 30 : (isTablet ? 34 : 30),
          width: compact ? 32 : (isTablet ? 40 : 36),
          child: AppActionDropdown2<String>(
            customButton: Icon(
              Icons.more_vert,
              size: compact ? 18 : (isTablet ? 22 : 20),
              color: Colors.grey.shade700,
            ),
            width: 150,
            buttonStyleData: ButtonStyleData(
              height: compact ? 30 : (isTablet ? 34 : 30),
              width: compact ? 32 : (isTablet ? 40 : 36),
              padding: EdgeInsets.zero,
            ),
            items: [
              if (StaffAccess.canUpdateProducts)
                DropdownItem<String>(
                  value: 'edit',
                  height: 44,
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: 10),
                      Text(loc.edit),
                    ],
                  ),
                ),
              if (StaffAccess.canDeleteProducts)
                DropdownItem<String>(
                  value: 'delete',
                  height: 44,
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outlined, size: 18),
                      const SizedBox(width: 10),
                      Text(loc.delete),
                    ],
                  ),
                ),
            ],
            onChanged: (value) {
              if (value == 'edit' &&
                  StaffAccess.ensure(StaffAccess.canUpdateProducts)) {
                Modular.to.pushNamed(
                  HomeMainRoutes.addItem,
                  arguments: {'item': item, 'isEdit': true},
                );
              } else if (value == 'delete') {
                controller.deleteItem(item);
              }
            },
          ),
        ),
        const SizedBox(width: 4),
        Obx(() {
          final isAvailable = controller.isItemAvailable(item.id);
          return Switch(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            value: isAvailable,
            onChanged: (_) => controller.toggleItemAvailability(item.id),
            activeColor: AppColor.primary.withOpacity(0.9),
            activeTrackColor: AppColor.primary.withOpacity(0.2),
          );
        }),
      ],
    );
  }

  Widget _buildCompactContent(
    BuildContext context,
    AppLocalizations loc,
    MenuItemController controller,
    String? imageUrl,
    bool selectionMode,
    bool isSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectionMode) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Checkbox(
              value: isSelected,
              activeColor: AppColor.primary,
              onChanged: (_) => controller.toggleItemSelection(item.id),
            ),
          ),
          const SizedBox(height: 4),
        ],
        AspectRatio(
          aspectRatio: 1.15,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
            child: _buildImageContent(imageUrl),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.itemName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isTablet ? 15 : 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${item.salePrice.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isTablet ? 14 : 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildActions(context, loc, controller, compact: true),
      ],
    );
  }

  Widget _buildWideContent(
    BuildContext context,
    AppLocalizations loc,
    MenuItemController controller,
    String? imageUrl,
    bool selectionMode,
    bool isSelected,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectionMode) ...[
          Checkbox(
            value: isSelected,
            activeColor: AppColor.primary,
            onChanged: (_) => controller.toggleItemSelection(item.id),
          ),
          SizedBox(width: isTablet ? 4 : 2),
        ],
        _buildItemImage(imageUrl),
        SizedBox(width: isTablet ? 16 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.itemName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              SizedBox(height: isTablet ? 6 : 4),
              Text(
                '₹${item.salePrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: isTablet ? 12 : 8),
        if (!selectionMode)
          SizedBox(
            width: isTablet ? 72 : 64,
            height: isTablet ? 80 : 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  height: isTablet ? 34 : 30,
                  width: isTablet ? 40 : 36,
                  child: AppActionDropdown2<String>(
                    customButton: Icon(
                      Icons.more_vert,
                      size: isTablet ? 22 : 20,
                      color: Colors.grey.shade700,
                    ),
                    width: 150,
                    buttonStyleData: ButtonStyleData(
                      height: isTablet ? 34 : 30,
                      width: isTablet ? 40 : 36,
                      padding: EdgeInsets.zero,
                    ),
                    items: [
                      if (StaffAccess.canUpdateProducts)
                        DropdownItem<String>(
                          value: 'edit',
                          height: 44,
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 18),
                              const SizedBox(width: 10),
                              Text(loc.edit),
                            ],
                          ),
                        ),
                      if (StaffAccess.canDeleteProducts)
                        DropdownItem<String>(
                          value: 'delete',
                          height: 44,
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outlined, size: 18),
                              const SizedBox(width: 10),
                              Text(loc.delete),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == 'edit' &&
                          StaffAccess.ensure(StaffAccess.canUpdateProducts)) {
                        Modular.to.pushNamed(
                          HomeMainRoutes.addItem,
                          arguments: {'item': item, 'isEdit': true},
                        );
                      } else if (value == 'delete') {
                        controller.deleteItem(item);
                      }
                    },
                  ),
                ),
                Obx(() {
                  final isAvailable = controller.isItemAvailable(item.id);
                  return Switch(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: isAvailable,
                    onChanged: (_) =>
                        controller.toggleItemAvailability(item.id),
                    activeColor: AppColor.primary.withOpacity(0.9),
                    activeTrackColor: AppColor.primary.withOpacity(0.2),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
