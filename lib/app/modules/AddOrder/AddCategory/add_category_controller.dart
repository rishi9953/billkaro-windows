import 'dart:io';

import 'package:billkaro/app/Widgets/desktop_camera_capture_dialog.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/services/Modals/Categories/bulk_delete_categories_request.dart';
import 'package:billkaro/app/services/Modals/Categories/categories_response.dart';
import 'package:billkaro/app/services/uploadFile.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:billkaro/utils/offline/offline_category_loader.dart';
import 'package:billkaro/utils/staff_access.dart';

class AddCategoryController extends BaseController {
  RxList<CategoryData> categories = <CategoryData>[].obs;
  TextEditingController categoryNameController = TextEditingController();
  var categoryId = ''.obs;
  var imageUrl = ''.obs;
  final ImagePicker _picker = ImagePicker();
  var selectedImage = Rx<File?>(null);

  final isEdit = false.obs;
  final isSelectionMode = false.obs;
  final selectedCategoryIds = <String>[].obs;
  final isDeletingCategories = false.obs;
  AddOrderController? addOrderController;
  MenuItemController? menuItemController;

  Future<void> uploadImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      showError(description: 'Failed to pick image: $e');
    }
  }

  Future<void> uploadImageFromCamera() async {
    try {
      String? path;
      if (_usesDesktopCameraPlugin()) {
        path = await showDesktopCameraCaptureDialog();
      } else {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );
        path = image?.path;
      }

      if (path == null || path.isEmpty) return;
      selectedImage.value = File(path);

      if (_usesDesktopCameraPlugin()) {
        showSuccess(description: 'Photo captured successfully.');
      }
    } catch (e) {
      showError(description: 'Failed to capture image: $e');
    }
  }

  bool _usesDesktopCameraPlugin() {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  Future<void> uploadImage() async {
    final source = await _pickImageSourceDialog();
    if (source == null) return;

    if (source == ImageSource.camera) {
      await uploadImageFromCamera();
    } else {
      await uploadImageFromGallery();
    }
  }

  Future<ImageSource?> _pickImageSourceDialog() async {
    final isDesktop = _usesDesktopCameraPlugin();
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    final dialogWidth = isDesktop
        ? (screenWidth * 0.35).clamp(320.0, 480.0)
        : (screenWidth * 0.9).clamp(280.0, 420.0);

    return Get.dialog<ImageSource>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: dialogWidth,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColor.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Select Image Source',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose how you want to add a category image',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _imageSourceOption(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        subtitle: isDesktop ? 'USB / webcam' : 'Take photo',
                        onTap: () => Get.back(result: ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _imageSourceOption(
                        icon: isDesktop
                            ? Icons.folder_open_outlined
                            : Icons.photo_library_outlined,
                        label: isDesktop ? 'Browse Files' : 'Gallery',
                        subtitle: 'Choose photo',
                        onTap: () => Get.back(result: ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Widget _imageSourceOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColor.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColor.primary.withOpacity(0.28)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            child: Column(
              children: [
                Icon(icon, size: 30, color: AppColor.primary),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> uploadCategoryImage() async {
    if (selectedImage.value == null) return true;
    final response = await callApi(
      MediaApi().uploadImage(
        file: File(selectedImage.value!.path),
        folderName: 'categories',
        outletId: appPref.selectedOutlet!.id!,
        userId: appPref.user!.id!,
      ),
    );
    if (response?.data?['url'] != null) {
      imageUrl.value = response!.data['url'];
      return true;
    }
    showError(description: 'Image upload failed. Please try again.');
    return false;
  }

  void removeCategoryImage() {
    selectedImage.value = null;
    imageUrl.value = '';
  }

  void resetForm() {
    categoryNameController.clear();
    selectedImage.value = null;
    imageUrl.value = '';
    categoryId.value = '';
  }

  void startEditCategory(CategoryData category) {
    if (!StaffAccess.ensure(StaffAccess.canUpdateCategories)) return;
    isEdit.value = true;
    categoryId.value = category.id;
    categoryNameController.text = category.categoryName;
    imageUrl.value = category.imageURL;
    // Reset newly picked image when switching between categories.
    selectedImage.value = null;
  }

  Future<void> addCategory() async {
    if (!StaffAccess.ensure(StaffAccess.canCreateCategories)) return;
    final loc = AppLocalizations.of(Get.context!)!;
    if (categoryNameController.text.trim().isEmpty) {
      showError(description: loc.category_name_cannot_be_empty);
      return;
    }

    try {
      if (selectedImage.value != null) {
        final ok = await uploadCategoryImage();
        if (!ok) return;
      }
      final response = await callApi(
        apiClient.addCategory(appPref.selectedOutlet!.id!, {
          'userId': appPref.user!.id,
          'outletId': appPref.selectedOutlet!.id,
          'categoryName': categoryNameController.text.trim().toLowerCase(),
          'imageURL': imageUrl.value,
        }),
        showLoader: false,
      );

      if (response != null && response['status'] == 'success') {
        resetForm();
        // Refresh categories in both controllers
        await getCategories(showloader: false);
        await addOrderController?.getCategories();
        await menuItemController?.getCategories();

        showSuccess(
          description: response['message'] ?? loc.category_added_successfully,
        );
      } else {
        showError(
          description: response?['message'] ?? loc.failed_to_add_category,
        );
      }
    } catch (e) {
      showError(description: loc.error_adding_category);
      debugPrint('Error in addCategory: $e');
    }
  }

  Future<void> getCategories({bool showloader = true}) async {
    try {
      final outletId = appPref.selectedOutlet?.id;
      if (outletId == null) return;

      final loaded = await OfflineCategoryLoader.load(
        outletId: outletId,
        fetchFromApi: () => callApi(
          apiClient.getCategories(outletId),
          showLoader: showloader,
        ),
      );

      categories.clear();
      categories.addAll(loaded);
      dismissAllAppLoader();
    } catch (e) {
      dismissAllAppLoader();
      debugPrint('Error in getCategories: $e');
      if (Get.context != null) {
        final loc = AppLocalizations.of(Get.context!)!;
        showError(description: loc.failed_to_load_categories);
      }
    }
  }

  void toggleSelectionMode() {
    if (isSelectionMode.value) {
      exitSelectionMode();
    } else {
      isSelectionMode.value = true;
      isEdit.value = false;
      resetForm();
    }
  }

  void exitSelectionMode() {
    isSelectionMode.value = false;
    selectedCategoryIds.clear();
  }

  void toggleCategorySelection(String categoryId) {
    if (selectedCategoryIds.contains(categoryId)) {
      selectedCategoryIds.remove(categoryId);
    } else {
      selectedCategoryIds.add(categoryId);
    }
  }

  bool isCategorySelected(String categoryId) =>
      selectedCategoryIds.contains(categoryId);

  void selectAllCategories() {
    selectedCategoryIds
      ..clear()
      ..addAll(categories.map((e) => e.id));
    selectedCategoryIds.refresh();
  }

  void clearCategorySelection() {
    selectedCategoryIds.clear();
    selectedCategoryIds.refresh();
  }

  Future<void> deleteCategory(int index) async {
    if (!StaffAccess.ensure(StaffAccess.canDeleteCategories)) return;
    final loc = AppLocalizations.of(Get.context!)!;
    if (index < 0 || index >= categories.length) {
      showError(description: loc.invalid_category_selection);
      return;
    }

    final id = categories[index].id;
    final ok = await _deleteCategoriesByIds([id], clearSelection: false);
    if (ok) {
      showSuccess(description: loc.category_deleted_successfully);
    }
  }

  Future<void> deleteSelectedCategories() async {
    if (!StaffAccess.ensure(StaffAccess.canDeleteCategories)) return;
    final loc = AppLocalizations.of(Get.context!)!;
    if (selectedCategoryIds.isEmpty) {
      showError(description: loc.select_at_least_one_item_to_delete);
      return;
    }

    final count = selectedCategoryIds.length;
    final shouldDelete =
        await Get.dialog<bool>(
          AlertDialog(
            title: Text(loc.delete),
            content: Text(
              count == 1
                  ? 'Are you sure you want to delete the selected category?'
                  : 'Are you sure you want to delete $count selected categories?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text(loc.cancel),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(loc.delete),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldDelete) return;

    final ids = selectedCategoryIds.toList();
    final ok = await _deleteCategoriesByIds(ids, clearSelection: true);
    if (ok) {
      showSuccess(
        description: count == 1
            ? loc.category_deleted_successfully
            : '$count categories deleted successfully',
      );
    }
  }

  Future<bool> _deleteCategoriesByIds(
    List<String> ids, {
    required bool clearSelection,
  }) async {
    if (ids.isEmpty) return false;
    final loc = AppLocalizations.of(Get.context!)!;
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      showError(description: loc.please_select_outlet_first);
      return false;
    }

    isDeletingCategories.value = true;
    showAppLoader();

    try {
      final uniqueIds = ids.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet().toList();
      final response = await callApi(
        apiClient.deleteBulkCategories(
          outletId,
          BulkDeleteCategoriesRequest(categoryIds: uniqueIds),
        ),
        showLoader: false,
      );

      if (response != null && response['status'] == 'success') {
        for (final id in uniqueIds) {
          if (categoryId.value == id) {
            isEdit.value = false;
            resetForm();
            break;
          }
        }
        if (clearSelection) {
          exitSelectionMode();
        }
        await getCategories(showloader: false);
        await addOrderController?.getCategories();
        await menuItemController?.getCategories();
        return true;
      }

      showError(
        description: response?['message']?.toString().isNotEmpty == true
            ? response!['message'].toString()
            : loc.failed_to_delete_category,
      );
      return false;
    } catch (e) {
      showError(description: loc.error_deleting_category);
      debugPrint('Error in _deleteCategoriesByIds: $e');
      return false;
    } finally {
      isDeletingCategories.value = false;
      dismissAllAppLoader();
    }
  }

  void updateCategory() async {
    if (!StaffAccess.ensure(StaffAccess.canUpdateCategories)) return;
    final loc = AppLocalizations.of(Get.context!)!;
    final id = categoryId.value;
    final name = categoryNameController.text.trim().toLowerCase();

    try {
      if (selectedImage.value != null) {
        final ok = await uploadCategoryImage();
        if (!ok) return;
      }
      final response = await callApi(
        apiClient.updateCategory(appPref.selectedOutlet!.id!, id, {
          'userId': appPref.user!.id,
          "categoryName": name,
          'outletId': appPref.selectedOutlet!.id,
          'imageURL': imageUrl.value,
        }),
      );
      debugPrint('Update response: $response');

      if (response != null && response['status'] == 'success') {
        // Refresh categories in both controllers
        await getCategories(showloader: false);
        await addOrderController?.getCategories();
        await menuItemController?.getCategories();
        dismissAllAppLoader();
        showSuccess(
          description: response['message'] ?? loc.category_updated_successfully,
        );
      } else {
        showError(
          description: response?['message'] ?? loc.failed_to_update_category,
        );
      }
    } catch (e) {
      showError(description: loc.error_updating_category);
      debugPrint('Error in updateCategory: $e');
    }
  }

  void toggleEdit() {
    final dynamic rawArgs = Get.arguments ?? Modular.args.data;
    final args = rawArgs is Map ? rawArgs : null;
    if (args != null && args['isEdit'] == true) {
      isEdit.value = true;
      final dynamic rawCategory = args['category'];

      if (rawCategory is CategoryData) {
        debugPrint(
          'Editing category: ${rawCategory.categoryName} (ID: ${rawCategory.id})',
        );
        startEditCategory(rawCategory);
        return;
      }

      // Fallback for cases where arguments were serialized into a Map.
      if (rawCategory is Map) {
        final name = rawCategory['categoryName']?.toString() ?? '';
        final id = rawCategory['id']?.toString() ?? '';
        final image =
            rawCategory['categoryImage']?.toString() ??
            rawCategory['imageURL']?.toString() ??
            '';
        categoryNameController.text = name;
        categoryId.value = id;
        imageUrl.value = image;
        selectedImage.value = null;
        return;
      }
      return;
    } else {
      isEdit.value = false;
      resetForm();
    }
  }

  void initialzeController() {
    // Try to find both controllers if they exist
    try {
      addOrderController = Get.find<AddOrderController>();
    } catch (e) {
      debugPrint('AddOrderController not found: $e');
    }

    try {
      menuItemController = Get.find<MenuItemController>();
    } catch (e) {
      debugPrint('MenuItemController not found: $e');
    }
  }

  @override
  void onInit() {
    initialzeController();
    // Prefill edit fields immediately (don’t wait for API categories load).
    toggleEdit();
    super.onInit();
  }

  @override
  void onClose() {
    categoryNameController.dispose();
    super.onClose();
  }

  @override
  void onReady() {
    getCategories();
    super.onReady();
  }
}
