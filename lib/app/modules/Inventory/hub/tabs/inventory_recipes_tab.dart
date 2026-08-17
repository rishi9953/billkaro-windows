part of '../../inventory_hub_screen.dart';

extension _InventoryRecipesTab on _InventoryHubScreenState {
  Widget _recipesTab(bool isWide, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _toolbar(
            loc: loc,
            hint: loc.search_recipes,
            searchController: _recipeSearchCtrl,
            searchWidth: MediaQuery.of(context).size.width * 0.32,
            onSearch: (v) => controller.recipeSearchQuery.value = v,
            filter: Obx(() {
              final materials = controller.rawMaterials.toList()
                ..sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );
              final menuItems = controller.menuItems.toList()
                ..sort(
                  (a, b) => a.itemName.toLowerCase().compareTo(
                    b.itemName.toLowerCase(),
                  ),
                );

              final selectedMaterial = controller.recipeMaterialIdFilter.value;
              final materialValue =
                  materials.any((m) => m.id == selectedMaterial)
                  ? selectedMaterial
                  : '';
              if (selectedMaterial.isNotEmpty && materialValue.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.recipeMaterialIdFilter.value = '';
                });
              }

              final selectedItem = controller.recipeItemIdFilter.value;
              final itemValue = menuItems.any((m) => m.id == selectedItem)
                  ? selectedItem
                  : '';
              if (selectedItem.isNotEmpty && itemValue.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.recipeItemIdFilter.value = '';
                });
              }

              final dateLabel = controller.recipeDateFilterLabel;
              final hasFilters = controller.hasRecipeFilters;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: isWide ? 200 : 160,
                    height: 44,
                    child: AppDropdownFormField2<String>(
                      value: itemValue,
                      isExpanded: true,
                      hint: const Text('All items'),
                      decoration: InputDecoration(
                        labelText: 'Menu item',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        filled: true,
                        fillColor: _inventoryCardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: [
                        const DropdownItem(value: '', child: Text('All items')),
                        ...menuItems.map(
                          (m) => DropdownItem(
                            value: m.id,
                            child: Text(
                              m.itemName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        controller.recipeItemIdFilter.value = v ?? '';
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: isWide ? 200 : 160,
                    height: 44,
                    child: AppDropdownFormField2<String>(
                      value: materialValue,
                      isExpanded: true,
                      hint: const Text('All materials'),
                      decoration: InputDecoration(
                        labelText: 'Material',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        filled: true,
                        fillColor: _inventoryCardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: [
                        const DropdownItem(
                          value: '',
                          child: Text('All materials'),
                        ),
                        ...materials.map(
                          (m) => DropdownItem(
                            value: m.id,
                            child: Text(
                              m.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        controller.recipeMaterialIdFilter.value = v ?? '';
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showAppDatePicker(
                          context: context,
                          initialDate: controller.recipeDateFilter.value ?? now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: now,
                          helpText: 'Filter recipes by day',
                        );
                        if (picked != null) {
                          controller.setRecipeDateFilter(picked);
                        }
                      },
                      icon: Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: _inventoryAccent,
                      ),
                      label: Text(dateLabel),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _inventoryAccent,
                        side: const BorderSide(color: _inventoryAccent),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  if (controller.hasRecipeDateFilter) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Show all days',
                      onPressed: controller.clearRecipeDateFilter,
                      icon: const Icon(Icons.clear, size: 18),
                    ),
                  ],
                  if (hasFilters) ...[
                    const SizedBox(width: 6),
                    TextButton.icon(
                      onPressed: () {
                        controller.clearRecipeFilters();
                        _recipeSearchCtrl.clear();
                      },
                      icon: const Icon(Icons.filter_alt_off, size: 16),
                      label: const Text('Clear filters'),
                      style: TextButton.styleFrom(foregroundColor: _inventoryAccent),
                    ),
                  ],
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final _ = controller.recipes.length;
            return Row(
              children: [
                Expanded(
                  child: _productStockSummaryCard(
                    'Recipes',
                    '${controller.recipeFilteredItemCount}',
                    Icons.restaurant_menu,
                    const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _productStockSummaryCard(
                    'Ingredients',
                    '${controller.recipeFilteredLineCount}',
                    Icons.grain,
                    const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _productStockSummaryCard(
                    controller.hasRecipeDateFilter
                        ? controller.recipeDateFilterLabel
                        : 'Period',
                    controller.hasRecipeDateFilter ? 'Filtered' : 'All days',
                    Icons.calendar_today_outlined,
                    _inventoryAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _productStockSummaryCard(
                    'Total mapped',
                    '${controller.recipes.length}',
                    Icons.link,
                    const Color(0xFF7C3AED),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              final allEmpty = controller.recipes.isEmpty;
              final grouped = controller.recipesGroupedByItem;
              if (allEmpty) {
                return _emptyCard(loc.no_recipes_yet);
              }
              if (grouped.isEmpty) {
                return _emptyCard('No recipes match the selected filters.');
              }
              final itemIds = grouped.keys.toList()
                ..sort(
                  (a, b) => controller
                      .menuItemName(a)
                      .compareTo(controller.menuItemName(b)),
                );
              return ListView.separated(
                itemCount: itemIds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final itemId = itemIds[i];
                  final lines = grouped[itemId]!;
                  final itemName = lines.first.itemName.isNotEmpty
                      ? lines.first.itemName
                      : controller.menuItemName(itemId);
                  return Container(
                    decoration: BoxDecoration(
                      color: _inventoryCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: const Icon(
                          Icons.restaurant_menu,
                          color: _inventoryAccent,
                          size: 22,
                        ),
                        title: Text(
                          itemName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          loc.recipe_lines_count(lines.length),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: StaffAccess.canAdjustStock
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: loc.edit_recipe,
                                    visualDensity: VisualDensity.compact,
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      if (!StaffAccess.ensure(
                                        StaffAccess.canAdjustStock,
                                      )) {
                                        return;
                                      }
                                      showEditRecipeDialog(
                                        controller,
                                        itemId: itemId,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    tooltip: loc.delete,
                                    visualDensity: VisualDensity.compact,
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.red.shade400,
                                    ),
                                    onPressed: () {
                                      if (!StaffAccess.ensure(
                                        StaffAccess.canAdjustStock,
                                      )) {
                                        return;
                                      }
                                      _confirmDelete(
                                        itemName,
                                        () => controller.deleteRecipesForItem(
                                          itemId,
                                        ),
                                        loc,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.expand_more,
                                    color: Colors.grey.shade600,
                                  ),
                                ],
                              )
                            : null,
                        children: lines
                            .map(
                              (r) => ListTile(
                                dense: true,
                                title: Text(r.rawMaterialName),
                                subtitle: Text(
                                  '${r.quantity} ${r.displayUnit}',
                                ),
                                trailing: StaffAccess.canAdjustStock
                                    ? IconButton(
                                        tooltip: loc.delete,
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.red.shade300,
                                        ),
                                        onPressed: () {
                                          if (!StaffAccess.ensure(
                                            StaffAccess.canAdjustStock,
                                          )) {
                                            return;
                                          }
                                          _confirmDelete(
                                            r.rawMaterialName,
                                            () => controller.deleteRecipe(r.id),
                                            loc,
                                          );
                                        },
                                      )
                                    : null,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
