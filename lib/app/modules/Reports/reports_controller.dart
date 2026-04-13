import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ReportsController extends BaseController {
  void navigateToOrderReports() {
    // Get.toNamed(AppRoute.orderReports);
    Modular.to.pushNamed(HomeMainRoutes.orderReport);
  }

  void navigateToItemReports() {
    Modular.to.pushNamed(HomeMainRoutes.itemsReport);
  }
}
