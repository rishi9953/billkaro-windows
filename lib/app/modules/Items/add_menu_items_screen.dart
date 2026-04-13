import 'package:billkaro/app/modules/Items/add_menu_items_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AddMenuItemScreen extends StatelessWidget {
  const AddMenuItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddMenuItemController());
    final rawArgs = Get.arguments ?? Modular.args.data;
    final args = rawArgs is Map<String, dynamic> ? rawArgs : null;
    controller.configureFromArgs(args);
    var loc = AppLocalizations.of(Get.context!)!;
    final scrollController = ScrollController();
    final theme = Theme.of(context);
    return Scaffold(
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
                        child: SizedBox(
                          width: double.infinity,
                          child: image,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          tooltip: 'Close',
                          onPressed: () =>
                              Navigator.of(dialogContext, rootNavigator: true)
                                  .pop(),
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
                  child: controller.isGeneratingImage.value
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 14),
                              Text(
                                'AI is generating image...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : controller.isScanning.value
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      'Availability',
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

          Widget buildButtons() {
            return Obx(() {
              if (controller.isEdit.value) {
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.onDeleteItem,
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
                    const SizedBox(width: 16),
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
                  const SizedBox(width: 16),
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

          final formContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle(
                controller.isEdit.value ? loc.edit_menu_item : loc.addMenuItem,
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
                const SizedBox(height: 16),
                imageFieldLabel(loc.item_image),
                const SizedBox(height: 8),
                buildImagePicker(),
                const SizedBox(height: 18),
              ],

              fieldLabel('${loc.item_name} *'),
              const SizedBox(height: 8),
              TextField(
                controller: controller.itemNameController,
                decoration: inputDecoration(hintText: loc.tap_to_enter),
              ),
              const SizedBox(height: 18),

              fieldLabel(loc.item_category),
              const SizedBox(height: 8),
              Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.selectedCategory.value.toLowerCase(),
                  decoration: inputDecoration(),
                  items: controller.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.capitalize ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    controller.selectedCategory.value = value!;
                  },
                ),
              ),
              const SizedBox(height: 18),

              fieldLabel(loc.sale_price),
              const SizedBox(height: 8),
              Obx(
                () => TextField(
                  controller: controller.salePriceController,
                  keyboardType: TextInputType.number,
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
                        controller.isWithTax.value =
                            !controller.isWithTax.value;
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              fieldLabel(loc.tax_percentage),
              const SizedBox(height: 8),
              Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.selectedTaxPercentage.value,
                  decoration: inputDecoration(),
                  items: controller.taxOptions
                      .map(
                        (tax) => DropdownMenuItem(
                          value: tax,
                          child: Text(tax == 'None' ? tax : '$tax%'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    controller.selectedTaxPercentage.value = value!;
                  },
                ),
              ),
              const SizedBox(height: 28),

              buildButtons(),
              const SizedBox(height: 18),
            ],
          );

          final rightRail = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildAvailabilityTile(),
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
