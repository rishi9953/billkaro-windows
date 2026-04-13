import 'package:billkaro/app/services/Modals/customer/customerResponse.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/foundation.dart';

class CutomerListController extends BaseController {
  var customerList = <CustomerData>[].obs;

  Future<void> getCustomerList() async {
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) {
      debugPrint('⚠️ [CUSTOMER] No outlet selected');
      return;
    }

    final response = await callApi(
      apiClient.getRegularCustomer(outletId),
    );
    if (response!.status == 'success') {
      customerList.value = response.data;
    }
  }

  @override
  void onReady() {
    getCustomerList();
    super.onReady();
  }
}
