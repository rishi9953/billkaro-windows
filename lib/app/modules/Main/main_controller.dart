import 'package:billkaro/app/routes/app_routes.dart';
import 'package:get/get.dart';

class MainController extends GetxController {
  void onRegister() {
    Get.toNamed(AppRoute.register);
  }

  void onAlreadyRegistered() {
    Get.toNamed(AppRoute.login);
  }
}
