import 'package:billkaro/app/modules/Items/item_details_screen.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/responsive.dart';
import 'package:shimmer/shimmer.dart';

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
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar - Always visible
            _buildSearchBar(loc, isTablet),
            // Category Filter Chips
            _buildCategoryFilters(loc, isTablet, screenWidth),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
              child: Text(
                'Note: Hold category chip to edit.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            // Add New Item Button
            _buildAddButton(loc, isTablet),

            // Items List
            Expanded(child: _buildItemsList(loc, isTablet, screenWidth)),
          ],
        ),
      );
    });
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
                Get.toNamed(
                  AppRoute.addCategory,
                  arguments: {'screen': 'item'},
                );
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
          onTap: () => Get.toNamed(AppRoute.addMenuItem),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.toNamed(
          AppRoute.addMenuItem,
          arguments: {'isEdit': true, 'item': item},
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
                    child: item.itemImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.itemImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Icon(
                                Icons.image,
                                size: isTablet ? 32 : 28,
                                color: Colors.grey[400],
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              child: Icon(
                                Icons.image,
                                size: isTablet ? 32 : 28,
                                color: Colors.grey[400],
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image,
                              size: isTablet ? 32 : 28,
                              color: Colors.grey[400],
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

                // Toggle Switch - Orange, centered vertically
                SizedBox(
                  height: isTablet ? 80 : 70, // Match image height
                  child: Center(
                    child: Obx(() {
                      final isAvailable = controller.isItemAvailable(item.id);
                      return Switch(
                        value: isAvailable,
                        onChanged: (value) {
                          controller.toggleItemAvailability(item.id);
                        },
                        activeColor: AppColor.primary.withOpacity(0.9),
                        activeTrackColor: AppColor.primary.withOpacity(0.2),
                      );
                    }),
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
