import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/responsive.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:shimmer/shimmer.dart';

String? _resolveItemImageUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;

  // If already absolute, just ensure it's safely encoded.
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    try {
      return Uri.encodeFull(trimmed);
    } catch (_) {
      return trimmed;
    }
  }

  // Build an absolute URL from the API base origin.
  // baseURL example: https://65.2.81.212/api/
  final origin = Uri.parse(baseURL).replace(path: '').toString();
  final joined = trimmed.startsWith('/')
      ? '$origin$trimmed'
      : '$origin/$trimmed';
  try {
    return Uri.encodeFull(joined);
  } catch (_) {
    return joined;
  }
}

class MenuItemScreen extends StatefulWidget {
  MenuItemScreen({super.key});

  @override
  State<MenuItemScreen> createState() => _MenuItemScreenState();
}

class _MenuItemScreenState extends State<MenuItemScreen> {
  final controller = Get.put(MenuItemController());
  final ScrollController scrollController = ScrollController();

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
    // Only trigger load more when viewing all items (not filtered by category)
    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 300) {
      if (controller.selectedCategoryId.value == 'none' &&
          controller.searchQuery.value.isEmpty) {
        controller.loadMoreItems();
      }
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
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
                  'Loading menu...',
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
        ),
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
                      'Note: Hold category chip to edit.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  // Add New Item Button
                  _buildAddButton(loc, isTablet),
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
                    hintText: 'Search dishes',
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
          const SizedBox(width: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => Modular.to.pushNamed(
                HomeMainRoutes.addItem,
                arguments: {'isEdit': false},
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent(AppLocalizations loc, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 260, child: _buildDesktopCategories(loc)),
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
                  'Categories',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: selectedCategory == null
                      ? 'Select a category to edit'
                      : 'Edit selected category',
                  child: IconButton(
                    onPressed: selectedCategory == null
                        ? null
                        : () {
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final appPref = Get.find<AppPref>();
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
                label: const Text('Add category'),
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
                thumbVisibility: true,
                child: ListView(
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
                          onLongPress: () {
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
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: Right-click / long-press a category to edit.',
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
        // Keep tiles wide enough so row contents (image + text + switch) never overflow.
        final int computedColumns = (availableWidth / 360).floor().clamp(1, 4);

        return Obx(() {
          final displayItems = controller.items;
          final searchQuery = controller.searchQuery.value;

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
                    'No items found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    searchQuery.isNotEmpty
                        ? 'Try a different search term'
                        : 'Add items to this category',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Scrollbar(
            thumbVisibility: true,
            child: RefreshIndicator(
              onRefresh: () => controller.getItems(forceApiRefresh: true),
              child: GridView.builder(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: computedColumns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  // Slightly wider tiles than before to avoid any edge-case overflow.
                  childAspectRatio: 3.0,
                ),
                itemCount: displayItems.length + 1,
                itemBuilder: (context, index) {
                  if (index == displayItems.length) {
                    return _buildBottomLoader(false);
                  }
                  final item = displayItems[index];
                  return _ItemCard(item: item, isTablet: true);
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
            hintText: 'Search Dishes',
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
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CategoryChip(
                      label: loc.all,
                      isSelected: selectedId == 'none',
                      onTap: () => controller.selectCategory('none'),
                      isTablet: isTablet,
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
                              onLongPress: () {
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
                              },
                              isTablet: isTablet,
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

  // ---------------- ADD BUTTON ----------------
  Widget _buildAddButton(AppLocalizations loc, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 12 : 10,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Modular.to.pushNamed(
            HomeMainRoutes.addItem,
            arguments: {'isEdit': false},
          ),
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 16 : 14,
            ),
            decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white, size: isTablet ? 24 : 20),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'Add New Item',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
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
                'No items found',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                searchQuery.isNotEmpty
                    ? 'Try a different search term'
                    : 'Add items to this category',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.getItems(forceApiRefresh: true),
        child: ListView.builder(
          physics: BouncingScrollPhysics(),
          controller: scrollController,
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          itemCount: displayItems.length + 1, // +1 for bottom loader
          itemBuilder: (context, index) {
            if (index == displayItems.length) {
              return _buildBottomLoader(isTablet);
            }
            final item = displayItems[index];
            return Padding(
              padding: EdgeInsets.only(bottom: isTablet ? 12 : 10),
              child: _ItemCard(item: item, isTablet: isTablet),
            );
          },
        ),
      );
    });
  }

  Widget _buildBottomLoader(bool isTablet) {
    return Obx(() {
      // Only show loader/messages when viewing all items without filters
      final isViewingAll =
          controller.selectedCategoryId.value == 'none' &&
          controller.searchQuery.value.isEmpty;
      final isLoading = controller.isLoadingMore.value;
      final hasMore = controller.hasMoreItems.value;
      final itemsCount = controller.items.length;

      if (!isViewingAll) {
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
        return Padding(
          padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
          child: Center(
            child: Text(
              'No more items',
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }

      if (hasMore && itemsCount > 0) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
          child: Center(
            child: Text(
              'Scroll for more',
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
                    if (title != 'ALL')
                      CachedNetworkImage(
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

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
    required this.isTablet,
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
      return Tooltip(message: 'Long press to edit category', child: child);
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

  const _AddCategoryChip({required this.onTap, required this.isTablet});

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
                'Category',
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

  const _ItemCard({required this.item, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MenuItemController>();
    final imageUrl = _resolveItemImageUrl(item.itemImage);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Modular.to.pushNamed(
          HomeMainRoutes.addItem,
          arguments: {'item': item, 'isEdit': true},
        ),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
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
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Image - Small square on left
                ClipRRect(
                  borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                  child: Container(
                    width: isTablet ? 80 : 70,
                    height: isTablet ? 80 : 70,
                    color: Colors.grey[200],
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: (isTablet ? 160 : 140),
                            memCacheHeight: (isTablet ? 160 : 140),
                            fadeInDuration: const Duration(milliseconds: 150),
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(color: Colors.grey[300]),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: isTablet ? 32 : 28,
                                color: Colors.grey[500],
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_outlined,
                              size: isTablet ? 32 : 28,
                              color: Colors.grey[500],
                            ),
                          ),
                  ),
                ),

                SizedBox(width: isTablet ? 16 : 12),

                // Item Details - Name and Price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Item Name
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
                      // Price
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

                // Actions (Edit menu) + Availability toggle
                SizedBox(
                  width: isTablet ? 72 : 64,
                  height: isTablet ? 80 : 70, // Match image height
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: isTablet ? 34 : 30,
                        width: isTablet ? 40 : 36,
                        child: PopupMenuButton<String>(
                          tooltip: 'More',
                          padding: EdgeInsets.zero,
                          iconSize: isTablet ? 22 : 20,
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey.shade700,
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              Modular.to.pushNamed(
                                HomeMainRoutes.addItem,
                                arguments: {'item': item, 'isEdit': true},
                              );
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 10),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Obx(() {
                          final isAvailable = controller.isItemAvailable(
                            item.id,
                          );
                          return Switch(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            value: isAvailable,
                            onChanged: (value) {
                              controller.toggleItemAvailability(item.id);
                            },
                            activeColor: AppColor.primary.withOpacity(0.9),
                            activeTrackColor: AppColor.primary.withOpacity(0.2),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
