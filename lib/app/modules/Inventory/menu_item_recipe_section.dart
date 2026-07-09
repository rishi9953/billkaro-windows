import 'package:billkaro/app/modules/Inventory/inventory_controller.dart';
import 'package:billkaro/app/modules/Inventory/inventory_dialogs.dart';
import 'package:billkaro/config/config.dart';

class MenuItemRecipeSection extends StatefulWidget {
  final String itemId;
  final String itemName;

  const MenuItemRecipeSection({
    super.key,
    required this.itemId,
    required this.itemName,
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
    _inventory.loadRecipes();
    if (_inventory.rawMaterials.isEmpty) {
      _inventory.loadRawMaterials();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Obx(() {
      final lines = _inventory.recipesForItem(widget.itemId);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.recipe_ingredients,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.recipe_ingredients_subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => showAddRecipeDialog(
                  _inventory,
                  preselectedItemId: widget.itemId,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(loc.add_ingredient),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (lines.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                loc.no_ingredients_yet,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            )
          else
            ...lines.map(
              (r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.grain, size: 18, color: Color(0xFFEF8819)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc.recipe_uses_material(
                          r.quantity.toString(),
                          r.rawMaterialUnit,
                          r.rawMaterialName,
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: loc.edit_recipe,
                      onPressed: () =>
                          showEditRecipeDialog(_inventory, r),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      onPressed: () => _confirmDelete(r.id, loc),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }

  void _confirmDelete(String recipeId, AppLocalizations loc) {
    Get.dialog(
      AlertDialog(
        title: Text(loc.confirm_delete),
        content: Text(loc.delete_confirm_message(loc.this_recipe)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _inventory.deleteRecipe(recipeId);
              await _inventory.loadRecipes();
              Get.back();
            },
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }
}
