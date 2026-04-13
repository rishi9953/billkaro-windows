import 'dart:io';

import 'package:billkaro/app/modules/AddOrder/AddCategory/add_category_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/widgets.dart' show Image;

class AddCategoryScreen extends StatelessWidget {
  AddCategoryScreen({super.key});

  final controller = Get.put(AddCategoryController());

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isEdit.value ? loc.edit_category : loc.add_category,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final maxWidth = isDesktop ? 1100.0 : 720.0;

          Widget leftList() {
            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          loc.all_categories,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: loc.add_category,
                          onPressed: () {
                            controller.isEdit.value = false;
                            controller.resetForm();
                          },
                          icon: const Icon(Icons.add),
                          color: AppColor.primary,
                          splashRadius: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Obx(() {
                        if (controller.categories.isEmpty) {
                          return Center(
                            child: Text(
                              'No categories yet',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          );
                        }
                        return Scrollbar(
                          thumbVisibility: isDesktop,
                          child: ListView.separated(
                            physics: const ClampingScrollPhysics(),
                            itemCount: controller.categories.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, index) {
                              final cat = controller.categories[index];
                              return ListTile(
                                dense: true,
                                leading: cat.imageURL.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          cat.imageURL,
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) {
                                            return CircleAvatar(
                                              radius: 18,
                                              backgroundColor:
                                                  Colors.grey.shade300,
                                              child: const Icon(
                                                Icons.category,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.category,
                                          color: Colors.white,
                                        ),
                                      ),
                                title: Text(
                                  (cat.categoryName.capitalize ??
                                      cat.categoryName),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: IconButton(
                                  tooltip: loc.delete,
                                  icon: Assets.svg.delete.svg(
                                    width: 20,
                                    height: 20,
                                  ),
                                  onPressed: () =>
                                      controller.deleteCategory(index),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          }

          Widget rightEditor() {
            Widget buildCategoryImagePicker() {
              return Obx(
                () => InkWell(
                  onTap: controller.uploadImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: controller.selectedImage.value != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(controller.selectedImage.value!.path),
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    tooltip: 'Change image',
                                    onPressed: controller.uploadImage,
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 18,
                                    ),
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
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildImagePlaceholder(loc);
                                  },
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    tooltip: 'Change image',
                                    onPressed: controller.uploadImage,
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _buildImagePlaceholder(loc),
                  ),
                ),
              );
            }

            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        controller.isEdit.value
                            ? loc.edit_category
                            : loc.add_category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      loc.category_name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller.categoryNameController,
                      decoration: InputDecoration(
                        hintText: loc.enter_category_name,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(height: 14),
                    Text(
                      'Category image',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    buildCategoryImagePicker(),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.items_shown_by_category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Obx(() {
                      final isEdit = controller.isEdit.value;
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                controller.isEdit.value = false;
                                controller.resetForm();
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(loc.cancel),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isEdit
                                  ? controller.updateCategory
                                  : controller.addCategory,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                isEdit ? loc.update_category : loc.add_category,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          }

          final content = isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 380, child: leftList()),
                    const SizedBox(width: 16),
                    Expanded(child: rightEditor()),
                  ],
                )
              : Column(
                  children: [
                    SizedBox(height: 260, child: rightEditor()),
                    const SizedBox(height: 12),
                    SizedBox(height: 420, child: leftList()),
                  ],
                );

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(padding: const EdgeInsets.all(16), child: content),
            ),
          );
        },
      ),
    );
  }
}

Widget _buildImagePlaceholder(AppLocalizations loc) {
  return Container(
    width: double.infinity,
    height: 150,
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 34,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 8),
        Text(
          loc.upload_item_image,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
