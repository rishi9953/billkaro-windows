import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/Widgets/horizontal_scroll_with_arrows.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_list_screen.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/app/services/Modals/orders/split_payment.dart';
import 'package:billkaro/app/utils/pos_cart_line.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AddOrderScreen extends StatefulWidget {
  AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  late final AddOrderController controller;
  final ScrollController scrollController = ScrollController();
  static const double _desktopRadius = 10;
  static const double _appBarActionButtonHeight = 36;

  bool get _isDesktopPlatform =>
      GetPlatform.isWindows || GetPlatform.isMacOS || GetPlatform.isLinux;

  bool get _isWindows => GetPlatform.isWindows;

  /// Windows: Fluent-style controls (secondary outline + primary filled).
  static const double _windowsFooterButtonRadius = 6;
  static const double _windowsFooterButtonHeight = 48;

  Widget _orderSourceIcon(String source) {
    switch (source) {
      case 'Delivery':
        return Assets.delivery.image(width: 20, height: 20);
      case 'Dine In':
        return Assets.dineIn.image(width: 20, height: 20);
      case 'Swiggy':
        return Assets.svg.swiggy.svg(width: 20, height: 20);
      case 'Takeaway':
        return Assets.takeaway.image(width: 20, height: 20);
      case 'Zomato':
        return Assets.svg.zomato.svg(width: 20, height: 20);
      default:
        return const Icon(Icons.help_outline, size: 20);
    }
  }

  @override
  void initState() {
    super.initState();
    // This screen is routed by Modular, so GetX may keep an old controller alive.
    // Recreate it to always consume the latest route arguments (edit order/customer data).
    if (Get.isRegistered<AddOrderController>()) {
      Get.delete<AddOrderController>(force: true);
    }
    controller = Get.put(AddOrderController());
    _setupScrollListener();
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
    controller.clearOrderDraft();
    // Only delete if this screen still owns the registered instance.
    // Navigating Create Order → Invoice (push) → Create Order (sidebar) can
    // dispose the old screen after a new controller was already put, which
    // would otherwise unregister the active one and break ConfirmOrderDialog.
    if (Get.isRegistered<AddOrderController>() &&
        identical(Get.find<AddOrderController>(), controller)) {
      Get.delete<AddOrderController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;
    final theme = Theme.of(context);
    final desktopButtonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(30, 38),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_desktopRadius),
      ),
    );

    Widget buildMainContent() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            // Keep categories bar visible when we have categories (even if selected category has no items)
            if (controller.items.isEmpty &&
                controller.categories.isEmpty &&
                !controller.showSearchBar.value) {
              return SizedBox.shrink();
            }
            if (controller.isListView.value) {
              return SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _isDesktopPlatform ? 14 : 8,
                vertical: _isDesktopPlatform ? 10 : 8,
              ),
              child: controller.showSearchBar.value
                  ? Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search items...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    _isDesktopPlatform ? _desktopRadius : 8,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: _isDesktopPlatform ? 10 : 0,
                                  horizontal: _isDesktopPlatform ? 14 : 12,
                                ),
                              ),
                              onChanged: (value) {
                                controller.filterItemsBySearch(value.trim());
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            controller.showSearchBarFunction();
                            controller.clearSearch();
                          },
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            controller.showSearchBarFunction();
                          },
                          style: desktopButtonStyle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 0,
                            ),
                            child: Icon(Icons.search, size: 20),
                          ),
                        ),
                        SizedBox(width: _isDesktopPlatform ? 8 : 6),
                        Expanded(
                          child: HorizontalScrollWithArrows(
                            arrowButtonSize: _isDesktopPlatform ? 34 : 30,
                            child: Row(
                              spacing: _isDesktopPlatform ? 12 : 10,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    controller.selectCategory('none');
                                  },
                                  style: desktopButtonStyle.copyWith(
                                    backgroundColor: WidgetStatePropertyAll(
                                      controller.selectedCategory.value
                                                  .toLowerCase() ==
                                              'none'
                                          ? AppColor.secondaryPrimary
                                                .withOpacity(0.5)
                                          : Colors.transparent,
                                    ),
                                    side: WidgetStatePropertyAll(
                                      BorderSide(
                                        color:
                                            controller.selectedCategory.value
                                                    .toLowerCase() ==
                                                'none'
                                            ? AppColor.secondaryPrimary
                                            : AppColor.primary,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                      vertical: 0,
                                    ),
                                    child: Text(loc.all),
                                  ),
                                ),
                                ...controller.categories.map((category) {
                                  return OutlinedButton(
                                    onPressed: () {
                                      controller.selectCategory(
                                        category.categoryName.toLowerCase(),
                                      );
                                    },
                                    style: desktopButtonStyle.copyWith(
                                      backgroundColor: WidgetStatePropertyAll(
                                        controller.selectedCategory.value ==
                                                category.categoryName
                                                    .toLowerCase()
                                            ? AppColor.secondaryPrimary
                                                  .withOpacity(0.5)
                                            : Colors.transparent,
                                      ),
                                      side: WidgetStatePropertyAll(
                                        BorderSide(
                                          color:
                                              controller
                                                      .selectedCategory
                                                      .value ==
                                                  category.categoryName
                                                      .toLowerCase()
                                              ? AppColor.secondaryPrimary
                                              : AppColor.primary,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0,
                                        vertical: 0,
                                      ),
                                      child: Text(
                                        category.categoryName.capitalize ?? '',
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: _isDesktopPlatform ? 8 : 6),
                        OutlinedButton(
                          onPressed: () {
                            Modular.to.pushNamed(
                              HomeMainRoutes.category,
                              arguments: {
                                'voiceCallback': controller.getCategories,
                              },
                            );
                          },
                          style: desktopButtonStyle,
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
            );
          }),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scrollHorizontalPadding =
                    (_isDesktopPlatform ? 12 : 8) * 2.0;
                final itemCardWidth = resolveWrapItemCardWidth(
                  constraints.maxWidth - scrollHorizontalPadding,
                  minWidth: _isDesktopPlatform ? 140.0 : 130.0,
                );

                return Obx(
                  () => controller.isListView.value
                      ? AddOrderListScreen(controller: controller)
                      : Obx(() {
                      if (controller.items.isEmpty) {
                        // Empty State — only show create shortcuts when allowed.
                        if (!StaffAccess.canCreateProducts) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                loc.no_items_found,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Add Menu using Photos (AI-powered)
                                  AddMenuAiCard(
                                    label: loc.add_your_menu_using_photos,
                                    cardWidth: itemCardWidth,
                                    onTap: () => controller.addMenuUsingAI(),
                                  ),
                                  const SizedBox(width: 16),
                                  // Add Item
                                  AddItemCard(
                                    label: loc.addItems,
                                    cardWidth: itemCardWidth,
                                    onTap: () => controller.addItem('none'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      // When items exist - Show by category
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              controller: scrollController,
                              padding: EdgeInsets.all(
                                _isDesktopPlatform ? 12 : 8,
                              ),
                              child: Obx(() {
                                // When "ALL" is selected, show all categories with their items
                                if (controller.selectedCategory.value
                                        .toLowerCase() ==
                                    'none') {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (controller.showRecommendedSection &&
                                          controller
                                              .recommendedItems
                                              .isNotEmpty)
                                        Builder(
                                          builder: (context) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8.0,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.star_rounded,
                                                        color: AppColor.primary,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        loc.recommended_items,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Wrap(
                                                  spacing: 12,
                                                  runSpacing: 12,
                                                  children: controller.recommendedItems.map((
                                                    item,
                                                  ) {
                                                    return Obx(
                                                      () => OrderItemCard(
                                                        cardWidth: itemCardWidth,
                                                        imageUrl: item.itemImage,
                                                        posColor: item.posColor,
                                                        itemName:
                                                            item
                                                                .itemName
                                                                .capitalize ??
                                                            '',
                                                        price:
                                                            double.tryParse(
                                                              item.salePrice
                                                                  .toString(),
                                                            ) ??
                                                            0.0,
                                                        quantity: controller
                                                            .getParentItemQuantity(
                                                              item.id,
                                                            ),
                                                        onDelete: () {
                                                          controller
                                                              .removeItemCompletely(
                                                                item.id,
                                                              );
                                                        },
                                                        onIncrement: () {
                                                          controller
                                                              .handlePosItemTap(item);
                                                        },
                                                        onDecrement: () {
                                                          controller
                                                              .decrementItemQuantity(
                                                                item.id,
                                                              );
                                                        },
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                            );
                                          },
                                        ),
                                      // Show "None" category items FIRST (top)
                                      Builder(
                                        builder: (context) {
                                          final noneItems = controller.items
                                              .where(
                                                (item) =>
                                                    item.category
                                                            .toLowerCase() ==
                                                        'none' &&
                                                    !controller
                                                        .bestSellingItemIds
                                                        .contains(item.id),
                                              )
                                              .toList();

                                          if (noneItems.isEmpty) {
                                            return SizedBox.shrink();
                                          }

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 8.0,
                                                ),
                                                child: Text(
                                                  'None',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              Wrap(
                                                spacing: 12,
                                                runSpacing: 12,
                                                children: [
                                                  // None category items
                                                  ...noneItems.map((item) {
                                                    return Obx(
                                                      () => OrderItemCard(
                                                        cardWidth: itemCardWidth,
                                                        imageUrl: item.itemImage,
                                                        posColor: item.posColor,
                                                        itemName:
                                                            item
                                                                .itemName
                                                                .capitalize ??
                                                            '',
                                                        price:
                                                            double.tryParse(
                                                              item.salePrice
                                                                  .toString(),
                                                            ) ??
                                                            0.0,
                                                        quantity: controller
                                                            .getParentItemQuantity(
                                                              item.id,
                                                            ),
                                                        onDelete: () {
                                                          controller
                                                              .removeItemCompletely(
                                                                item.id,
                                                              );
                                                        },
                                                        onIncrement: () {
                                                          controller
                                                              .handlePosItemTap(item);
                                                        },
                                                        onDecrement: () {
                                                          controller
                                                              .decrementItemQuantity(
                                                                item.id,
                                                              );
                                                        },
                                                      ),
                                                    );
                                                  }),

                                                  // Add Photo Card
                                                  AddMenuAiCard(
                                                    label: loc
                                                        .add_your_menu_using_photos,
                                                    cardWidth: itemCardWidth,
                                                    onTap: () => controller
                                                        .addMenuUsingAI(),
                                                  ),

                                                  // Add Item Card
                                                  AddItemCard(
                                                    label: loc.addItems,
                                                    cardWidth: itemCardWidth,
                                                    onTap: () => controller
                                                        .addItem('none'),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                          );
                                        },
                                      ),

                                      // Show all categories with items
                                      ...controller.categories.map((category) {
                                        final categoryItems = controller.items
                                            .where(
                                              (item) =>
                                                  item.category.toLowerCase() ==
                                                      category.categoryName
                                                          .toLowerCase() &&
                                                  !controller.bestSellingItemIds
                                                      .contains(item.id),
                                            )
                                            .toList();

                                        if (categoryItems.isEmpty) {
                                          return SizedBox.shrink();
                                        }

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8.0,
                                                  ),
                                              child: Text(
                                                category
                                                        .categoryName
                                                        .capitalize ??
                                                    '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Wrap(
                                              spacing: 12,
                                              runSpacing: 12,
                                              children: [
                                                ...categoryItems.map((item) {
                                                  return Obx(
                                                    () => OrderItemCard(
                                                      cardWidth: itemCardWidth,
                                                      imageUrl: item.itemImage,
                                                        posColor: item.posColor,
                                                      itemName:
                                                          item
                                                              .itemName
                                                              .capitalize ??
                                                          '',
                                                      price:
                                                          double.tryParse(
                                                            item.salePrice
                                                                .toString(),
                                                          ) ??
                                                          0.0,
                                                      quantity: controller
                                                          .getParentItemQuantity(
                                                            item.id,
                                                          ),
                                                      onDelete: () {
                                                        controller
                                                            .removeItemCompletely(
                                                              item.id,
                                                            );
                                                      },
                                                      onIncrement: () {
                                                        controller
                                                            .handlePosItemTap(
                                                              item,
                                                            );
                                                      },
                                                      onDecrement: () {
                                                        controller
                                                            .decrementItemQuantity(
                                                              item.id,
                                                            );
                                                      },
                                                    ),
                                                  );
                                                }),
                                                AddItemCard(
                                                  label: loc.addItems,
                                                  cardWidth: itemCardWidth,
                                                  onTap: () =>
                                                      controller.addItem(
                                                        category.categoryName,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                          ],
                                        );
                                      }),

                                      // Loading indicator for pagination
                                      Obx(() {
                                        if (controller.isLoadingMore.value) {
                                          return Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        }
                                        return SizedBox.shrink();
                                      }),
                                    ],
                                  );
                                } else {
                                  // Show only selected category items
                                  final selectedItems = controller.items
                                      .where(
                                        (item) =>
                                            item.category.toLowerCase() ==
                                            controller.selectedCategory.value
                                                .toLowerCase(),
                                      )
                                      .toList();

                                  // Also include items with category "None" when showing a specific category
                                  // This ensures items with "None" category appear in all tabs
                                  if (controller.selectedCategory.value
                                          .toLowerCase() !=
                                      'none') {
                                    final noneCategoryItems = controller.items
                                        .where(
                                          (item) =>
                                              item.category.toLowerCase() ==
                                              'none',
                                        )
                                        .toList();
                                    // Put None items on top
                                    selectedItems.insertAll(
                                      0,
                                      noneCategoryItems,
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Text(
                                          controller
                                                  .selectedCategory
                                                  .value
                                                  .capitalize ??
                                              '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          ...selectedItems.map((item) {
                                            return Obx(
                                              () => OrderItemCard(
                                                cardWidth: itemCardWidth,
                                                imageUrl: item.itemImage,
                                                        posColor: item.posColor,
                                                itemName:
                                                    item.itemName.capitalize ??
                                                    '',
                                                price:
                                                    double.tryParse(
                                                      item.salePrice.toString(),
                                                    ) ??
                                                    0.0,
                                                quantity: controller
                                                    .getParentItemQuantity(item.id),
                                                onDelete: () {
                                                  controller
                                                      .removeItemCompletely(
                                                        item.id,
                                                      );
                                                },
                                                onIncrement: () {
                                                  controller
                                                      .incrementItemQuantity(
                                                        item.id,
                                                      );
                                                },
                                                onDecrement: () {
                                                  controller
                                                      .decrementItemQuantity(
                                                        item.id,
                                                      );
                                                },
                                              ),
                                            );
                                          }),
                                          AddItemCard(
                                            label: loc.addItems,
                                            cardWidth: itemCardWidth,
                                            onTap: () => controller.addItem(
                                              controller.selectedCategory.value,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                              }),
                            ),
                          ),

                          // Summary Section pinned at bottom - Only show when items are selected
                        ],
                      );
                    }),
                );
              },
            ),
          ),
        ],
      );
    }

    return WillPopScope(
      onWillPop: () => _showLeaveConfirmationDialog(context),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _canShowBackButton(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : null,
          elevation: 0,
          centerTitle: false,
          toolbarHeight: _isDesktopPlatform ? 64 : kToolbarHeight,
          title: Obx(() {
            if (controller.selectedOrderSource.value.isEmpty) {
              return Text(
                loc.add_Order,
                style: TextStyle(
                  color: AppColor.white,
                  fontSize: _isDesktopPlatform ? 18 : 20,
                  fontWeight: FontWeight.w600,
                ),
              );
            }
            return Row(
              children: [
                Text(
                  controller.selectedOrderSource.value,
                  style: TextStyle(
                    color: AppColor.white,
                    fontSize: _isDesktopPlatform ? 18 : 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(20),
                controller.showIcon(),
              ],
            );
          }),
          actions: [
            Obx(() {
              if (controller.isFromTableScreen.value) {
                return const SizedBox.shrink();
              }
              controller.homeController.selectedOutlet.value;
              if (!HomeMainRoutes.outletIsCafeOrRestaurant()) {
                return const SizedBox.shrink();
              }
              final selected = controller.selectedOrderSource.value;
              return Tooltip(
                message: 'Change order source',
                child: AppActionDropdown2<String>(
                  width: 220,
                  customButton: Container(
                    margin: const EdgeInsets.only(
                      right: 4,
                      top: 10,
                      bottom: 10,
                    ),
                    height: _appBarActionButtonHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(
                        _isDesktopPlatform ? _desktopRadius : 8,
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz,
                          size: 18,
                          color: Colors.white.withOpacity(0.95),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selected.isEmpty ? 'Order source' : selected,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  items: controller.ordersList.map((source) {
                    final isSelected = source == selected;
                    return DropdownItem<String>(
                      value: source,
                      height: 44,
                      child: Row(
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check, size: 18),
                            const SizedBox(width: 8),
                          ] else ...[
                            const SizedBox(width: 26),
                          ],
                          _orderSourceIcon(source),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              source,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.setOrderSource(value);
                    }
                  },
                ),
              );
            }),

            // Gap(8),
            // Obx(() {
            //   if (controller.items.isEmpty) {
            //     return Container();
            //   }
            //   if (!controller.showAddDetailsOnCreateOrder.value) {
            //     return Container();
            //   }
            //   return InkWell(
            //     onTap: () async {
            //       final result = await Modular.to.pushNamed(
            //         HomeMainRoutes.orderDetails,
            //         arguments: {
            //           ...controller.orderDetails,
            //           'orderFrom': controller.selectedOrderSource.value,
            //           'totalAmount': controller.totalAmount.value,
            //         },
            //       );
            //       // final result = await Get.toNamed(
            //       //   AppRoute.orderDetails,
            //       //   arguments: {
            //       //     ...controller.orderDetails,
            //       //     'orderFrom': controller.selectedOrderSource.value,
            //       //     'totalAmount': controller.totalAmount.value,
            //       //   },
            //       // );
            //       if (result != null && result is CreateorderRequest) {
            //         controller.setOrderDetails(result.toJson());
            //         debugPrint(controller.orderDetails.toString());
            //       }
            //     },
            //     child: Container(
            //       margin: const EdgeInsets.only(top: 10, bottom: 10, right: 8),
            //       height: _appBarActionButtonHeight,
            //       decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(
            //           _isDesktopPlatform ? _desktopRadius : 6,
            //         ),
            //         border: Border.all(color: AppColor.white, width: 1),
            //         color: AppColor.white,
            //       ),
            //       child: Center(
            //         child: Padding(
            //           padding: const EdgeInsets.symmetric(horizontal: 12),
            //           child: Text(
            //             loc.add_details,
            //             style: TextStyle(
            //               color: AppColor.primary,
            //               fontSize: 16,
            //               fontWeight: FontWeight.w500,
            //             ),
            //           ),
            //         ),
            //       ),
            //     ),
            //   );
            // }),
            if (StaffAccess.canManageSettings)
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColor.white),
                onPressed: controller.openSettings,
              ),
          ],
        ),
        body: Column(
          children: [
            // Obx(() {
            //   controller.homeController.selectedOutlet.value;
            //   if (!HomeMainRoutes.outletIsCafeOrRestaurant()) {
            //     return const SizedBox.shrink();
            //   }
            //   return _OrderTypeBar(
            //     controller: controller,
            //     orderSourceIcon: _orderSourceIcon,
            //   );
            // }),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1000;

                  if (!isWide) {
                    return buildMainContent();
                  }

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1500),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: buildMainContent()),
                          SizedBox(
                            width: 400,
                            child: _CartPanel(controller: controller),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: Obx(() {
          controller.itemQuantities.length;
          controller.isKOT.value;
          controller.pendingKotItemCount;
          controller.homeController.selectedOutlet.value;
          final kotEnabled = controller.isKotFeatureActive;
          final showKotButton = kotEnabled && StaffAccess.canPrintKot;

          if (_isWindows) {
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: controller.hasSelectedItems
                        ? () => controller.viewInvoicePreview()
                        : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, _windowsFooterButtonHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(color: theme.colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          _windowsFooterButtonRadius,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (showKotButton) ...[
                    OutlinedButton(
                      onPressed: controller.hasSelectedItems
                          ? () =>
                                controller.executePosAction(PosOrderAction.kot)
                          : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, _windowsFooterButtonHeight),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: const Color(0xFFE65100),
                        side: const BorderSide(color: Color(0xFFE65100)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            _windowsFooterButtonRadius,
                          ),
                        ),
                      ),
                      child: Text(
                        controller.pendingKotItemCount > 0
                            ? 'KOT (${controller.pendingKotItemCount})'
                            : 'KOT',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  OutlinedButton(
                    onPressed: controller.hasSelectedItems
                        ? () => controller.showConfirmOrderDialog(
                            PosOrderAction.hold,
                          )
                        : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, _windowsFooterButtonHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(color: theme.colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          _windowsFooterButtonRadius,
                        ),
                      ),
                    ),
                    child: Text(
                      kotEnabled ? 'Save' : loc.save_and_hold,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: controller.hasSelectedItems
                        ? () => controller.showConfirmOrderDialog(
                            PosOrderAction.bill,
                          )
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, _windowsFooterButtonHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: AppColor.primary,
                      foregroundColor: AppColor.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          _windowsFooterButtonRadius,
                        ),
                      ),
                    ),
                    child: Text(
                      kotEnabled ? 'Bill' : loc.save_and_bill,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final secondaryLabel = kotEnabled ? 'Save' : loc.save_and_hold;
          final primaryLabel = kotEnabled ? 'Bill' : loc.save_and_bill;

          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isDesktopPlatform ? 24 : 16,
              vertical: _isDesktopPlatform ? 14 : 16,
            ),
            color: theme.colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                ElevatedButton(
                  onPressed: controller.hasSelectedItems
                      ? () => controller.viewInvoicePreview()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.onSurface,
                    elevation: 0,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.symmetric(
                      horizontal: _isDesktopPlatform ? 14 : 12,
                      vertical: _isDesktopPlatform ? 14 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(
                        _isDesktopPlatform ? _desktopRadius : 12,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Preview',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 12),
                if (showKotButton) ...[
                  ElevatedButton(
                    onPressed: controller.hasSelectedItems
                        ? () => controller.executePosAction(PosOrderAction.kot)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      foregroundColor: const Color(0xFFE65100),
                      elevation: 0,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.symmetric(
                        horizontal: _isDesktopPlatform ? 14 : 12,
                        vertical: _isDesktopPlatform ? 14 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Color(0xFFE65100)),
                        borderRadius: BorderRadius.circular(
                          _isDesktopPlatform ? _desktopRadius : 12,
                        ),
                      ),
                    ),
                    child: Text(
                      controller.pendingKotItemCount > 0
                          ? 'KOT (${controller.pendingKotItemCount})'
                          : 'KOT',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                ElevatedButton(
                  onPressed: controller.hasSelectedItems
                      ? () => controller.showConfirmOrderDialog(
                          PosOrderAction.hold,
                        )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.onSurface,
                    elevation: 0,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.symmetric(
                      horizontal: _isDesktopPlatform ? 14 : 12,
                      vertical: _isDesktopPlatform ? 14 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(
                        _isDesktopPlatform ? _desktopRadius : 12,
                      ),
                    ),
                  ),
                  child: Text(
                    secondaryLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: controller.hasSelectedItems
                      ? () => controller.showConfirmOrderDialog(
                          PosOrderAction.bill,
                        )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: AppColor.white,
                    elevation: 0,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.symmetric(
                      horizontal: _isDesktopPlatform ? 14 : 12,
                      vertical: _isDesktopPlatform ? 14 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        _isDesktopPlatform ? _desktopRadius : 12,
                      ),
                    ),
                  ),
                  child: Text(
                    primaryLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  bool _canShowBackButton(BuildContext context) {
    return Modular.to.canPop() || Navigator.of(context).canPop();
  }

  Future<bool> _showLeaveConfirmationDialog(BuildContext context) async {
    if (!controller.hasSelectedItems) {
      return true;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          constraints: const BoxConstraints(maxWidth: 360),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          title: const Text('Discard order?'),
          content: const Text(
            'You have unsaved order changes. Are you sure you want to leave this screen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Stay'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
    return shouldLeave ?? false;
  }
}

class _OrderTypeBar extends StatelessWidget {
  final AddOrderController controller;
  final Widget Function(String source) orderSourceIcon;

  const _OrderTypeBar({
    required this.controller,
    required this.orderSourceIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final selected = controller.selectedOrderSource.value;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: controller.ordersList.map((source) {
              final isSelected = selected == source;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      orderSourceIcon(source),
                      const SizedBox(width: 8),
                      Text(source),
                    ],
                  ),
                  selected: isSelected,
                  onSelected:
                      controller.isFromTableScreen.value && source != 'Dine In'
                      ? null
                      : (_) => controller.setOrderSource(source),
                  selectedColor: AppColor.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColor.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? AppColor.primary
                        : theme.colorScheme.outline.withOpacity(0.4),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }
}

class _CartPanel extends StatelessWidget {
  final AddOrderController controller;

  const _CartPanel({required this.controller});

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? 0}') ?? 0.0;
  }

  Widget _row(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: strong ? Colors.black87 : Colors.grey[700],
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.8,
              color: strong ? Colors.black87 : Colors.grey[800],
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Obx(() {
      controller.orderDetailsVersion.value;
      controller.selectedOrderSource.value;
      controller.showAddDetailsOnCreateOrder.value;
      final entries = controller.itemQuantities.entries
          .where((e) => e.value > 0)
          .toList();

      final cartItems = <Map<String, dynamic>>[];
      for (final entry in entries) {
        final parsed = PosCartLine.fromKey(entry.key);
        if (!controller.allItemsMap.containsKey(parsed.itemId)) continue;
        final price = controller.cartLineUnitPrice(entry.key);
        final sent = controller.kotPrintedQuantities[entry.key] ?? 0;
        final pending = entry.value - sent;
        cartItems.add({
          'id': entry.key,
          'name': controller.cartLineLabel(entry.key),
          'qty': entry.value,
          'pendingKot': pending,
          'price': price,
          'total': price * entry.value,
          'image': controller.allItemsMap[parsed.itemId]?.itemImage ?? '',
          'remark': controller.itemRemarks[entry.key] ?? '',
        });
      }

      final selectedTable = (controller.orderDetails['tableNumber'] ?? '')
          .toString()
          .trim();
      final isDineIn =
          controller.selectedOrderSource.value.toLowerCase() == 'dine in';

      return Container(
        margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.6),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Bill #${controller.displayBillNumber}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      if (controller.isEdit.value)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Running',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isDineIn && HomeMainRoutes.outletShowsTables())
                    controller.availableTables.isEmpty
                        ? (selectedTable.isEmpty
                              ? const SizedBox.shrink()
                              : Text(
                                  'Table: $selectedTable',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ))
                        : AppDropdownFormField2<String>(
                            value: selectedTable.isEmpty
                                ? null
                                : controller.availableTables.any(
                                    (t) => t.displayName == selectedTable,
                                  )
                                ? selectedTable
                                : null,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: loc.table_number,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: controller.availableTables
                                .map(
                                  (t) => DropdownItem(
                                    value: t.displayName,
                                    child: Text(t.displayName),
                                  ),
                                )
                                .toList(),
                            onChanged: controller.setTableNumber,
                          ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (controller.showAddDetailsOnCreateOrder.value)
                        TextButton.icon(
                          onPressed: () async {
                            final result = await Modular.to.pushNamed(
                              HomeMainRoutes.orderDetails,
                              arguments: {
                                ...controller.orderDetails,
                                'orderFrom':
                                    controller.selectedOrderSource.value,
                                'totalAmount': controller.totalAmount.value,
                              },
                            );
                            if (result != null &&
                                result is CreateorderRequest) {
                              controller.setOrderDetails(result.toJson());
                            }
                          },
                          icon: const Icon(
                            Icons.receipt_long_outlined,
                            size: 18,
                          ),
                          label: Text(loc.add_details),
                        ),
                      TextButton.icon(
                        onPressed: controller.showRemarkDialog,
                        icon: const Icon(Icons.note_alt_outlined, size: 18),
                        label: const Text('Remark'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                      child: Text(
                        'Tap items to add to order',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: cartItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 14),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final pendingKot = item['pendingKot'] as int;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${(item['price'] as double).toStringAsFixed(2)} × ${item['qty']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (pendingKot > 0 &&
                                      controller.isKotFeatureActive)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '$pendingKot new for kitchen',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFE65100),
                                        ),
                                      ),
                                    ),
                                  if ((item['remark'] as String).isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '📝 ${item['remark']}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Item remark',
                              icon: Icon(
                                (item['remark'] as String).isNotEmpty
                                    ? Icons.chat_bubble
                                    : Icons.chat_bubble_outline,
                                size: 20,
                                color: (item['remark'] as String).isNotEmpty
                                    ? AppColor.primary
                                    : Colors.grey,
                              ),
                              onPressed: () => controller.showItemRemarkDialog(
                                item['id'] as String,
                                item['name'] as String,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    splashRadius: 16,
                                    onPressed: () =>
                                        controller.decrementItemQuantity(
                                          item['id'] as String,
                                        ),
                                  ),
                                  Text(
                                    '${item['qty']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    splashRadius: 16,
                                    onPressed: () =>
                                        controller.incrementItemQuantity(
                                          item['id'] as String,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₹${(item['total'] as double).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _PaymentSection(controller: controller, loc: loc),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row(
                    'Subtotal',
                    '₹${controller.subtotal.value.toStringAsFixed(2)}',
                  ),
                  _row(
                    'Tax',
                    '₹${controller.totalTax.value.toStringAsFixed(2)}',
                  ),
                  _row(
                    'Discount',
                    '-₹${controller.appliedDiscountAmount().toStringAsFixed(2)}',
                  ),
                  // _row(
                  //   'Service',
                  //   '₹${_num(controller.orderDetails['serviceCharge']).toStringAsFixed(2)}',
                  // ),
                  const SizedBox(height: 6),
                  _row(
                    loc.total_amount,
                    '₹${controller.totalAmount.value.toStringAsFixed(2)}',
                    strong: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${controller.totalSelectedQuantity} items · ${controller.selectedItemsCount} SKU',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PaymentSection extends StatelessWidget {
  final AddOrderController controller;
  final AppLocalizations loc;

  const _PaymentSection({required this.controller, required this.loc});

  static const Set<String> _allowedPaymentMethods = {'cash', 'card', 'upi'};

  String _normalizePaymentMethod(String value) {
    final normalized = value.trim().toLowerCase();
    return _allowedPaymentMethods.contains(normalized) ? normalized : 'cash';
  }

  Widget _paymentSvgIcon(String method, {double size = 20}) {
    switch (_normalizePaymentMethod(method)) {
      case 'card':
        return Assets.svg.cardIcon.svg(width: size, height: size);
      case 'upi':
        return Assets.svg.upiIcon.svg(width: size, height: size);
      case 'cash':
      default:
        return Assets.svg.cashIcon.svg(width: size, height: size);
    }
  }

  List<(String method, String label)> get _paymentMethods => [
    ('cash', loc.cash),
    ('card', loc.card),
    ('upi', loc.upi),
  ];

  Widget _buildPaymentMethodWrap({
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _paymentMethods.map((entry) {
        final method = entry.$1;
        final label = entry.$2;
        final isSelected = selected == method;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _paymentSvgIcon(method, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => onSelected(method),
          selectedColor: AppColor.primary.withOpacity(0.15),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColor.primary : Colors.grey[700],
          ),
          side: BorderSide(
            color: isSelected
                ? AppColor.primary
                : Colors.grey.shade400.withOpacity(0.6),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      controller.orderDetailsVersion.value;
      controller.totalAmount.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.payment_received_in,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Split',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Switch(
                value: controller.useSplitPayment.value,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: controller.setUseSplitPayment,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!controller.useSplitPayment.value)
            _buildPaymentMethodWrap(
              selected: _normalizePaymentMethod(
                controller.paymentReceivedIn.value,
              ),
              onSelected: controller.setPaymentMethod,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        '₹${controller.totalAmount.value.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...controller.splitPayments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final payment = entry.value;
                  return _buildSplitPaymentItem(index, payment);
                }),
                Builder(
                  builder: (context) {
                    final remaining = controller.remainingPaymentAmount;
                    final bg = remaining < 0
                        ? Colors.red[50]
                        : remaining > 0.01
                        ? Colors.orange[50]
                        : Colors.green[50];
                    final border = remaining < 0
                        ? Colors.red[300]!
                        : remaining > 0.01
                        ? Colors.orange[300]!
                        : Colors.green[300]!;
                    final fg = remaining < 0
                        ? Colors.red[900]
                        : remaining > 0.01
                        ? Colors.orange[900]
                        : Colors.green[900];

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            remaining < 0
                                ? 'Excess'
                                : remaining > 0.01
                                ? 'Remaining'
                                : 'Complete',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: fg,
                              fontSize: 12.5,
                            ),
                          ),
                          Text(
                            '₹${remaining.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: fg,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddSplitPaymentDialog(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Payment'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      );
    });
  }

  Widget _buildSplitPaymentItem(int index, SplitPayment payment) {
    final safeMethod = _normalizePaymentMethod(payment.paymentMethod);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPaymentMethodWrap(
                  selected: safeMethod,
                  onSelected: (method) {
                    controller.updateSplitPayment(
                      index,
                      SplitPayment(
                        paymentMethod: method,
                        amount: payment.amount,
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => controller.removeSplitPayment(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: payment.amount.toStringAsFixed(2),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '₹',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              controller.updateSplitPayment(
                index,
                SplitPayment(
                  paymentMethod: payment.paymentMethod,
                  amount: amount,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddSplitPaymentDialog(BuildContext context) {
    final amountController = TextEditingController();
    var selectedMethod = 'cash';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildPaymentMethodWrap(
                selected: selectedMethod,
                onSelected: (method) {
                  setDialogState(() => selectedMethod = method);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount > 0) {
                  controller.addSplitPayment(selectedMethod, amount);
                  Navigator.of(dialogCtx).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

const double _wrapItemSpacing = 12;

/// Fits item cards to the available row width so [Wrap] rows have no trailing gap.
double resolveWrapItemCardWidth(
  double availableWidth, {
  double spacing = _wrapItemSpacing,
  double minWidth = 130,
}) {
  if (availableWidth <= minWidth) return availableWidth;

  var columns = 1;
  for (var c = 2; c <= 20; c++) {
    final width = (availableWidth - spacing * (c - 1)) / c;
    if (width < minWidth) break;
    columns = c;
  }
  return (availableWidth - spacing * (columns - 1)) / columns;
}

class AddItemCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double cardWidth;

  const AddItemCard({
    super.key,
    required this.label,
    required this.onTap,
    this.cardWidth = 150,
  });

  @override
  Widget build(BuildContext context) {
    if (!StaffAccess.canCreateProducts) return const SizedBox.shrink();

    final isDesktop =
        GetPlatform.isWindows || GetPlatform.isMacOS || GetPlatform.isLinux;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isDesktop ? 10 : 16),
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(isDesktop ? 10 : 16),
          border: Border.all(
            color: isDesktop ? Colors.grey[300]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDesktop ? 0.015 : 0.02),
              blurRadius: isDesktop ? 3 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(isDesktop ? 10 : 16),
              ),
              child: SizedBox(
                height: 110,
                child: Container(
                  color: const Color(0xFFF5F5F5),
                  child: Center(
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF6A3D),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹0.00',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF6A3D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.remove,
                              size: 18,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            '0',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF6A3D),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddMenuAiCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double cardWidth;

  const AddMenuAiCard({
    super.key,
    required this.label,
    required this.onTap,
    this.cardWidth = 150,
  });

  @override
  Widget build(BuildContext context) {
    if (!StaffAccess.canCreateProducts) return const SizedBox.shrink();

    final isDesktop =
        GetPlatform.isWindows || GetPlatform.isMacOS || GetPlatform.isLinux;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isDesktop ? 10 : 16),
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(isDesktop ? 10 : 16),
          border: Border.all(
            color: isDesktop ? Colors.grey[300]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDesktop ? 0.015 : 0.02),
              blurRadius: isDesktop ? 3 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(isDesktop ? 10 : 16),
              ),
              child: SizedBox(
                height: 110,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF9D6CFF), Color(0xFF5E8EFF)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Maintain same vertical rhythm as item cards
                  const Text(
                    '₹0.00',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF6A3D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.remove,
                              size: 18,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFF6A3D),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.add,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderItemCard extends StatelessWidget {
  final String itemName;
  final double price;
  final String? imageUrl;
  final String posColor;
  final int quantity;
  final double cardWidth;
  final VoidCallback onDelete;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback? onQuickAdd;

  const OrderItemCard({
    super.key,
    required this.itemName,
    required this.price,
    required this.onDelete,
    required this.onIncrement,
    required this.onDecrement,
    this.onQuickAdd,
    this.imageUrl,
    this.posColor = '',
    this.quantity = 0,
    this.cardWidth = 150,
  });

  Color? get _posColor {
    if (posColor.isEmpty) return null;
    var value = posColor.replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return null;
    return Color(int.parse(value, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        GetPlatform.isWindows || GetPlatform.isMacOS || GetPlatform.isLinux;
    final tileColor = _posColor;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return InkWell(
      onTap: onQuickAdd ?? onIncrement,
      borderRadius: BorderRadius.circular(isDesktop ? 10 : 16),
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(isDesktop ? 10 : 16),
          border: Border.all(
            color: quantity > 0
                ? AppColor.primary.withOpacity(0.55)
                : (isDesktop ? Colors.grey[300]! : Colors.grey[200]!),
            width: quantity > 0 ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDesktop ? 0.015 : 0.02),
              blurRadius: isDesktop ? 3 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(isDesktop ? 10 : 16),
              ),
              child: SizedBox(
                height: 110,
                child: hasImage
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => tileColor != null
                            ? ColoredBox(color: tileColor)
                            : Assets.svg.placeholder.svg(fit: BoxFit.cover),
                      )
                    : tileColor != null
                    ? ColoredBox(
                        color: tileColor,
                        child: Center(
                          child: Text(
                            itemName.isNotEmpty
                                ? itemName.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : Assets.svg.placeholder.svg(fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF6A3D), // light orange like reference
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: quantity > 0 ? onDecrement : null,
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.remove,
                                size: 18,
                                color: quantity > 0
                                    ? Colors.grey[800]
                                    : Colors.grey[400],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            quantity.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: onIncrement,
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFF6A3D),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
