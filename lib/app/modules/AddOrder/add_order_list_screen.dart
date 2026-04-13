import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dotted_border/dotted_border.dart';

class AddOrderListScreen extends StatefulWidget {
  final AddOrderController controller;
  const AddOrderListScreen({super.key, required this.controller});

  @override
  State<AddOrderListScreen> createState() => _AddOrderListScreenState();
}

class _AddOrderListScreenState extends State<AddOrderListScreen> {
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                  ),
                  onChanged: (value) {
                    widget.controller.filterItemsBySearch(value.trim());
                  },
                ),
              ),
              const SizedBox(width: 8),
              Obx(() {
                if (widget.controller.searchQuery.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    widget.controller.filterItemsBySearch('');
                  },
                );
              }),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      right: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  child: Obx(() {
                    return Column(
                      children: [
                        Expanded(
                          child: ListView(
                            children: [
                              InkWell(
                                onTap: () {
                                  widget.controller.selectCategory('none');
                                },
                                child: Container(
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  width: double.infinity,
                                  color:
                                      widget.controller.selectedCategory.value
                                              .toLowerCase() ==
                                          'none'
                                      ? AppColor.secondaryPrimary.withOpacity(
                                          0.5,
                                        )
                                      : Colors.transparent,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'All',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            widget
                                                    .controller
                                                    .selectedCategory
                                                    .value
                                                    .toLowerCase() ==
                                                'none'
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color:
                                            widget
                                                    .controller
                                                    .selectedCategory
                                                    .value
                                                    .toLowerCase() ==
                                                'none'
                                            ? AppColor.primary
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ...widget.controller.categories.map((category) {
                                final isSelected =
                                    widget.controller.selectedCategory.value ==
                                    category.categoryName.toLowerCase();
                                return InkWell(
                                  onTap: () {
                                    widget.controller.selectCategory(
                                      category.categoryName.toLowerCase(),
                                    );
                                  },
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 50,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    width: double.infinity,
                                    alignment: Alignment.centerLeft,
                                    color: isSelected
                                        ? AppColor.secondaryPrimary.withOpacity(
                                            0.5,
                                          )
                                        : Colors.transparent,
                                    child: Text(
                                      category.categoryName.capitalize ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? AppColor.primary
                                            : Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            final appPref = Get.find<AppPref>();
                            if (!hasTrialOrSubscription(appPref)) {
                              checkSubscription();
                              return;
                            }
                            await Modular.to.pushNamed(
                              HomeMainRoutes.category,
                              arguments: {
                                'voiceCallback':
                                    widget.controller.getCategories,
                              },
                            );
                          },
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 50),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            width: double.infinity,
                            alignment: Alignment.centerLeft,

                            child: Text(
                              'Add Category',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColor.primary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              Expanded(
                flex: 7,
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Obx(() {
                        // widget.controller.itemQuantities;

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              widget.controller.items.length +
                              (widget.controller.isLoadingMore.value ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == widget.controller.items.length) {
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final item = widget.controller.items[index];
                            return Obx(
                              () => OrderItemCard(
                                imageUrl: item.itemImage,
                                itemName: item.itemName.capitalize ?? '',
                                price:
                                    double.tryParse(
                                      item.salePrice.toString(),
                                    ) ??
                                    0.0,
                                quantity: widget.controller.getItemQuantity(
                                  item.id,
                                ),
                                onDelete: () {
                                  widget.controller.removeItemCompletely(
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
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return Divider(color: AppColor.grey.shade300);
                          },
                        );
                      }),

                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: InkWell(
                            onTap: () =>
                                widget.controller.showQuickAddItemBottomSheet(),
                            child: DottedBorder(
                              options: RoundedRectDottedBorderOptions(
                                color: AppColor.primary.withOpacity(0.2),
                                strokeWidth: 1,
                                dashPattern: const [8, 4],
                                radius: const Radius.circular(10),
                              ),
                              child: Container(
                                height: 80,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 10),
                                    Icon(Icons.add_circle_outline),
                                    const SizedBox(height: 10),
                                    Text('Quick Add Item'),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: AppColor.white,
      child: Row(
        children: [
          // Item Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: Icon(Icons.image, color: Colors.grey[400], size: 24),
                  ),
          ),
          const SizedBox(width: 12),
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColor.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Quantity Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              quantity > 0
                  ? Row(
                      children: [
                        InkWell(
                          onTap: onDecrement,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColor.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColor.primary,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.remove,
                              size: 18,
                              color: AppColor.primary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$quantity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onIncrement,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColor.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColor.primary,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 18,
                              color: AppColor.primary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : InkWell(
                      onTap: onIncrement,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 60,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: AppColor.primary,
                        ),
                        child: Text(
                          'ADD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColor.white,
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
}
