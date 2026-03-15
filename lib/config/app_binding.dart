import 'package:billkaro/app/Database/app_database.dart' as dbs;
import 'package:get/get.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Only register AppDatabase if not already registered
    if (!Get.isRegistered<dbs.AppDatabase>()) {
      Get.put<dbs.AppDatabase>(dbs.AppDatabase(), permanent: true);
    }
  }
}
