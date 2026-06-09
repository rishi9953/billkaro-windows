import 'package:billkaro/app/services/Modals/customer/customerResponse.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/foundation.dart';

class CutomerListController extends BaseController {
  var customerList = <CustomerData>[].obs;
  final isLoading = false.obs;
  final loadError = ''.obs;
  final hasLoadedOnce = false.obs;

  Future<void> getCustomerList() async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      loadError.value = 'No outlet selected';
      customerList.clear();
      hasLoadedOnce.value = true;
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
        loadError.value = 'Unable to load customers. Please try again.';
        customerList.clear();
      }
    } catch (e) {
      debugPrint('Customer list error: $e');
      loadError.value = 'Unable to load customers. Please check your connection.';
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
