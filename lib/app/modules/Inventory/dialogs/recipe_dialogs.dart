part of 'inventory_dialogs.dart';

Future<void> showRecipeDialog(
  InventoryController c, {
  String? preselectedItemId,
  String? draftItemName,
  List<RecipeLineInput>? initialDraftIngredients,
  void Function(List<RecipeLineInput> ingredients)? onDraftSaved,
}) => _showRecipeMultiDialog(
  c,
  preselectedItemId: preselectedItemId,
  draftItemName: draftItemName,
  initialDraftIngredients: initialDraftIngredients,
  onDraftSaved: onDraftSaved,
);

Future<void> showAddRecipeDialog(
  InventoryController c, {
  String? preselectedItemId,
}) => showRecipeDialog(c, preselectedItemId: preselectedItemId);

Future<void> showEditRecipeDialog(
  InventoryController c, {
  required String itemId,
}) => showRecipeDialog(c, preselectedItemId: itemId);

class _RecipeIngredientDraft {
  _RecipeIngredientDraft({
    this.recipeId,
    this.rawMaterialId = '',
    this.unit = '',
    double? quantity,
  }) : qtyCtrl = TextEditingController(
         text: quantity != null && quantity > 0 ? quantity.toString() : '',
       );

  final String? recipeId;
  String rawMaterialId;
  String unit;
  final TextEditingController qtyCtrl;

  void dispose() => qtyCtrl.dispose();
}

List<String> _compatibleRecipeUnits(String materialUnit) {
  switch (materialUnit.trim().toUpperCase()) {
    case 'KG':
    case 'GRAM':
      return const ['KG', 'GRAM'];
    case 'LITER':
    case 'ML':
      return const ['LITER', 'ML'];
    case 'PIECE':
      return const ['PIECE'];
    case 'PACKET':
      return const ['PACKET'];
    case 'BOX':
      return const ['BOX'];
    case 'DOZEN':
      return const ['DOZEN'];
    case 'BOTTLE':
      return const ['BOTTLE'];
    default:
      final u = materialUnit.trim().toUpperCase();
      return u.isEmpty ? const ['PIECE'] : [u];
  }
}

List<RawMaterialData> _availableMaterialsForRecipe(
  InventoryController c,
  String itemId,
  List<_RecipeIngredientDraft> lines,
  int excludeIndex, {
  required bool isEdit,
}) {
  final draftMaterialIds = lines
      .where((l) => l.rawMaterialId.isNotEmpty)
      .map((l) => l.rawMaterialId)
      .toSet();
  final usedInRecipe = c
      .recipesForItem(itemId)
      .map((r) => r.rawMaterialId)
      .toSet();
  final blockedFromDb = isEdit
      ? usedInRecipe.difference(draftMaterialIds)
      : usedInRecipe;
  final usedInDraft = <String>{};
  for (var i = 0; i < lines.length; i++) {
    if (i != excludeIndex && lines[i].rawMaterialId.isNotEmpty) {
      usedInDraft.add(lines[i].rawMaterialId);
    }
  }
  return c.rawMaterials
      .where(
        (m) => !blockedFromDb.contains(m.id) && !usedInDraft.contains(m.id),
      )
      .toList();
}

List<_RecipeIngredientDraft> _initialRecipeDrafts(
  InventoryController c,
  String itemId, {
  List<RecipeLineInput>? seedDrafts,
}) {
  if (seedDrafts != null && seedDrafts.isNotEmpty) {
    return seedDrafts
        .map(
          (r) => _RecipeIngredientDraft(
            recipeId: r.id,
            rawMaterialId: r.rawMaterialId,
            unit: r.unit,
            quantity: r.quantity,
          ),
        )
        .toList();
  }
  final existing = itemId.isNotEmpty
      ? c.recipesForItem(itemId)
      : <RecipeData>[];
  if (existing.isNotEmpty) {
    return existing
        .map(
          (r) => _RecipeIngredientDraft(
            recipeId: r.id,
            rawMaterialId: r.rawMaterialId,
            unit: r.displayUnit,
            quantity: r.quantity,
          ),
        )
        .toList();
  }
  return [_RecipeIngredientDraft(), _RecipeIngredientDraft()];
}

