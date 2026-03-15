import 'package:billkaro/config/config.dart';

class ReportsController extends BaseController {
  void navigateToOrderReports() {
    Get.toNamed(AppRoute.orderReports);
  }

  void navigateToItemReports() {
    Get.toNamed(AppRoute.itemReports);
  }
}
