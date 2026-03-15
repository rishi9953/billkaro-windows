import 'package:billkaro/config/config.dart';

int _noOfCallRunning = 0;

void showAppLoader({bool isCancelable = false, double? loaderTopPadding}) {
  if (!(Get.isDialogOpen ?? false)) _noOfCallRunning = 0;
  _noOfCallRunning++;
  if (_noOfCallRunning == 1) _showLoadingDialog(isCancelable, loaderTopPadding);
}

void dismissAppLoader() {
  if (_noOfCallRunning == 1 &&
      Get.isDialogOpen == true &&
      Get.rawRoute?.settings.name == 'dialog_loading') {
    Get.back();
  }
  _noOfCallRunning--;
}

void dismissAllAppLoader() {
  debugPrint("dismissAllAppLoader: -> $_noOfCallRunning");
  if (_noOfCallRunning >= 1) {
    _noOfCallRunning--;
    dismissAllAppLoader();
  } else {
    if (_noOfCallRunning <= 0 &&
        Get.isDialogOpen == true &&
        Get.rawRoute?.settings.name == 'dialog_loading') {
      _noOfCallRunning = 0;
      Get.back();
      return;
    }
  }
}

void _showLoadingDialog(bool isCancelable, double? loaderTopPadding) {
  Get.dialog(
    PopScope(
      canPop: isCancelable,
      child: Builder(
        builder: (context) => Material(
          color: Colors.transparent.withOpacity(0.1),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            child: CircularProgressIndicator(color: AppColor.white),
          ),
        ),
      ),
    ),
    barrierDismissible: isCancelable,
    name: 'dialog_loading',
  );
}
