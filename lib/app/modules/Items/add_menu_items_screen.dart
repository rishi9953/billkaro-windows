import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/modules/Items/add_menu_items_controller.dart';
import 'package:billkaro/app/modules/Items/product_form_extras.dart';
import 'package:billkaro/app/modules/Items/product_variants_section.dart';
import 'package:billkaro/app/modules/Inventory/menu_item_recipe_section.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:billkaro/utils/staff_access.dart';

class AddMenuItemScreen extends StatefulWidget {
  const AddMenuItemScreen({super.key});

  @override
  State<AddMenuItemScreen> createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends State<AddMenuItemScreen> {
  late final AddMenuItemController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AddMenuItemController());
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareScreen());
  }

  Future<void> _prepareScreen() async {
    if (!mounted) return;
    final rawArgs = Get.arguments ?? Modular.args.data;
    final args = rawArgs is Map<String, dynamic> ? rawArgs : null;
    await controller.prepareScreen(args);
  }

  @override
  Widget build(BuildContext context) {
    var loc = AppLocalizations.of(Get.context!)!;
    final scrollController = ScrollController();
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _confirmLeave(context);
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Obx(() {
            return Text(
              controller.isEdit.value ? loc.edit_menu_item : loc.addMenuItem,
              style: TextStyle(
                color: AppColor.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            );
          }),
          actions: [
            // Reset Form
            IconButton(
              tooltip: 'Reset Form',
              onPressed: controller.resetForm,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final contentMaxWidth = isWide ? 980.0 : 720.0;

            InputDecoration inputDecoration({
              String? hintText,
              Widget? suffixIcon,
              String? suffixText,
            }) {
              return InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey[400]),
                suffixText: suffixText,
                suffixIcon: suffixIcon,
                suffixStyle: TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColor.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              );
            }

            Widget sectionTitle(String text) {
              return Text(
                text,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              );
            }

            Widget fieldLabel(String text) {
              return Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              );
            }

            Widget requiredFieldLabel(String label) {
              return RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(text: label),
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ),
              );
            }

            Widget imageFieldLabel(String text) {
              return Row(
                children: [
                  Icon(Icons.image_outlined, size: 16, color: AppColor.primary),
                  const SizedBox(width: 6),
                  fieldLabel(text),
                ],
              );
            }

            Widget buildImagePicker() {
              void showImagePreview(Widget image) {
                showDialog(
                  context: context,
                  builder: (dialogContext) => Dialog(
                    insetPadding: const EdgeInsets.all(20),
                    backgroundColor: Colors.black,
                    child: Stack(
                      children: [
                        InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4,
                          child: SizedBox(width: double.infinity, child: image),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(
                              dialogContext,
                              rootNavigator: true,
                            ).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Obx(
                () => InkWell(
                  onTap: () {
                    if (controller.selectedImage.value != null) {
                      showImagePreview(
                        Image.file(
                          controller.selectedImage.value!,
                          fit: BoxFit.contain,
                        ),
                      );
                      return;
                    }
                    if (controller.imageUrl.value.isNotEmpty) {
                      showImagePreview(
                        Image.network(
                          controller.imageUrl.value,
                          fit: BoxFit.contain,
                        ),
                      );
                      return;
                    }
                    controller.uploadImage();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 210,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: controller.isScanning.value
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 14),
                                Text(
                                  'AI is scanning menu...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : controller.selectedImage.value != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  controller.selectedImage.value!,
                                  width: double.infinity,
                                  height: 210,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (controller.aiScanResult.value != null &&
                                  controller.aiScanResult.value!.isValid)
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.92),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.auto_awesome,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'AI Scanned',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 10,
                                left:
                                    (controller.aiScanResult.value != null &&
                                        controller.aiScanResult.value!.isValid)
                                    ? 120
                                    : 10,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    tooltip: 'View image',
                                    icon: const Icon(
                                      Icons.visibility,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      showImagePreview(
                                        Image.file(
                                          controller.selectedImage.value!,
                                          fit: BoxFit.contain,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    tooltip: loc.remove_image,
                                    icon: Icon(
                                      Icons.delete,
                                      color: AppColor.error,
                                      size: 20,
                                    ),
                                    onPressed: controller.removeImage,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 60,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    tooltip: loc.upload_item_image,
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: controller.uploadImage,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : controller.imageUrl.value.isNotEmpty
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  controller.imageUrl.value,
                                  width: double.infinity,
                                  height: 210,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildEmptyImagePlaceholder(loc),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    tooltip: 'View image',
                                    icon: const Icon(
                                      Icons.visibility,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      showImagePreview(
                                        Image.network(
                                          controller.imageUrl.value,
                                          fit: BoxFit.contain,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    tooltip: loc.remove_image,
                                    icon: Icon(
                                      Icons.delete,
                                      color: AppColor.error,
                                      size: 20,
                                    ),
                                    onPressed: controller.removeImage,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 60,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    tooltip: loc.upload_item_image,
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: controller.uploadImage,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _buildEmptyImagePlaceholder(loc),
                  ),
                ),
              );
            }

            Widget buildAvailabilityTile() {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Available for Sale',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Obx(
                      () => Switch(
                        value: controller.isAvailable.value,
                        activeColor: AppColor.primary.withOpacity(0.95),
                        activeTrackColor: AppColor.primary.withOpacity(0.25),
                        onChanged: (value) {
                          controller.isAvailable.value = value;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            Widget buildRecommendedTile() {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, color: AppColor.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc.mark_this_item_as_favourite,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Obx(
                      () => Switch(
                        value: controller.markAsFavorite.value,
                        activeColor: AppColor.primary.withOpacity(0.95),
                        activeTrackColor: AppColor.primary.withOpacity(0.25),
                        onChanged: (value) {
                          controller.markAsFavorite.value = value;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            Widget buildButtons() {
              return Obx(() {
                if (controller.isEdit.value) {
                  return Row(
                    children: [
                      if (StaffAccess.canDeleteProducts)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: controller.showDeleteConfirmationDialog,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColor.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppColor.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color: AppColor.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (StaffAccess.canDeleteProducts &&
                          StaffAccess.canUpdateProducts)
                        const SizedBox(width: 16),
                      if (StaffAccess.canUpdateProducts)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: controller.onUpdateItem,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Update',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }

                return Row(
                  children: [
                    if (StaffAccess.canCreateProducts)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.saveAndNew,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppColor.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            loc.save_and_new,
                            style: TextStyle(
                              color: AppColor.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (StaffAccess.canCreateProducts)
                      const SizedBox(width: 16),
                    if (StaffAccess.canCreateProducts)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: controller.saveItem,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            loc.save_item,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              });
            }

            final formContent = Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle(
                    controller.isEdit.value
                        ? loc.edit_menu_item
                        : loc.addMenuItem,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.tap_to_enter,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (!isWide) ...[
                    buildAvailabilityTile(),
                    const SizedBox(height: 12),
                    buildRecommendedTile(),
                    const SizedBox(height: 16),
                    imageFieldLabel(loc.item_image),
                    const SizedBox(height: 8),
                    buildImagePicker(),
                    const SizedBox(height: 18),
                  ],

                  requiredFieldLabel(loc.item_name),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.itemNameController,
                    validator: controller.validateItemName,
                    decoration: inputDecoration(hintText: loc.tap_to_enter),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(child: fieldLabel(loc.item_category)),
                      TextButton.icon(
                        onPressed: controller.showQuickAddCategoryDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(loc.add_category),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColor.primary,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    // Rebuild when category images load/update.
                    final _ = controller.categoryDetails.length;
                    return AppDropdownFormField2<String>(
                      isExpanded: true,
                      decoration: inputDecoration(),
                      value: controller.selectedCategoryDropdownValue,
                      items: controller.categories
                          .map(
                            (category) => DropdownItem<String>(
                              value: category,
                              child: _buildCategoryOption(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectCategory(value);
                        }
                      },
                      iconStyleData: IconStyleData(
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColor.primary,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 18),

                  Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fastfood_outlined,
                            color: AppColor.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Combo item',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[850],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sell selected menu items together as one meal.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: controller.isComboItem.value,
                            activeThumbColor: AppColor.primary.withValues(
                              alpha: 0.95,
                            ),
                            activeTrackColor: AppColor.primary.withValues(
                              alpha: 0.25,
                            ),
                            onChanged: controller.setComboItem,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  _buildComboComponentsSection(context),
                  Obx(() {
                    if (!controller.isWithTax.value) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),
                        fieldLabel(loc.tax_percentage),
                        const SizedBox(height: 8),
                        AppDropdownFormField2<String>(
                          isExpanded: true,
                          decoration: inputDecoration(),
                          value: controller.selectedTaxPercentage.value,
                          items: controller.taxOptions
                              .map(
                                (tax) => DropdownItem<String>(
                                  value: tax,
                                  child: Text(tax == 'None' ? tax : '$tax%'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.selectedTaxPercentage.value = value;
                            }
                          },
                          iconStyleData: IconStyleData(
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: AppColor.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    );
                  }),
                  requiredFieldLabel(loc.sale_price),
                  const SizedBox(height: 8),
                  Obx(
                    () => TextFormField(
                      controller: controller.salePriceController,
                      validator: controller.validateSalePrice,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: inputDecoration(
                        hintText: loc.tap_to_enter,
                        suffixText: controller.isWithTax.value
                            ? loc.with_tax
                            : loc.without_tax,
                        suffixIcon: IconButton(
                          tooltip: controller.isWithTax.value
                              ? loc.with_tax
                              : loc.without_tax,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColor.primary,
                          ),
                          onPressed: () {
                            final withTax = !controller.isWithTax.value;
                            controller.isWithTax.value = withTax;
                            if (!withTax) {
                              controller.selectedTaxPercentage.value = 'None';
                            } else if (controller.selectedTaxPercentage.value ==
                                'None') {
                              controller.selectedTaxPercentage.value = '5';
                            }
                          },
                        ),
                      ),
                    ),
                  ),

                  ProductFormExtras(
                    controller: controller,
                    showBarcodeScanner: true,
                    onScanBarcode: controller.scanBarcode,
                  ),

                  Obx(
                    () => ProductVariantsSection(
                      enabled: controller.hasVariantsEnabled.value,
                      variants: controller.variantDrafts.toList(),
                      onEnabledChanged: controller.setVariantsEnabled,
                      onAddVariant: () => controller.addVariantDraft(),
                      onRemoveVariant: controller.removeVariantDraft,
                      onSetDefault: controller.setDefaultVariantDraft,
                    ),
                  ),

                  fieldLabel('Kitchen prep time (minutes)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.prepTimeController,
                    validator: controller.validatePrepTime,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: inputDecoration(hintText: 'e.g. 15'),
                  ),

                  const SizedBox(height: 28),

                  Obx(() {
                    final isEdit = controller.isEdit.value;
                    final itemId = controller.itemId.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 18),
                        MenuItemRecipeSection(
                          itemId: isEdit ? itemId : '',
                          itemName: controller.itemNameController.text,
                          linkedRecipeItemId:
                              controller.linkedRecipeItemId.value,
                          onLinkedRecipeChanged: (id) {
                            controller.linkedRecipeItemId.value = id;
                          },
                        ),
                        const SizedBox(height: 18),
                      ],
                    );
                  }),

                  buildButtons(),
                  const SizedBox(height: 18),
                ],
              ),
            );

            final rightRail = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildAvailabilityTile(),
                const SizedBox(height: 12),
                buildRecommendedTile(),
                const SizedBox(height: 16),
                imageFieldLabel(loc.item_image),
                const SizedBox(height: 8),
                buildImagePicker(),
              ],
            );

            final content = isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: formContent),
                      const SizedBox(width: 20),
                      Expanded(flex: 4, child: rightRail),
                    ],
                  )
                : formContent;

            return Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 24 : 16,
                  vertical: isWide ? 20 : 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isWide ? 22 : 16),
                        child: content,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryOption(String category) {
    final categoryImage = controller.getCategoryImageUrl(category);
    return Row(
      children: [
        _buildCategoryAvatar(categoryImage),
        if (categoryImage.isNotEmpty) const SizedBox(width: 10),
        Flexible(
          child: Text(
            category.capitalize ?? '',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryAvatar(String imageUrl) {
    if (imageUrl.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        resolvedMediaUrl(imageUrl),
        width: 26,
        height: 26,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Leave item screen?'),
        content: const Text('Your unsaved item changes will be discarded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Widget _buildComboComponentsSection(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (!controller.isComboItem.value) return const SizedBox.shrink();

      final selectedItems = controller.selectedComboItems;
      final selectedCount = controller.comboComponentQuantities.length;
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Meal items',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    controller.clearComboComponentSearch(reload: false);
                    controller.seedComboComponentOptions(force: true);
                    _showComboComponentPicker();
                    controller.loadComboComponentOptions();
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: Text(selectedCount == 0 ? 'Add items' : 'Edit items'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (selectedCount == 0)
              Text(
                'Choose the menu items included in this meal.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              )
            else if (selectedItems.isEmpty)
              Text(
                '$selectedCount item(s) selected. Open Edit items to refresh names.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
              )
            else
              ...selectedItems.map((item) {
                final qty = controller.comboComponentQuantities[item.id] ?? 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      _buildMealItemImage(item.itemImage),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName.capitalize ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _buildMealItemPriceText(item),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            controller.decrementComboComponent(item.id),
                        icon: const Icon(Icons.remove_circle_outline),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      Text(
                        qty.toStringAsFixed(
                          qty.truncateToDouble() == qty ? 0 : 2,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        onPressed: () =>
                            controller.incrementComboComponent(item.id),
                        icon: const Icon(Icons.add_circle_outline),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 14),
            Builder(
              builder: (_) {
                final totals = controller.comboCostBreakdown;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildComboCostSummaryRow(
                      'Amount',
                      '₹${_formatMealAmount(totals.base)}',
                    ),
                    const SizedBox(height: 4),
                    _buildComboCostSummaryRow(
                      'Tax',
                      '₹${_formatMealAmount(totals.tax)}',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Cost price (total)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.costPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Total amount',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixText: '₹ ',
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColor.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildComboCostSummaryRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey.shade900,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showComboComponentPicker() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 560,
          height: 600,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Choose meal items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        controller.clearComboComponentSearch(reload: false);
                        Get.back();
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final hasQuery = controller.comboSearchQuery.value.isNotEmpty;
                  return TextField(
                    controller: controller.comboSearchController,
                    onChanged: controller.filterComboComponentOptions,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search menu items',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: hasQuery
                          ? IconButton(
                              onPressed: controller.clearComboComponentSearch,
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColor.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    // Track RxMap so checkbox / qty UI rebuilds on toggle.
                    final selectedQty = controller.comboComponentQuantities;
                    final _ = selectedQty.length;
                    final __ = controller.comboSearchQuery.value;

                    if (controller.isLoadingComboOptions.value &&
                        controller.comboComponentOptions.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final options = controller.comboComponentOptions;
                    if (options.isEmpty) {
                      return Center(
                        child: Text(
                          controller.comboSearchQuery.value.isEmpty
                              ? 'No menu items available to add.'
                              : 'No items match your search.',
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        ListView.separated(
                          itemCount: options.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = options[index];
                            final selected = selectedQty.containsKey(item.id);
                            final qty = selectedQty[item.id] ?? 1;
                            return _buildComboOptionTile(
                              context,
                              item: item,
                              selected: selected,
                              qty: qty,
                            );
                          },
                        ),
                        if (controller.isLoadingComboOptions.value)
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      controller.clearComboComponentSearch(reload: false);
                      Get.back();
                    },
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComboOptionTile(
    BuildContext context, {
    required ItemData item,
    required bool selected,
    required double qty,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.setComboComponent(item, !selected),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColor.primary.withValues(alpha: 0.06)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColor.primary : Colors.grey.shade300,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                activeColor: AppColor.primary,
                checkColor: Colors.white,
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColor.primary;
                  }
                  return Colors.white;
                }),
                side: BorderSide(color: Colors.grey.shade700, width: 1.6),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (value) =>
                    controller.setComboComponent(item, value == true),
              ),
              const SizedBox(width: 4),
              _buildMealItemImage(item.itemImage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    _buildMealItemPriceText(item),
                  ],
                ),
              ),
              if (selected)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () =>
                          controller.decrementComboComponent(item.id),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(qty.toStringAsFixed(0)),
                    IconButton(
                      onPressed: () =>
                          controller.incrementComboComponent(item.id),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealItemPriceText(ItemData item) {
    final tax = controller.comboItemTaxAmount(item);
    final total = controller.comboItemPriceWithTax(item);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount ₹${_formatMealAmount(item.salePrice)}',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
        Text(
          tax > 0 ? 'Tax ${item.gst}% · ₹${_formatMealAmount(tax)}' : 'Tax ₹0',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
        Text(
          'Total ₹${_formatMealAmount(total)}',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatMealAmount(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  Widget _buildMealItemImage(String imageUrl) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          resolvedMediaUrl(imageUrl),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildMealImageFallback(),
        ),
      );
    }
    return _buildMealImageFallback();
  }

  Widget _buildMealImageFallback() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.restaurant_menu, size: 20, color: Colors.grey.shade600),
    );
  }

  Widget _buildEmptyImagePlaceholder(AppLocalizations loc) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 12),
              Text(
                loc.upload_item_image,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Star icon in top right corner (matching the design)
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star, color: AppColor.primary, size: 20),
          ),
        ),
      ],
    );
  }
}
