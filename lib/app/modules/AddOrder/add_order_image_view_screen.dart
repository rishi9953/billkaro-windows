import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/config/config.dart';

class AddOrderImageViewScreen extends StatefulWidget {
  final AddOrderController controller;
  const AddOrderImageViewScreen({super.key, required this.controller});

  @override
  State<AddOrderImageViewScreen> createState() => _AddOrderImageViewScreenState();
}

class _AddOrderImageViewScreenState extends State<AddOrderImageViewScreen> {
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
      if (widget.controller.selectedCategoryId.value == 'none' &&
          widget.controller.searchQuery.value.isEmpty) {
        widget.controller.loadMoreItems();
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
    var loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Search Bar
          Obx(() {
            if (!widget.controller.showSearchBar.value) {
              return SizedBox.shrink();
            }

            return Row(
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
                        widget.controller.filterItemsBySearch(value.trim());
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    widget.controller.showSearchBarFunction();
                  },
                ),
              ],
            );
          }),

          // Quick Add Item Button
          Obx(() {
            if (widget.controller.showSearchBar.value) {
              return SizedBox.shrink();
            }
            return Column(
              children: [
                Gap(10),
                InkWell(
                  onTap: widget.controller.showQuickAddItemBottomSheet,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.add_circle, color: AppColor.primary),
                        Gap(10),
                        Text('Quick Add Item'),
                      ],
                    ),
                  ),
                ),
                Gap(10),
              ],
            );
          }),

          // Category Filters
          Obx(() {
            if (widget.controller.showSearchBar.value) {
              return SizedBox.shrink();
            }
            return Container(
              height: 50,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Search Button
                    OutlinedButton(
                      onPressed: () {
                        widget.controller.showSearchBarFunction();
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
                    SizedBox(width: 10),
                    // All Button
                    OutlinedButton(
                      onPressed: () {
                        widget.controller.selectCategory('none');
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: widget.controller.selectedCategory.value
                                    .toLowerCase() ==
                                'none'
                            ? AppColor.secondaryPrimary.withOpacity(0.5)
                            : Colors.transparent,
                        side: BorderSide(
                          color: widget.controller.selectedCategory.value
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
                    SizedBox(width: 10),
                    // Category Buttons
                    ...widget.controller.categories.map((category) {
                      return Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: OutlinedButton(
                          onPressed: () {
                            widget.controller.selectCategory(
                              category.categoryName.toLowerCase(),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: widget.controller.selectedCategory
                                        .value ==
                                    category.categoryName.toLowerCase()
                                ? AppColor.secondaryPrimary.withOpacity(0.5)
                                : Colors.transparent,
                            side: BorderSide(
                              color: widget.controller.selectedCategory.value ==
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
                        ),
                      );
                    }),
                    // Add Category Button
                    OutlinedButton(
                      onPressed: () {
                        Get.toNamed(
                          AppRoute.addCategory,
                          arguments: {
                            'voiceCallback': widget.controller.getCategories,
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

          Gap(10),

          // Items Display - Image View
          Expanded(
            child: Obx(() {
              if (widget.controller.items.isEmpty) {
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
                            onTap: () => widget.controller.addMenuUsingAI(),
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
                                mainAxisAlignment: MainAxisAlignment.center,
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
                            onTap: () => widget.controller.addItem('none'),
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
                                mainAxisAlignment: MainAxisAlignment.center,
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
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                controller: scrollController,
                padding: const EdgeInsets.all(8),
                child: Obx(() {
                  // When "ALL" is selected, show all categories with their items
                  if (widget.controller.selectedCategory.value.toLowerCase() ==
                      'none') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show all categories with items
                        ...widget.controller.categories.map((category) {
                          final categoryItems = widget.controller.items
                              .where(
                                (item) =>
                                    item.category.toLowerCase() ==
                                    category.categoryName.toLowerCase(),
                              )
                              .toList();

                          if (categoryItems.isEmpty) {
                            return SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  category.categoryName.capitalize ?? '',
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
                                            item.itemName.capitalize ?? '',
                                        price: double.tryParse(
                                              item.salePrice.toString(),
                                            ) ??
                                            0.0,
                                        quantity: widget.controller
                                            .getItemQuantity(item.id),
                                        onDelete: () {
                                          widget.controller.itemQuantities
                                              .remove(item.id);
                                        },
                                        onIncrement: () {
                                          widget.controller
                                              .incrementItemQuantity(item.id);
                                        },
                                        onDecrement: () {
                                          widget.controller
                                              .decrementItemQuantity(item.id);
                                        },
                                      ),
                                    );
                                  }),
                                  GestureDetector(
                                    onTap: () => widget.controller.addItem(
                                      category.categoryName,
                                    ),
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
                              const SizedBox(height: 16),
                            ],
                          );
                        }),

                        // Show "None" category items
                        Builder(
                          builder: (context) {
                            final noneItems = widget.controller.items
                                .where((item) => item.category.toLowerCase() == 'none')
                                .toList();

                            if (noneItems.isEmpty) {
                              return SizedBox.shrink();
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      onTap: () =>
                                          widget.controller.addMenuUsingAI(),
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
                                          borderRadius:
                                              BorderRadius.circular(10),
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

                                    // Add Item Card
                                    GestureDetector(
                                      onTap: () =>
                                          widget.controller.addItem('none'),
                                      child: Container(
                                        padding: const EdgeInsets.all(8.0),
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
                                                fontWeight: FontWeight.w500,
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
                                          imageUrl: item.itemImage,
                                          itemName:
                                              item.itemName.capitalize ?? '',
                                          price: double.tryParse(
                                                item.salePrice.toString(),
                                              ) ??
                                              0.0,
                                          quantity: widget.controller
                                              .getItemQuantity(item.id),
                                          onDelete: () {
                                            widget.controller.itemQuantities
                                                .remove(item.id);
                                          },
                                          onIncrement: () {
                                            widget.controller
                                                .incrementItemQuantity(item.id);
                                          },
                                          onDecrement: () {
                                            widget.controller
                                                .decrementItemQuantity(item.id);
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
                          if (widget.controller.isLoadingMore.value) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return SizedBox.shrink();
                        }),
                      ],
                    );
                  } else {
                    // Show only selected category items
                    final selectedItems = widget.controller.items
                        .where(
                          (item) =>
                              item.category.toLowerCase() ==
                              widget.controller.selectedCategory.value
                                  .toLowerCase(),
                        )
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                          ),
                          child: Text(
                            widget.controller.selectedCategory.value.capitalize ??
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
                                  itemName: item.itemName.capitalize ?? '',
                                  price: double.tryParse(
                                        item.salePrice.toString(),
                                      ) ??
                                      0.0,
                                  quantity: widget.controller.getItemQuantity(
                                    item.id,
                                  ),
                                  onDelete: () {
                                    widget.controller.itemQuantities.remove(
                                      item.id,
                                    );
                                  },
                                  onIncrement: () {
                                    widget.controller.incrementItemQuantity(
                                      item.id,
                                    );
                                  },
                                  onDecrement: () {
                                    widget.controller.decrementItemQuantity(
                                      item.id,
                                    );
                                  },
                                ),
                              );
                            }),
                            GestureDetector(
                              onTap: () => widget.controller.addItem(
                                widget.controller.selectedCategory.value,
                              ),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                    );
                  }
                }),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// OrderItemCard widget (same as in add_order_list_screen.dart)
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
                child: CachedNetworkImage(
                  imageUrl: imageUrl ?? '',
                  width: 130,
                  height: 160,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Center(
                    child: Assets.svg.placeholder.svg(fit: BoxFit.cover),
                  ),
                  placeholder: (_, __) => Center(
                    child: CircularProgressIndicator(),
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
