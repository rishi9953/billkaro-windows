import 'package:billkaro/app/services/Modals/customer/customerResponse.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/foundation.dart';

class CutomerListController extends BaseController {
  var customerList = <CustomerData>[].obs;
  final isLoading = false.obs;
  final loadError = ''.obs;
  final hasLoadedOnce = false.obs;

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
