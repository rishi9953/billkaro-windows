import 'dart:math' as math;

import 'package:billkaro/app/modules/Promotions/promotions_controller.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/Modals/promotions/promotion_response.dart';
import 'package:billkaro/app/utils/promotion_engine.dart';
import 'package:billkaro/app/utils/promotion_types.dart';
import 'package:billkaro/config/config.dart';

class PromotionsScreen extends StatelessWidget {
  PromotionsScreen({super.key});

  final controller = Get.put(PromotionsController());

  static const _dialogRadius = 8.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        title: const Text('Offers & Promotions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateFlow(context),
        icon: const Icon(Icons.add),
        label: const Text('Create offer'),
      ),
      body: Obx(() {
        if (controller.promotions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'No offers yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'BOGO, discounts, free items & more',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _openCreateFlow(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create offer'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.promotions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final promo = controller.promotions[index];
            return _PromotionCard(
              promotion: promo,
              subtitle: controller.offerSummary(promo),
              onEdit: () => _openForm(context, existing: promo),
              onDelete: () => controller.deletePromotion(promo),
              onToggle: () => controller.toggleActive(promo),
            );
          },
        );
      }),
    );
  }

  Future<void> _openCreateFlow(BuildContext context) async {
    final type = await _pickOfferType(context);
    if (type == null || !context.mounted) return;
    _openForm(context, initialType: type);
  }

  Future<String?> _pickOfferType(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Get.dialog<String>(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_dialogRadius),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: AppColor.cardSurface,
        child: SizedBox(
          width: math.min(480, screenWidth - 40),
          height: screenHeight * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DialogHeader(
                title: 'Choose offer type',
                subtitle: 'Pick how this promotion should work',
                onClose: () => Get.back(),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: PromotionTypes.all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final type = PromotionTypes.all[index];
                    return _OfferTypeTile(
                      type: type,
                      onTap: () => Get.back(result: type),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openForm(
    BuildContext context, {
    PromotionData? existing,
    String? initialType,
  }) {
    controller.loadMenuItems();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_dialogRadius),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: AppColor.cardSurface,
        child: SizedBox(
          width: math.min(520, screenWidth - 40),
          height: screenHeight * 0.78,
          child: _PromotionFormDialog(
            controller: controller,
            existing: existing,
            initialType: initialType,
          ),
        ),
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.promotion,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final PromotionData promotion;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColor.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.secondaryPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_offer_outlined,
                    color: AppColor.secondaryPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    promotion.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),
                Switch(value: promotion.active, onChanged: (_) => onToggle()),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColor.secondaryPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                PromotionTypes.label(promotion.type),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColor.secondaryPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle.capitalize ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: AppColor.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppColor.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferTypeTile extends StatelessWidget {
  const _OfferTypeTile({required this.type, required this.onTap});

  final String type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.backGroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColor.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  PromotionTypes.icon(type),
                  color: AppColor.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PromotionTypes.label(type),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      PromotionTypes.example(type),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromotionFormDialog extends StatefulWidget {
  const _PromotionFormDialog({
    required this.controller,
    this.existing,
    this.initialType,
  });

  final PromotionsController controller;
  final PromotionData? existing;
  final String? initialType;

  @override
  State<_PromotionFormDialog> createState() => _PromotionFormDialogState();
}

class _PromotionFormDialogState extends State<_PromotionFormDialog> {
  late final TextEditingController nameController;
  late final TextEditingController amountController;
  late final TextEditingController buyQtyController;
  late final TextEditingController getQtyController;
  late final TextEditingController flatController;
  late final TextEditingController percentController;
  late final TextEditingController startTimeController;
  late final TextEditingController endTimeController;
  late final TextEditingController searchController;
  late final Set<String> selectedItemIds;
  late bool active;
  late String _selectedType;
  late bool _sameAsTrigger;
  String? _productItemId;
  String _searchQuery = '';
  String? _selectedCategory;

  static const _allCategoriesValue = '__all_order__';

  String _normalizeEditType(PromotionData? existing) {
    if (existing == null) return PromotionTypes.spendThresholdFreeItem;
    if (existing.type == PromotionTypes.categorySpendThresholdFreeItem) {
      return PromotionTypes.spendThresholdFreeItem;
    }
    return existing.type;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _selectedType = widget.initialType ?? _normalizeEditType(existing);
    _sameAsTrigger = existing?.rewards.sameAsTrigger ?? false;
    _productItemId = existing?.conditions.itemId;

    nameController = TextEditingController(text: existing?.name ?? '');
    amountController = TextEditingController(
      text: existing?.conditions.minOrderAmount.toStringAsFixed(0) ?? '250',
    );
    buyQtyController = TextEditingController(
      text: (existing?.conditions.buyQuantity ?? 1).toString(),
    );
    getQtyController = TextEditingController(
      text: (existing?.rewards.getQuantity ?? 1).toString(),
    );
    flatController = TextEditingController(
      text: existing?.rewards.flatAmount.toStringAsFixed(0) ?? '0',
    );
    percentController = TextEditingController(
      text: existing?.rewards.percent.toStringAsFixed(0) ?? '0',
    );
    startTimeController = TextEditingController(
      text: existing?.conditions.startTime ?? '14:00',
    );
    endTimeController = TextEditingController(
      text: existing?.conditions.endTime ?? '17:00',
    );
    searchController = TextEditingController();
    selectedItemIds =
        existing?.rewards.freeItems.map((e) => e.itemId).toSet() ?? {};
    active = existing?.active ?? true;
    final existingCategory = existing?.conditions.categoryName?.trim();
    _selectedCategory = existingCategory != null && existingCategory.isNotEmpty
        ? existingCategory
        : _allCategoriesValue;
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    buyQtyController.dispose();
    getQtyController.dispose();
    flatController.dispose();
    percentController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    searchController.dispose();
    super.dispose();
  }

  bool get _needsMinAmount =>
      _selectedType == PromotionTypes.spendThresholdFreeItem ||
      _selectedType == PromotionTypes.amountThresholdDiscount ||
      _selectedType == PromotionTypes.percentageThreshold;

  bool get _needsBuyQty =>
      _selectedType == PromotionTypes.buyXGetY ||
      _selectedType == PromotionTypes.buyXPercentOff ||
      _selectedType == PromotionTypes.productSpecific;

  bool get _needsGetQty => _selectedType == PromotionTypes.buyXGetY;

  bool get _needsFlatAmount =>
      _selectedType == PromotionTypes.amountThresholdDiscount ||
      _selectedType == PromotionTypes.flatDiscount ||
      _selectedType == PromotionTypes.productSpecific ||
      (_selectedType == PromotionTypes.timeBased &&
          (double.tryParse(flatController.text) ?? 0) > 0);

  bool get _needsPercent =>
      _selectedType == PromotionTypes.percentageThreshold ||
      _selectedType == PromotionTypes.buyXPercentOff ||
      _selectedType == PromotionTypes.categoryPercent ||
      _selectedType == PromotionTypes.timeBased;

  bool get _needsCategory =>
      _selectedType == PromotionTypes.categoryPercent ||
      (_selectedType == PromotionTypes.spendThresholdFreeItem &&
          _selectedCategory != _allCategoriesValue);

  bool get _needsCategoryOptional =>
      _selectedType == PromotionTypes.spendThresholdFreeItem;

  bool get _needsTime => _selectedType == PromotionTypes.timeBased;

  bool get _needsFreeItems =>
      _selectedType == PromotionTypes.spendThresholdFreeItem ||
      (_selectedType == PromotionTypes.buyXGetY && !_sameAsTrigger);

  bool get _needsProduct =>
      _selectedType == PromotionTypes.productSpecific ||
      _selectedType == PromotionTypes.buyXGetY;

  bool get _singleProductSelect =>
      _selectedType == PromotionTypes.productSpecific ||
      (_selectedType == PromotionTypes.buyXGetY && _sameAsTrigger);

  InputDecoration _fieldDecoration(
    String label, {
    String? helper,
    String? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixText: prefix,
      filled: true,
      fillColor: AppColor.backGroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  List<ItemData> _filteredItems(List<ItemData> items) {
    var scoped = items;
    if (_selectedCategory != null && _selectedCategory != _allCategoriesValue) {
      scoped = scoped
          .where(
            (item) => PromotionEngine.categoryMatches(
              item.category,
              _selectedCategory!,
            ),
          )
          .toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return scoped;

    return scoped.where((item) {
      final name = item.itemName.toLowerCase();
      final category = item.category.toLowerCase();
      final sku = item.sku.toLowerCase();
      final barcode = item.barcode.toLowerCase();
      return name.contains(query) ||
          category.contains(query) ||
          sku.contains(query) ||
          barcode.contains(query);
    }).toList();
  }

  String? get _categoryNameForSave {
    if (_selectedCategory == null || _selectedCategory == _allCategoriesValue) {
      return null;
    }
    return _selectedCategory;
  }

  String get _minAmountLabel {
    if (_needsCategory &&
        _selectedCategory != null &&
        _selectedCategory != _allCategoriesValue) {
      return 'Minimum $_selectedCategory amount (₹)';
    }
    return 'Minimum order amount (₹)';
  }

  String get _itemsSectionTitle {
    if (_selectedType == PromotionTypes.buyXGetY && !_sameAsTrigger) {
      return 'Buy product & free choices';
    }
    if (_singleProductSelect) return 'Select product';
    if (_needsFreeItems) return 'Free item choices';
    return 'Items';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final showItemList = _needsFreeItems || _needsProduct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DialogHeader(
          title: isEditing ? 'Edit offer' : 'Create offer',
          subtitle: PromotionTypes.label(_selectedType),
          onClose: () => Get.back(),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: _SectionCard(
            title: 'Offer details',
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: _fieldDecoration('Offer type'),
                  items: PromotionTypes.all
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(PromotionTypes.label(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedType = value;
                      selectedItemIds.clear();
                      _productItemId = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: _fieldDecoration(
                    'Offer name',
                    helper: PromotionTypes.example(_selectedType),
                  ),
                ),
                if (_needsMinAmount) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration(_minAmountLabel, prefix: '₹ '),
                  ),
                ],
                if (_needsBuyQty) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: buyQtyController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration('Buy quantity'),
                  ),
                ],
                if (_needsGetQty) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: getQtyController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration('Free quantity'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Same product (BOGO)'),
                    subtitle: const Text(
                      'Free item is the same as the purchased product',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColor.textSecondary,
                      ),
                    ),
                    value: _sameAsTrigger,
                    onChanged: (value) => setState(() {
                      _sameAsTrigger = value;
                      selectedItemIds.clear();
                    }),
                  ),
                ],
                if (_needsFlatAmount &&
                    _selectedType != PromotionTypes.timeBased) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: flatController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration(
                      'Discount amount (₹)',
                      prefix: '₹ ',
                    ),
                  ),
                ],
                if (_needsPercent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: percentController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration('Discount (%)', prefix: '% '),
                  ),
                ],
                if (_needsTime) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startTimeController,
                          decoration: _fieldDecoration(
                            'Start time',
                            helper: 'HH:MM',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: endTimeController,
                          decoration: _fieldDecoration(
                            'End time',
                            helper: 'HH:MM',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: flatController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration(
                      'Flat discount (₹) — optional',
                      prefix: '₹ ',
                    ),
                  ),
                ],
                if (_needsCategoryOptional || _needsCategory) ...[
                  const SizedBox(height: 12),
                  Obx(() {
                    final categories = widget.controller.availableCategories;
                    if (categories.isEmpty) return const SizedBox.shrink();
                    return DropdownButtonFormField<String>(
                      value: _selectedCategory ?? _allCategoriesValue,
                      decoration: _fieldDecoration(
                        _needsCategory
                            ? 'Category'
                            : 'Offer category (optional)',
                        helper: _needsCategory
                            ? 'Discount applies to this category only'
                            : 'Leave on entire order for all items',
                      ),
                      items: [
                        if (_needsCategoryOptional)
                          const DropdownMenuItem(
                            value: _allCategoriesValue,
                            child: Text('Entire order'),
                          ),
                        ...categories.map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category.capitalize ?? ''),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                          selectedItemIds.removeWhere((id) {
                            final item = widget.controller.menuItems
                                .firstWhereOrNull((entry) => entry.id == id);
                            if (item == null) return true;
                            if (value == null || value == _allCategoriesValue) {
                              return false;
                            }
                            return !PromotionEngine.categoryMatches(
                              item.category,
                              value,
                            );
                          });
                        });
                      },
                    );
                  }),
                ],
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Offer active',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Inactive offers are hidden at billing',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  value: active,
                  onChanged: (value) => setState(() => active = value),
                ),
              ],
            ),
          ),
        ),
        if (showItemList) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text(
                  _itemsSectionTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_needsFreeItems)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${selectedItemIds.length} selected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search items by name, category, SKU…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                filled: true,
                fillColor: AppColor.backGroundColor,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() {
                if (widget.controller.isLoadingItems.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = _filteredItems(widget.controller.menuItems);
                if (widget.controller.menuItems.isEmpty) {
                  return _EmptyItemsState(
                    message: 'No menu items found',
                    actionLabel: 'Reload items',
                    onAction: widget.controller.loadMenuItems,
                  );
                }
                if (items.isEmpty) {
                  return _EmptyItemsState(
                    message: 'No items match "$_searchQuery"',
                    actionLabel: 'Clear search',
                    onAction: () {
                      searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: AppColor.backGroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColor.cardBorder),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 52,
                      color: AppColor.cardBorder.withValues(alpha: 0.7),
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (_selectedType == PromotionTypes.buyXGetY &&
                          !_sameAsTrigger) {
                        return _ItemBuyFreeTile(
                          item: item,
                          isBuyProduct: _productItemId == item.id,
                          isFreeChoice: selectedItemIds.contains(item.id),
                          onBuyTap: () =>
                              setState(() => _productItemId = item.id),
                          onFreeChanged: (checked) {
                            setState(() {
                              if (checked) {
                                selectedItemIds.add(item.id);
                              } else {
                                selectedItemIds.remove(item.id);
                              }
                            });
                          },
                        );
                      }
                      if (_singleProductSelect) {
                        return _ItemRadioTile(
                          item: item,
                          groupValue: _productItemId,
                          value: item.id,
                          onChanged: (value) =>
                              setState(() => _productItemId = value),
                        );
                      }
                      final isSelected = selectedItemIds.contains(item.id);
                      return _ItemCheckboxTile(
                        item: item,
                        selected: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked) {
                              if (_needsProduct && !_needsFreeItems) {
                                selectedItemIds
                                  ..clear()
                                  ..add(item.id);
                                _productItemId = item.id;
                              } else {
                                selectedItemIds.add(item.id);
                              }
                            } else {
                              selectedItemIds.remove(item.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ] else
          const Spacer(),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(
            () => Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.controller.isSaving.value
                        ? null
                        : () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.controller.isSaving.value ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: widget.controller.isSaving.value
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isEditing ? 'Save changes' : 'Create offer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _save() {
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    final buyQty = int.tryParse(buyQtyController.text.trim()) ?? 1;
    final getQty = int.tryParse(getQtyController.text.trim()) ?? 1;
    final flat = double.tryParse(flatController.text.trim()) ?? 0;
    final percent = double.tryParse(percentController.text.trim()) ?? 0;

    final freeItems = selectedItemIds.map((id) {
      final item = widget.controller.menuItems.firstWhereOrNull(
        (entry) => entry.id == id,
      );
      return PromotionFreeItem(itemId: id, label: item?.itemName);
    }).toList();

    final productId =
        _productItemId ??
        (_needsProduct && selectedItemIds.length == 1
            ? selectedItemIds.first
            : null);

    widget.controller.savePromotion(
      existing: widget.existing,
      type: _selectedType,
      name: nameController.text,
      active: active,
      minOrderAmount: amount,
      buyQuantity: buyQty,
      getQuantity: getQty,
      flatAmount: flat,
      percent: percent,
      categoryName: _categoryNameForSave,
      productItemId: productId,
      startTime: startTimeController.text.trim(),
      endTime: endTimeController.text.trim(),
      freeItems: freeItems,
      sameAsTrigger: _sameAsTrigger,
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColor.secondaryPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              color: AppColor.secondaryPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: AppColor.textSecondary),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColor.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColor.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  const _EmptyItemsState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 36,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _ItemRadioTile extends StatelessWidget {
  const _ItemRadioTile({
    required this.item,
    required this.groupValue,
    required this.value,
    required this.onChanged,
  });

  final ItemData item;
  final String? groupValue;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final category = item.category.trim();
    final hasCategory = category.isNotEmpty && category.toLowerCase() != 'none';
    final selected = groupValue == value;

    return Material(
      color: selected
          ? AppColor.primary.withValues(alpha: 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: groupValue,
                activeColor: AppColor.primary,
                onChanged: onChanged,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    if (hasCategory)
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColor.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '₹${item.salePrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemBuyFreeTile extends StatelessWidget {
  const _ItemBuyFreeTile({
    required this.item,
    required this.isBuyProduct,
    required this.isFreeChoice,
    required this.onBuyTap,
    required this.onFreeChanged,
  });

  final ItemData item;
  final bool isBuyProduct;
  final bool isFreeChoice;
  final VoidCallback onBuyTap;
  final ValueChanged<bool> onFreeChanged;

  @override
  Widget build(BuildContext context) {
    final category = item.category.trim();
    final hasCategory = category.isNotEmpty && category.toLowerCase() != 'none';
    final highlighted = isBuyProduct || isFreeChoice;

    return Material(
      color: highlighted
          ? AppColor.primary.withValues(alpha: 0.06)
          : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Buy product',
              onPressed: onBuyTap,
              icon: Icon(
                isBuyProduct ? Icons.shopping_bag : Icons.shopping_bag_outlined,
                color: isBuyProduct ? AppColor.primary : AppColor.textSecondary,
                size: 20,
              ),
            ),
            Checkbox(
              value: isFreeChoice,
              activeColor: AppColor.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (value) => onFreeChanged(value == true),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    style: TextStyle(
                      fontWeight: highlighted
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  if (hasCategory)
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColor.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '₹${item.salePrice.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColor.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCheckboxTile extends StatelessWidget {
  const _ItemCheckboxTile({
    required this.item,
    required this.selected,
    required this.onChanged,
  });

  final ItemData item;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final category = item.category.trim();
    final hasCategory = category.isNotEmpty && category.toLowerCase() != 'none';

    return Material(
      color: selected
          ? AppColor.primary.withValues(alpha: 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!selected),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                activeColor: AppColor.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (value) => onChanged(value == true),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    if (hasCategory)
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColor.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '₹${item.salePrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
