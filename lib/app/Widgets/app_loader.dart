import 'dart:io';

import 'package:billkaro/app/Widgets/windows_desktop_title_bar.dart';
import 'package:billkaro/config/config.dart';

int _noOfCallRunning = 0;
bool _isLoaderDialogVisible = false;
OverlayEntry? _loaderOverlayEntry;

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
  if (!_isLoaderDialogVisible) return;

  if (_loaderOverlayEntry != null) {
    _loaderOverlayEntry!.remove();
    _loaderOverlayEntry = null;
    _isLoaderDialogVisible = false;
    if (_noOfCallRunning < 0) _noOfCallRunning = 0;
    return;
  }

  final context = Get.overlayContext;
  if (context == null) return;

  final navigator = Navigator.of(context, rootNavigator: true);
  final route = ModalRoute.of(context);
  final isLoadingRoute = route?.settings.name == 'dialog_loading';
  if (navigator.canPop() || isLoadingRoute) {
    navigator.pop();
  }
}

double _effectiveLoaderTopPadding(double? loaderTopPadding) {
  if (loaderTopPadding != null) return loaderTopPadding;
  if (!kIsWeb && Platform.isWindows) return kWindowsDesktopTitleBarHeight;
  return 0;
}

Color _loaderColor(BuildContext context) =>
    Theme.of(context).colorScheme.primary;

void _showLoadingDialog(bool isCancelable, double? loaderTopPadding) {
  _isLoaderDialogVisible = true;
  final topPadding = _effectiveLoaderTopPadding(loaderTopPadding);

  if (topPadding > 0) {
    _showLoadingOverlay(topPadding, isCancelable);
    return;
  }

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
            child: CircularProgressIndicator(color: _loaderColor(context)),
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

void _showLoadingOverlay(double topPadding, bool isCancelable) {
  final context = Get.overlayContext;
  if (context == null) {
    _isLoaderDialogVisible = false;
    return;
  }

  _loaderOverlayEntry = OverlayEntry(
    builder: (context) => PopScope(
      canPop: isCancelable,
      child: Stack(
        children: [
          Positioned(
            top: topPadding,
            left: 0,
            right: 0,
            bottom: 0,
            child: ModalBarrier(
              color: Colors.black.withOpacity(0.1),
              dismissible: isCancelable,
              onDismiss: isCancelable ? dismissAllAppLoader : null,
            ),
          ),
          Positioned(
            top: topPadding,
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: CircularProgressIndicator(color: _loaderColor(context)),
            ),
          ),
        ],
      ),
    ),
  );

  Overlay.of(context, rootOverlay: true).insert(_loaderOverlayEntry!);
}
