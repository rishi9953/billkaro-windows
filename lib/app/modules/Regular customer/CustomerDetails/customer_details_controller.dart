import 'package:billkaro/app/services/Modals/customer/customerResponse.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

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
    final dynamic rawArgs = Get.arguments ?? Modular.args.data;
    if (rawArgs is CustomerData) {
      customer = rawArgs;
      customerName.value = rawArgs.customerName;
      phoneNumber.value = rawArgs.phoneNumber;
      loyaltyDiscount.value = double.tryParse(rawArgs.loyalityDiscount.toString()) ?? 0.0;
    } else if (rawArgs != null) {
      // Leave fields as default, but keep a breadcrumb for debugging.
      debugPrint(
        '[CustomerDetailsController] Unexpected args type: ${rawArgs.runtimeType}',
      );
    }
    super.onInit();
  }
}
