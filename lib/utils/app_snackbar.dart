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

  static SnackbarController showConnectivity({
    required String title,
    required String message,
    required String badge,
    required bool isOnline,
  }) {
    if (Get.isSnackbarOpen == true) Get.closeAllSnackbars();

    return Get.rawSnackbar(
      backgroundColor: Colors.transparent,
      snackPosition: SnackPosition.TOP,
      snackStyle: SnackStyle.FLOATING,
      duration: const Duration(seconds: 4),
      margin: _resolveMargin(snackPosition: SnackPosition.TOP),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 16,
      animationDuration: const Duration(milliseconds: 450),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      messageText: _ConnectivityToastCard(
        title: title,
        message: message,
        badge: badge,
        isOnline: isOnline,
      ),
    );
  }
}

class _ConnectivityToastCard extends StatelessWidget {
  const _ConnectivityToastCard({
    required this.title,
    required this.message,
    required this.badge,
    required this.isOnline,
  });

  final String title;
  final String message;
  final String badge;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final accent = isOnline ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final surface = isOnline ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final border = isOnline ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA);
    final iconBg = isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final icon = isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: iconBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: accent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
