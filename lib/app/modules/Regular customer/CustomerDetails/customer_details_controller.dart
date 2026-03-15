import 'package:billkaro/app/services/Modals/customer/customerResponse.dart';
import 'package:billkaro/config/config.dart';

class CustomerDetailsController extends BaseController {
  final customerName = ''.obs;
  final phoneNumber = ''.obs;
  final loyaltyDiscount = 0.0.obs;
  final avgOrder = 0.0.obs;
  final totalDiscount = 0.0.obs;
  final totalVisits = 0.obs;
  final orderValue = 0.0.obs;
  final orderNumber = ''.obs;
  final orderDate = ''.obs;
  final orderTotal = 0.0.obs;
  final paymentType = ''.obs;
  CustomerData? customer;

  @override
  void onInit() {
    var args = Get.arguments;
    if (args != null) {
      var data = args as CustomerData;
      customer = data;
      customerName.value = data.customerName;
      phoneNumber.value = data.phoneNumber;
      loyaltyDiscount.value = double.parse(data.loyalityDiscount.toString());
    }
    super.onInit();
  }
}
