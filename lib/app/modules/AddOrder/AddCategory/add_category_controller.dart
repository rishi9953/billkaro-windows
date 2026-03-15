import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/services/Modals/Categories/categories_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddCategoryController extends BaseController {
  RxList<CategoryData> categories = <CategoryData>[].obs;
  TextEditingController categoryNameController = TextEditingController();
  var categoryId = ''.obs;

  final isEdit = false.obs;
  AddOrderController? addOrderController;
  MenuItemController? menuItemController;

  Future<void> addCategory() async {
    final loc = AppLocalizations.of(Get.context!)!;
    if (categoryNameController.text.trim().isEmpty) {
      showError(description: loc.category_name_cannot_be_empty);
      return;
    }

    try {
      final response = await callApi(
        apiClient.addCategory(appPref.selectedOutlet!.id!, {
          'userId': appPref.user!.id,
          'outletId': appPref.selectedOutlet!.id,
          'categoryName': categoryNameController.text.trim().toLowerCase(),
        }),
        showLoader: false,
      );

      if (response != null && response['status'] == 'success') {
        categoryNameController.clear();
        // Refresh categories in both controllers
        await getCategories(showloader: false);
        await addOrderController?.getCategories();
        await menuItemController?.getCategories();

        showSuccess(description: response['message'] ?? loc.category_added_successfully);
      } else {
        showError(description: response?['message'] ?? loc.failed_to_add_category);
      }
    } catch (e) {
      showError(description: loc.error_adding_category);
      debugPrint('Error in addCategory: $e');
    }
  }

  Future<void> getCategories({bool showloader = true}) async {
    try {
      final response = await callApi(apiClient.getCategories(appPref.selectedOutlet!.id!), showLoader: showloader);

      if (response != null && response.status == 'success') {
        debugPrint('Response: $response');

        List<CategoryData> categoryList = response.categories ?? [];

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
      final response = await callApi(apiClient.deleteCategory(appPref.selectedOutlet!.id!, id), showLoader: false);
      debugPrint('Delete response: $response');

      if (response != null && response['status'] == 'success') {
        // Refresh categories in both controllers
        await getCategories(showloader: false);
        await addOrderController?.getCategories();
        await menuItemController?.getCategories();
        dismissAllAppLoader();
        showSuccess(description: response['message'] ?? loc.category_deleted_successfully);
      } else {
        showError(description: response?['message'] ?? loc.failed_to_delete_category);
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
      final response = await callApi(
        apiClient.updateCategory(appPref.selectedOutlet!.id!, id, {'userId': appPref.user!.id, "categoryName": name, 'outletId': appPref.selectedOutlet!.id}),
      );
      debugPrint('Update response: $response');

      if (response != null && response['status'] == 'success') {
        // Refresh categories in both controllers
        await getCategories(showloader: false);
        await addOrderController?.getCategories();
        await menuItemController?.getCategories();
        dismissAllAppLoader();
        showSuccess(description: response['message'] ?? loc.category_updated_successfully);
      } else {
        showError(description: response?['message'] ?? loc.failed_to_update_category);
      }
    } catch (e) {
      showError(description: loc.error_updating_category);
      debugPrint('Error in updateCategory: $e');
    }
  }

  void toggleEdit() {
    final args = Get.arguments;
    if (args != null && args['isEdit'] == true) {
      isEdit.value = true;
      var category = args['category'] as CategoryData;
      categoryNameController.text = category.categoryName ?? '';
      categoryId.value = category.id;
    } else {
      isEdit.value = false;
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
    super.onInit();
  }

  @override
  void onReady() {
    getCategories();
    super.onReady();
  }
}
