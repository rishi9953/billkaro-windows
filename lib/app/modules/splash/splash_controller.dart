import 'package:billkaro/config/config.dart';

class SplashController extends BaseController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;

  @override
  void onInit() {
    super.onInit();

    // Initialize animation controller
    animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeIn),
    );

    // Start animation
    animationController.forward();

    // Navigate to home screen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _gotoNextScreen();
    });
  }

  void _gotoNextScreen() {
    // Get.offAllNamed(AppRoute.main);
    debugPrint(appPref.isLogin.toString());
    if (appPref.isLogin) {
      Get.offAllNamed(AppRoute.homeMain);
    } else {
      Get.offAllNamed(AppRoute.main);
    }
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
