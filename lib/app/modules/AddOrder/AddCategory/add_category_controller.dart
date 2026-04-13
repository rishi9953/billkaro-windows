import 'dart:io';

import 'package:billkaro/app/Widgets/desktop_camera_capture_dialog.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/services/Modals/Categories/categories_response.dart';
import 'package:billkaro/app/services/uploadFile.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AddCategoryController extends BaseController {
  RxList<CategoryData> categories = <CategoryData>[].obs;
  TextEditingController categoryNameController = TextEditingController();
  var categoryId = ''.obs;
  var imageUrl = ''.obs;
  final ImagePicker _picker = ImagePicker();
  var selectedImage = Rx<File?>(null);

  final isEdit = false.obs;
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

  void uploadImage() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: AppColor.primary),
                title: const Text('Gallery'),
                onTap: () {
                  Get.back();
                  uploadImageFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: AppColor.primary),
                title: const Text('Camera'),
                onTap: () {
                  Get.back();
                  uploadImageFromCamera();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  void resetForm() {
    categoryNameController.clear();
    selectedImage.value = null;
    imageUrl.value = '';
  }

  Future<void> addCategory() async {
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
          'categoryImage': imageUrl.value,
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
      final response = await callApi(
        apiClient.getCategories(appPref.selectedOutlet!.id!),
        showLoader: showloader,
      );

      if (response != null && response.status == 'success') {
        debugPrint('Response: $response');

        final List<CategoryData> categoryList = response.categories;

        categories.clear();
        categories.addAll(categoryList);
        dismissAllAppLoader();
      } else {
        dismissAllAppLoader();
        final loc = AppLocalizations.of(Get.context!)!;
        showError(description: loc.failed_to_load_categories);
      }
    } catch (e) {
      dismissAllAppLoader();
      debugPrint('Error in getCategories: $e');
    }

    toggleEdit();
  }

  void deleteCategory(int index) async {
    final loc = AppLocalizations.of(Get.context!)!;
    if (index < 0 || index >= categories.length) {
      showError(description: loc.invalid_category_selection);
      return;
    }

    final id = categories[index].id;

    try {
      final response = await callApi(
        apiClient.deleteCategory(appPref.selectedOutlet!.id!, id),
        showLoader: false,
      );
      debugPrint('Delete response: $response');

      if (response != null && response['status'] == 'success') {
        // Refresh categories in both controllers
        await getCategories(showloader: false);
        await addOrderController?.getCategories();
        await menuItemController?.getCategories();
        dismissAllAppLoader();
        showSuccess(
          description: response['message'] ?? loc.category_deleted_successfully,
        );
      } else {
        showError(
          description: response?['message'] ?? loc.failed_to_delete_category,
        );
      }
    } catch (e) {
      showError(description: loc.error_deleting_category);
      debugPrint('Error in deleteCategory: $e');
    }
  }

  void updateCategory() async {
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
          'categoryImage': imageUrl.value,
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
        categoryNameController.text = rawCategory.categoryName;
        categoryId.value = rawCategory.id;
        imageUrl.value = '';
        return;
      }

      // Fallback for cases where arguments were serialized into a Map.
      if (rawCategory is Map) {
        final name = rawCategory['categoryName']?.toString() ?? '';
        final id = rawCategory['id']?.toString() ?? '';
        final image = rawCategory['categoryImage']?.toString() ?? '';
        categoryNameController.text = name;
        categoryId.value = id;
        imageUrl.value = image;
        return;
      }
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
