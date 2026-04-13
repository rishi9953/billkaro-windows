import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_list_screen.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/config/config.dart';
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
    if (Get.isRegistered<AddOrderController>()) {
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
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: _isDesktopPlatform ? 12 : 10,
                        mainAxisAlignment: MainAxisAlignment.start,
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
                          OutlinedButton(
                            onPressed: () {
                              controller.selectCategory('none');
                            },
                            style: desktopButtonStyle.copyWith(
                              backgroundColor: WidgetStatePropertyAll(
                                controller.selectedCategory.value
                                            .toLowerCase() ==
                                        'none'
                                    ? AppColor.secondaryPrimary.withOpacity(0.5)
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
                                          category.categoryName.toLowerCase()
                                      ? AppColor.secondaryPrimary.withOpacity(
                                          0.5,
                                        )
                                      : Colors.transparent,
                                ),
                                side: WidgetStatePropertyAll(
                                  BorderSide(
                                    color:
                                        controller.selectedCategory.value ==
                                            category.categoryName.toLowerCase()
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
                          OutlinedButton(
                            onPressed: () {
                              Modular.to.pushNamed(
                                HomeMainRoutes.category,
                                arguments: {
                                  'voiceCallback': controller.getCategories,
                                },
                              );
                              // Get.toNamed(
                              //   AppRoute.addCategory,
                              //   arguments: {
                              //     'voiceCallback': controller.getCategories,
                              //   },
                              // );
                            },
                            style: desktopButtonStyle,
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
            );
          }),
          Expanded(
            child: Obx(
              () => controller.isListView.value
                  ? AddOrderListScreen(controller: controller)
                  : Obx(() {
                      if (controller.items.isEmpty) {
                        // Empty State
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
                                    onTap: () => controller.addMenuUsingAI(),
                                  ),
                                  const SizedBox(width: 16),
                                  // Add Item
                                  AddItemCard(
                                    label: loc.addItems,
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
                                      // Show "None" category items FIRST (top)
                                      Builder(
                                        builder: (context) {
                                          final noneItems = controller.items
                                              .where(
                                                (item) =>
                                                    item.category
                                                        .toLowerCase() ==
                                                    'none',
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
                                                        imageUrl:
                                                            item.itemImage,
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
                                                            .getItemQuantity(
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

                                                  // Add Photo Card
                                                  AddMenuAiCard(
                                                    label: loc
                                                        .add_your_menu_using_photos,
                                                    onTap: () => controller
                                                        .addMenuUsingAI(),
                                                  ),

                                                  // Add Item Card
                                                  AddItemCard(
                                                    label: loc.addItems,
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
                                                      .toLowerCase(),
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
                                                      imageUrl: item.itemImage,
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
                                                          .getItemQuantity(
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
                                                imageUrl: item.itemImage,
                                                itemName:
                                                    item.itemName.capitalize ??
                                                    '',
                                                price:
                                                    double.tryParse(
                                                      item.salePrice.toString(),
                                                    ) ??
                                                    0.0,
                                                quantity: controller
                                                    .getItemQuantity(item.id),
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
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
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
            return PopupMenuButton<String>(
              tooltip: 'Change order source',
              onSelected: (value) {
                controller.selectedOrderSource.value = value;
              },
              itemBuilder: (context) {
                return controller.ordersList.map((source) {
                  final isSelected = source == selected;
                  return PopupMenuItem<String>(
                    value: source,
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
                          child: Text(source, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 4, top: 10, bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
            );
          }),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColor.white),
            onPressed: controller.openSettings,
          ),
          Obx(() {
            if (controller.items.isEmpty) {
              return Container();
            }
            if (!controller.isEdit.value &&
                !controller.showAddDetailsOnCreateOrder.value) {
              return Container();
            }
            return InkWell(
              onTap: () async {
                final result = await Modular.to.pushNamed(
                  HomeMainRoutes.orderDetails,
                  arguments: {
                    ...controller.orderDetails,
                    'orderFrom': controller.selectedOrderSource.value,
                    'totalAmount': controller.totalAmount.value,
                  },
                );
                // final result = await Get.toNamed(
                //   AppRoute.orderDetails,
                //   arguments: {
                //     ...controller.orderDetails,
                //     'orderFrom': controller.selectedOrderSource.value,
                //     'totalAmount': controller.totalAmount.value,
                //   },
                // );
                if (result != null && result is CreateorderRequest) {
                  controller.setOrderDetails(result.toJson());
                  debugPrint(controller.orderDetails.toString());
                }
              },
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12, right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    _isDesktopPlatform ? _desktopRadius : 6,
                  ),
                  border: Border.all(color: AppColor.white, width: 1),
                  color: AppColor.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Center(
                    child: Text(
                      loc.add_details,
                      style: TextStyle(
                        color: AppColor.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;

          if (!isWide) {
            // Mobile / narrow layout – keep existing single-column behaviour
            return buildMainContent();
          }

          // For wide layout, only show right cart panel when items are added
          return Obx(() {
            if (!controller.hasSelectedItems) {
              // No items → use full-width main content, hide cart panel
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1500),
                  child: buildMainContent(),
                ),
              );
            }

            // Desktop / wide layout – items on the left, cart panel on the right
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1500),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: buildMainContent()),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 390,
                      child: _CartPanel(controller: controller),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
      bottomNavigationBar: Obx(() {
        controller.itemQuantities.length;
        controller.isKOT.value;
        controller.homeController.selectedOutlet.value;
        final secondaryLabel = controller.isKotFeatureActive
            ? loc.kot_and_hold
            : loc.save_and_hold;
        final primaryLabel = controller.isKotFeatureActive
            ? loc.kot_and_bill
            : loc.save_and_bill;
        final showViewInvoice = controller.hasSelectedItems;

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
              mainAxisSize: MainAxisSize.max,
              children: [
                if (showViewInvoice) ...[
                  OutlinedButton(
                    onPressed: () => controller.viewInvoicePreview(),
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
                      'View Invoice',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                OutlinedButton(
                  onPressed: () =>
                      controller.showConfirmOrderBottomSheet('pending'),
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
                  child: Text(
                    secondaryLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () =>
                      controller.showConfirmOrderBottomSheet('closed'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, _windowsFooterButtonHeight),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    primaryLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

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
              if (showViewInvoice) ...[
                ElevatedButton(
                  onPressed: () => controller.viewInvoicePreview(),
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
                    'View Invoice',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              ElevatedButton(
                onPressed: () =>
                    controller.showConfirmOrderBottomSheet('pending'),
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
                onPressed: () =>
                    controller.showConfirmOrderBottomSheet('closed'),
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
    );
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

    return Obx(() {
      // Subscribe to customer/details updates from Order Details screen.
      controller.orderDetailsVersion.value;
      final entries = controller.itemQuantities.entries
          .where((e) => e.value > 0)
          .toList();

      final cartItems = <Map<String, dynamic>>[];
      for (final entry in entries) {
        final item = controller.allItemsMap[entry.key];
        if (item == null) continue;
        final price = double.tryParse(item.salePrice.toString()) ?? 0.0;
        cartItems.add({
          'id': item.id,
          'name': item.itemName,
          'qty': entry.value,
          'price': price,
          'total': price * entry.value,
          'image': item.itemImage,
        });
      }

      if (cartItems.isEmpty) {
        // No items in cart → hide the entire card
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.order_summary,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${controller.selectedItemsCount} ${controller.selectedItemsCount == 1 ? loc.item_selected : loc.items_selected}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Totals breakdown (cart summary)
            Builder(
              builder: (_) {
                final customerName =
                    (controller.orderDetails['customerName'] ?? '')
                        .toString()
                        .trim();
                final phoneNumber =
                    (controller.orderDetails['phoneNumber'] ?? '')
                        .toString()
                        .trim();
                final subtotal = controller.subtotal.value;
                final tax = controller.totalTax.value;
                final discount = _num(controller.orderDetails['discount']);
                final serviceCharge = _num(
                  controller.orderDetails['serviceCharge'],
                );
                final total = controller.totalAmount.value;

                return Column(
                  children: [
                    if (customerName.isNotEmpty) _row('Customer', customerName),
                    if (phoneNumber.isNotEmpty) _row('Phone', phoneNumber),
                    if (customerName.isNotEmpty || phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Divider(
                        height: 12,
                        color: Colors.black.withOpacity(0.08),
                      ),
                    ],
                    _row('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                    _row('Tax', '₹${tax.toStringAsFixed(2)}'),
                    _row('Discount', '-₹${discount.toStringAsFixed(2)}'),
                    _row(
                      'Service charge',
                      '₹${serviceCharge.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 6),
                    Divider(height: 12, color: Colors.black.withOpacity(0.08)),
                    _row(
                      loc.total_amount,
                      '₹${total.toStringAsFixed(2)}',
                      strong: true,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: cartItems.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Item image thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 46,
                          height: 46,
                          child:
                              (item['image'] as String?) == null ||
                                  (item['image'] as String).isEmpty
                              ? Assets.svg.placeholder.svg(fit: BoxFit.cover)
                              : Image.network(
                                  item['image'] as String,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Assets
                                      .svg
                                      .placeholder
                                      .svg(fit: BoxFit.cover),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${(item['price'] as double).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              splashRadius: 18,
                              onPressed: () => controller.decrementItemQuantity(
                                item['id'] as String,
                              ),
                            ),
                            Text(
                              (item['qty'] as int).toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              splashRadius: 18,
                              onPressed: () => controller.incrementItemQuantity(
                                item['id'] as String,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${(item['total'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          controller.removeItemCompletely(item['id'] as String);
                        },
                        child: Assets.svg.delete.svg(height: 20, width: 20),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.total_amount,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                Text(
                  '₹${controller.totalAmount.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class AddItemCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AddItemCard({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        GetPlatform.isWindows || GetPlatform.isMacOS || GetPlatform.isLinux;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isDesktop ? 10 : 16),
      child: Container(
        width: 150,
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

  const AddMenuAiCard({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        GetPlatform.isWindows || GetPlatform.isMacOS || GetPlatform.isLinux;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isDesktop ? 10 : 16),
      child: Container(
        width: 150,
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
  final int quantity;
  final VoidCallback onDelete;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const OrderItemCard({
    super.key,
    required this.itemName,
    required this.price,
    required this.onDelete,
    required this.onIncrement,
    required this.onDecrement,
    this.imageUrl,
    this.quantity = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        GetPlatform.isWindows || GetPlatform.isMacOS || GetPlatform.isLinux;
    return Container(
      width: 150,
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
          // Image area
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isDesktop ? 10 : 16),
            ),
            child: SizedBox(
              height: 110,
              child: imageUrl == null || imageUrl!.isEmpty
                  ? Assets.svg.placeholder.svg(fit: BoxFit.cover)
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Assets.svg.placeholder.svg(fit: BoxFit.cover),
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
    );
  }
}
