import 'package:billkaro/app/services/Modals/customer/customerResponse.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:flutter/foundation.dart';

class CutomerListController extends BaseController {
  var customerList = <CustomerData>[].obs;
  final isLoading = false.obs;
  final loadError = ''.obs;
  final hasLoadedOnce = false.obs;

  Future<void> deleteRegularCustomer(CustomerData customer) async {
    if (!StaffAccess.ensure(StaffAccess.canDeleteCustomers)) return;

    final loc = AppLocalizations.of(Get.context!)!;
    final outletId = appPref.selectedOutlet?.id;
    final id = customer.id.trim();

    if (outletId == null) {
      showError(description: loc.please_select_outlet_first);
      return;
    }
    if (id.isEmpty) {
      showError(description: loc.error_occurred_try_again);
      return;
    }

    final customerName = customer.customerName.trim().isEmpty
        ? loc.customer_section_title
        : customer.customerName.trim();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(loc.delete),
        content: Text(loc.delete_confirm_message(customerName)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(Get.context!).colorScheme.error,
            ),
            onPressed: () => Get.back(result: true),
            child: Text(loc.delete),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    if (confirmed != true) return;

    final response = await callApi(
      apiClient.deleteRegularCustomer(outletId, id),
    );
    if (response is Map && response['status']?.toString() == 'success') {
      customerList.removeWhere((c) => c.id == id);
      showSuccess(
        description: response['message']?.toString() ?? loc.customer_deleted,
      );
    }
  }

  Future<void> getCustomerList() async {
    final loc = AppLocalizations.of(Get.context!)!;
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      loadError.value = loc.no_outlet_selected;
      customerList.clear();
      hasLoadedOnce.value = true;
      return;
    }

    final isOnline = await NetworkUtils.hasInternetConnection();
    if (!isOnline) {
      loadError.value = loc.unable_to_load_customers_connection;
      customerList.clear();
      hasLoadedOnce.value = true;
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    loadError.value = '';

    try {
      final response = await callApi(
        apiClient.getRegularCustomer(outletId),
        showLoader: false,
      );

      if (response?.status == 'success') {
        customerList.value = response!.data;
      } else {
        loadError.value = loc.unable_to_load_customers;
        customerList.clear();
      }
    } catch (e) {
      debugPrint('Customer list error: $e');
      loadError.value = loc.unable_to_load_customers_connection;
      customerList.clear();
    } finally {
      isLoading.value = false;
      hasLoadedOnce.value = true;
    }
  }

  @override
  void onReady() {
    getCustomerList();
    super.onReady();
  }
}
