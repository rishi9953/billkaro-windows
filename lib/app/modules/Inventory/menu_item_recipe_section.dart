import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/modules/Inventory/inventory_controller.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/config/config.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

/// Links an existing Inventory recipe to a menu item (no new recipe rows).
class MenuItemRecipeSection extends StatefulWidget {
  final String itemId;
  final String itemName;
  final String linkedRecipeItemId;
  final ValueChanged<String> onLinkedRecipeChanged;

  const MenuItemRecipeSection({
    super.key,
    required this.itemId,
    required this.itemName,
    required this.linkedRecipeItemId,
    required this.onLinkedRecipeChanged,
  });

  @override
  State<MenuItemRecipeSection> createState() => _MenuItemRecipeSectionState();
}

class _MenuItemRecipeSectionState extends State<MenuItemRecipeSection> {
  late final InventoryController _inventory;

  @override
  void initState() {
    super.initState();
    _inventory = Get.isRegistered<InventoryController>()
        ? Get.find<InventoryController>()
        : Get.put(InventoryController());
    _inventory.loadRecipeData();
  }

  /// Existing recipes grouped by menu item (excludes the current item).
  List<({String itemId, String itemName, int ingredientCount})>
  _existingRecipeOptions() {
    final byItem = <String, List<RecipeData>>{};
    for (final r in _inventory.recipes) {
      if (r.itemId.isEmpty) continue;
      if (widget.itemId.isNotEmpty && r.itemId == widget.itemId) continue;
      byItem.putIfAbsent(r.itemId, () => []).add(r);
    }

    final options = byItem.entries.map((e) {
      final name = e.value.first.itemName.trim().isNotEmpty
          ? e.value.first.itemName.trim()
          : _inventory.menuItemName(e.key);
      return (
        itemId: e.key,
        itemName: name.isNotEmpty ? name : e.key,
        ingredientCount: e.value.length,
      );
    }).toList();

    options.sort(
      (a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
    );
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Obx(() {
      final _ = _inventory.recipes.length;
      final __ = _inventory.rawMaterials.length;
      final recipeOptions = _existingRecipeOptions();
      final linkedId = widget.linkedRecipeItemId.trim();
      final selectedValue = linkedId.isEmpty
          ? '__none__'
          : (recipeOptions.any((o) => o.itemId == linkedId) ? linkedId : null);
      final linkedLines = linkedId.isEmpty
          ? const <RecipeData>[]
          : _inventory.recipesForItem(linkedId);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.recipe_ingredients,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Select an existing recipe from Inventory. No new recipe is created.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          if (recipeOptions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                'No recipes found. Create one in Inventory → Recipes first, then link it here.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            )
          else ...[
            AppDropdownFormField2<String>(
              isExpanded: true,
              value: selectedValue,
              decoration: const InputDecoration(
                labelText: 'Link recipe from Inventory',
                hintText: 'Select an existing recipe',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownItem<String>(
                  value: '__none__',
                  child: Text('None'),
                ),
                ...recipeOptions.map(
                  (o) => DropdownItem<String>(
                    value: o.itemId,
                    child: Text(
                      '${o.itemName} (${o.ingredientCount})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                final id = (value ?? '').trim();
                widget.onLinkedRecipeChanged(id == '__none__' ? '' : id);
              },
              iconStyleData: IconStyleData(
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColor.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (linkedLines.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'Select a recipe above. Raw materials deduct on sale and appear in Stock Log.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              )
            else
              ...linkedLines.map(
                (r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.grain,
                        size: 18,
                        color: Color(0xFFEF8819),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          loc.recipe_uses_material(
                            r.quantity.toString(),
                            r.displayUnit,
                            r.rawMaterialName,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      );
    });
  }
}