Future<void> _showRecipeMultiDialog(
  InventoryController c, {
  String? preselectedItemId,
  String? draftItemName,
  List<RecipeLineInput>? initialDraftIngredients,
  void Function(List<RecipeLineInput> ingredients)? onDraftSaved,
}) async {
  final loc = AppLocalizations.of(Get.context!)!;
  final isDraftMode = onDraftSaved != null;

  if (c.rawMaterials.isEmpty || (!isDraftMode && c.menuItems.isEmpty)) {
    await c.loadRecipeData();
  }

  var selectedItemId = preselectedItemId ?? '';
  if (!isDraftMode && selectedItemId.isEmpty && c.menuItems.length == 1) {
    selectedItemId = c.menuItems.first.id;
  }

  final lockedItemId = preselectedItemId;
  final lockItem = lockedItemId != null || isDraftMode;
  final initialItemId = lockedItemId ?? selectedItemId;
  var isEdit = isDraftMode
      ? (initialDraftIngredients?.isNotEmpty ?? false)
      : initialItemId.isNotEmpty && c.recipesForItem(initialItemId).isNotEmpty;
  final lines = _initialRecipeDrafts(
    c,
    initialItemId,
    seedDrafts: initialDraftIngredients,
  );

  Future<void> saveRecipe() async {
    final parsed = <RecipeLineInput>[];
    final seenMaterials = <String>{};

    for (final line in lines) {
      if (line.rawMaterialId.isEmpty) continue;
      final qty = double.tryParse(line.qtyCtrl.text.trim());
      if (qty == null || qty <= 0) continue;
      if (!seenMaterials.add(line.rawMaterialId)) {
        showError(description: loc.recipe_duplicate_material);
        return;
      }
      parsed.add(
        RecipeLineInput(
          id: line.recipeId,
          rawMaterialId: line.rawMaterialId,
          quantity: qty,
          unit: line.unit.trim().isNotEmpty
              ? line.unit.trim().toUpperCase()
              : (c.rawMaterials
                        .firstWhereOrNull((m) => m.id == line.rawMaterialId)
                        ?.unit ??
                    'PIECE'),
        ),
      );
    }

    if (parsed.isEmpty) {
      showError(description: loc.recipe_need_at_least_one_ingredient);
      return;
    }

    if (isDraftMode) {
      onDraftSaved!(parsed);
      Get.back();
      return;
    }

    final itemId = lockedItemId ?? selectedItemId;
    if (itemId.isEmpty) {
      showError(description: loc.select_menu_item_required);
      return;
    }

    final ok = await c.saveRecipesForItem(itemId: itemId, ingredients: parsed);
    if (ok) Get.back();
  }

  await showInventoryEndDrawer(
    title: isEdit ? loc.edit_recipe : loc.add_recipe,
    width: 520,
    body: StatefulBuilder(
      builder: (context, setState) {
        final itemId = lockedItemId ?? selectedItemId;
        if (!isDraftMode) {
          isEdit = itemId.isNotEmpty && c.recipesForItem(itemId).isNotEmpty;
        }

        Widget buildIngredientRow(int index) {
          final line = lines[index];
          final available = _availableMaterialsForRecipe(
            c,
            itemId,
            lines,
            index,
            isEdit: isEdit,
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.ingredient_number(index + 1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (lines.length > 1)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: loc.delete,
                        onPressed: () {
                          setState(() {
                            lines[index].dispose();
                            lines.removeAt(index);
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                AppDropdownFormField2<String>(
                  value: line.rawMaterialId.isEmpty ? null : line.rawMaterialId,
                  decoration: InputDecoration(
                    labelText: loc.select_raw_material,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: available
                      .map(
                        (m) => DropdownItem(
                          value: m.id,
                          child: Text('${m.name} (${m.unit})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    final material = c.rawMaterials.firstWhereOrNull(
                      (m) => m.id == v,
                    );
                    setState(() {
                      line.rawMaterialId = v ?? '';
                      line.unit = material?.unit ?? '';
                    });
                  },
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (_) {
                    final material = c.rawMaterials.firstWhereOrNull(
                      (m) => m.id == line.rawMaterialId,
                    );
                    final units = _compatibleRecipeUnits(
                      material?.unit ?? line.unit,
                    );
                    final unitValue = units.contains(line.unit)
                        ? line.unit
                        : (units.isNotEmpty ? units.first : null);
                    if (unitValue != null && line.unit != unitValue) {
                      line.unit = unitValue;
                    }
                    final selectedUom = (unitValue ?? line.unit).trim();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppDropdownFormField2<String>(
                          value: unitValue,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'UOM *',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          hint: const Text('Select UOM'),
                          items: units
                              .map(
                                (u) => DropdownItem(
                                  value: u,
                                  child: Text(u),
                                ),
                              )
                              .toList(),
                          onChanged: line.rawMaterialId.isEmpty
                              ? null
                              : (v) => setState(() => line.unit = v ?? ''),
                          validator: (value) {
                            if (line.rawMaterialId.isEmpty) return null;
                            if ((value ?? '').trim().isEmpty) {
                              return 'Select UOM';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: line.qtyCtrl,
                          enabled: line.rawMaterialId.isNotEmpty,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: _numberInputFormatters,
                          decoration: InputDecoration(
                            labelText: selectedUom.isEmpty
                                ? loc.recipe_quantity_hint
                                : 'Quantity ($selectedUom) *',
                            hintText: selectedUom.isEmpty
                                ? null
                                : 'Enter quantity in $selectedUom',
                            suffixText:
                                selectedUom.isEmpty ? null : selectedUom,
                            helperText: loc.recipe_quantity_helper,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (value) {
                            if (line.rawMaterialId.isEmpty) return null;
                            final qty = double.tryParse((value ?? '').trim());
                            if (qty == null || qty <= 0) {
                              return 'Enter quantity${selectedUom.isEmpty ? '' : ' in $selectedUom'}';
                            }
                            return null;
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.add_recipe_subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (lockItem)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  isDraftMode
                      ? ((draftItemName ?? '').trim().isNotEmpty
                            ? draftItemName!.trim()
                            : loc.addMenuItem)
                      : c.menuItemName(lockedItemId!),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              )
            else
              AppDropdownFormField2<String>(
                value: selectedItemId.isEmpty ? null : selectedItemId,
                decoration: InputDecoration(
                  labelText: loc.select_menu_item,
                  border: const OutlineInputBorder(),
                ),
                items: c.menuItems
                    .map(
                      (item) => DropdownItem(
                        value: item.id,
                        child: Text(item.itemName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedItemId = v ?? ''),
              ),
            const SizedBox(height: 16),
            Text(
              loc.recipe_ingredients_section,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...List.generate(lines.length, buildIngredientRow),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => lines.add(_RecipeIngredientDraft())),
                icon: const Icon(Icons.add, size: 18),
                label: Text(loc.add_another_ingredient),
              ),
            ),
          ],
        );
      },
    ),
    footerActions: [
      TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
      ElevatedButton(onPressed: saveRecipe, child: Text(loc.save)),
    ],
  );

  // Wait for drawer reverse animation before disposing controllers.
  await Future.delayed(const Duration(milliseconds: 350));
  for (final line in lines) {
    line.dispose();
  }
}
