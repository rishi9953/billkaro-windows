import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_list_screen.dart';
import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/material.dart';

class AddOrderScreen extends StatefulWidget {
  AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final controller = Get.put(AddOrderController());
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Obx(() {
          if (controller.selectedOrderSource.value.isEmpty) {
            return Text(
              loc.add_Order,
              style: TextStyle(
                color: AppColor.white,
                fontSize: 20,
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
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gap(20),
              controller.showIcon(),
            ],
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColor.white),
            onPressed: controller.openSettings,
          ),
          Obx(() {
            if (controller.items.isEmpty) {
              return Container();
            }
            return InkWell(
              onTap: () async {
                final result = await Get.toNamed(
                  AppRoute.orderDetails,
                  arguments: {
                    ...controller.orderDetails,
                    'orderFrom': controller.selectedOrderSource.value,
                    'totalAmount': controller.totalAmount.value,
                  },
                );
                if (result != null && result is CreateorderRequest) {
                  controller.orderDetails = result.toJson();
                  debugPrint(controller.orderDetails.toString());
                }
              },
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12, right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
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
      body: Column(
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
              padding: const EdgeInsets.all(8.0),
              child: controller.showSearchBar.value
                  ? Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search items...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 12,
                                ),
                              ),
                              onChanged: (value) {
                                controller.filterItemsBySearch(value.trim());
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
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
                        spacing: 10,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              controller.showSearchBarFunction();
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(25, 25),
                              padding: EdgeInsets.all(12),
                            ),
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
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  controller.selectedCategory.value
                                          .toLowerCase() ==
                                      'none'
                                  ? AppColor.secondaryPrimary.withOpacity(0.5)
                                  : Colors.transparent,
                              side: BorderSide(
                                color:
                                    controller.selectedCategory.value
                                            .toLowerCase() ==
                                        'none'
                                    ? AppColor.secondaryPrimary
                                    : AppColor.primary,
                              ),
                              minimumSize: Size(25, 25),
                              padding: EdgeInsets.all(12),
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
                              style: OutlinedButton.styleFrom(
                                backgroundColor:
                                    controller.selectedCategory.value ==
                                        category.categoryName.toLowerCase()
                                    ? AppColor.secondaryPrimary.withOpacity(0.5)
                                    : Colors.transparent,
                                side: BorderSide(
                                  color:
                                      controller.selectedCategory.value ==
                                          category.categoryName.toLowerCase()
                                      ? AppColor.secondaryPrimary
                                      : AppColor.primary,
                                ),
                                minimumSize: Size(25, 25),
                                padding: EdgeInsets.all(12),
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
                              Get.toNamed(
                                AppRoute.addCategory,
                                arguments: {
                                  'voiceCallback': controller.getCategories,
                                },
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(25, 25),
                              padding: EdgeInsets.all(12),
                            ),
                            child: Icon(Icons.add),
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
                                  GestureDetector(
                                    onTap: () => controller.addMenuUsingAI(),
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      height: 160,
                                      width: 130,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xFF9D6CFF),
                                            Color(0xFF5E8EFF),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.auto_awesome,
                                            color: Colors.white,
                                          ),
                                          Text(
                                            loc.add_your_menu_using_photos,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Add Item
                                  GestureDetector(
                                    onTap: () => controller.addItem('none'),
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      height: 160,
                                      width: 130,
                                      decoration: BoxDecoration(
                                        color: AppColor.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add,
                                            color: Colors.grey[600],
                                            size: 15,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            loc.addItems,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
                              padding: const EdgeInsets.all(8),
                              child: Obx(() {
                                // When "ALL" is selected, show all categories with their items
                                if (controller.selectedCategory.value
                                        .toLowerCase() ==
                                    'none') {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                                            .itemQuantities
                                                            .remove(item.id);
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
                                                GestureDetector(
                                                  onTap: () =>
                                                      controller.addItem(
                                                        category.categoryName,
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          8.0,
                                                        ),
                                                    height: 160,
                                                    width: 130,
                                                    decoration: BoxDecoration(
                                                      color: AppColor.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      border: Border.all(
                                                        color:
                                                            Colors.grey[300]!,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.add,
                                                          color:
                                                              Colors.grey[600],
                                                          size: 15,
                                                        ),
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        Text(
                                                          loc.addItems,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                          ],
                                        );
                                      }),

                                      // Show "None" category items
                                      Builder(
                                        builder: (context) {
                                          final noneItems = controller.items
                                              .where(
                                                (item) =>
                                                    item.category.toLowerCase() == 'none',
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
                                                  // Add Photo Card
                                                  GestureDetector(
                                                    onTap: () => controller
                                                        .addMenuUsingAI(),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      height: 160,
                                                      width: 130,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                              begin: Alignment
                                                                  .topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                              colors: [
                                                                Color(
                                                                  0xFF9D6CFF,
                                                                ),
                                                                Color(
                                                                  0xFF5E8EFF,
                                                                ),
                                                              ],
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          const Icon(
                                                            Icons.auto_awesome,
                                                            color: Colors.white,
                                                          ),
                                                          Text(
                                                            loc.add_your_menu_using_photos,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                  // Add Item Card
                                                  GestureDetector(
                                                    onTap: () => controller
                                                        .addItem('none'),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      height: 160,
                                                      width: 130,
                                                      decoration: BoxDecoration(
                                                        color: AppColor.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              Colors.grey[300]!,
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.add,
                                                            color: Colors
                                                                .grey[600],
                                                            size: 15,
                                                          ),
                                                          const SizedBox(
                                                            height: 16,
                                                          ),
                                                          Text(
                                                            loc.addItems,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[600],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),

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
                                                              .itemQuantities
                                                              .remove(item.id);
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
                                                ],
                                              ),
                                            ],
                                          );
                                        },
                                      ),

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
                                  if (controller.selectedCategory.value.toLowerCase() != 'none') {
                                    final noneCategoryItems = controller.items
                                        .where(
                                          (item) =>
                                              item.category.toLowerCase() == 'none',
                                        )
                                        .toList();
                                    selectedItems.addAll(noneCategoryItems);
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
                                                  controller.itemQuantities
                                                      .remove(item.id);
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
                                          GestureDetector(
                                            onTap: () => controller.addItem(
                                              controller.selectedCategory.value,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              height: 160,
                                              width: 130,
                                              decoration: BoxDecoration(
                                                color: AppColor.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.grey[300]!,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.add,
                                                    color: Colors.grey[600],
                                                    size: 15,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    loc.addItems,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
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
          Obx(() {
            // Only show summary if there are selected items (quantity >= 1)
            if (!controller.hasSelectedItems) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColor.primary.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            size: 18,
                            color: AppColor.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            loc.order_summary,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${controller.selectedItemsCount} ${controller.selectedItemsCount == 1 ? loc.item_selected : loc.items_selected}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${loc.total_quantity}: ${controller.totalSelectedQuantity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        loc.total_amount,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${controller.totalAmount.value.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        color: theme.colorScheme.surface,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: controller.showConfirmOrderBottomSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  controller.isKOT.value ? loc.kot_and_hold : loc.save_and_hold,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: controller.showConfirmOrderBottomSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: AppColor.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  controller.isKOT.value ? "KOT & Bill" : loc.save_and_bill,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 130,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl ?? '',
                  width: 130,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Assets.svg.placeholder.svg(fit: BoxFit.cover),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PRICE TAG
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₹$price',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),
                    // QUANTITY CONTROLS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        quantity > 0
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    // decrement
                                    InkWell(
                                      onTap: onDecrement,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.remove,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // increment
                                    InkWell(
                                      onTap: onIncrement,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add, size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : InkWell(
                                onTap: onIncrement,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, size: 18),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // ITEM NAME
        Padding(
          padding: const EdgeInsets.only(left: 6.0),
          child: Text(
            itemName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
