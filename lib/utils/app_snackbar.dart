import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  AppSnackbar._();

  static const double _desktopSidebarSafeLeft = 248;
  static const EdgeInsets _defaultMargin = EdgeInsets.all(16);

  static bool get _isWindowsDesktop => !kIsWeb && Platform.isWindows;

  static EdgeInsets _resolveMargin({SnackPosition? snackPosition}) {
    if (!_isWindowsDesktop) return _defaultMargin;
    return const EdgeInsets.fromLTRB(_desktopSidebarSafeLeft, 16, 16, 16);
  }

  static SnackStyle _resolveSnackStyle(SnackStyle? snackStyle) {
    if (snackStyle != null) return snackStyle;
    return _isWindowsDesktop ? SnackStyle.FLOATING : SnackStyle.GROUNDED;
  }

  static SnackbarController show({
    required String title,
    required String message,
    SnackPosition snackPosition = SnackPosition.BOTTOM,
    Color? backgroundColor,
    Color? colorText,
    Widget? icon,
    Duration? duration,
    SnackStyle? snackStyle,
    EdgeInsets? margin,
  }) {
    return Get.snackbar(
      title,
      message,
      snackPosition: snackPosition,
      backgroundColor: backgroundColor,
      colorText: colorText,
      icon: icon,
      duration: duration,
      margin: margin ?? _resolveMargin(snackPosition: snackPosition),
      snackStyle: _resolveSnackStyle(snackStyle),
    );
  }

  static SnackbarController showRaw({
    required Color backgroundColor,
    Widget? titleText,
    Widget? messageText,
    Widget? icon,
    SnackPosition snackPosition = SnackPosition.BOTTOM,
    Duration duration = const Duration(milliseconds: 3000),
    EdgeInsets? padding,
    SnackStyle? snackStyle,
  }) {
    return Get.rawSnackbar(
      backgroundColor: backgroundColor,
      titleText: titleText,
      messageText: messageText,
      icon: icon,
      padding: padding ?? const EdgeInsets.all(20),
      snackPosition: snackPosition,
      duration: duration,
      margin: _resolveMargin(snackPosition: snackPosition),
      snackStyle: _resolveSnackStyle(snackStyle),
    );
  }
}
