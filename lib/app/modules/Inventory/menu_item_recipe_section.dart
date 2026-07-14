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
                onPressed: () => showRecipeDialog(
                  _inventory,
                  preselectedItemId: widget.itemId,
                ),
                icon: Icon(
                  lines.isEmpty ? Icons.add : Icons.edit_outlined,
                  size: 18,
                ),
                label: Text(
                  lines.isEmpty ? loc.add_recipe : loc.edit_recipe,
                ),
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
                loc.add_recipe_subtitle,
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
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}
