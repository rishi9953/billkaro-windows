import 'package:billkaro/config/config.dart';

int _noOfCallRunning = 0;
bool _isLoaderDialogVisible = false;

void showAppLoader({bool isCancelable = false, double? loaderTopPadding}) {
  if (!(Get.isDialogOpen ?? false) && !_isLoaderDialogVisible) {
    _noOfCallRunning = 0;
  }
  _noOfCallRunning++;
  if (_noOfCallRunning == 1 && !_isLoaderDialogVisible) {
    _showLoadingDialog(isCancelable, loaderTopPadding);
  }
}

void dismissAppLoader() {
  if (_noOfCallRunning <= 0) {
    _noOfCallRunning = 0;
    _closeLoadingDialogIfVisible();
    return;
  }

  _noOfCallRunning--;
  if (_noOfCallRunning == 0) {
    _closeLoadingDialogIfVisible();
  }
}

void dismissAllAppLoader() {
  _noOfCallRunning = 0;
  _closeLoadingDialogIfVisible();
}

void _closeLoadingDialogIfVisible() {
  if (_isLoaderDialogVisible && (Get.isDialogOpen ?? false)) {
    Get.back();
    return;
  }

  // Fallback if dialog state is out of sync.
  if (Get.isDialogOpen == true &&
      Get.rawRoute?.settings.name == 'dialog_loading') {
    Get.back();
  }
}

void _showLoadingDialog(bool isCancelable, double? loaderTopPadding) {
  _isLoaderDialogVisible = true;
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
  ).whenComplete(() {
    _isLoaderDialogVisible = false;
    if (_noOfCallRunning < 0) _noOfCallRunning = 0;
  });
}
