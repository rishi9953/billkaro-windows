import 'dart:async';

import 'package:billkaro/config/config.dart';

VoidCallback? activePoDrawerCloser;
VoidCallback? activePoDrawerOverlayRefresh;
GlobalKey<NavigatorState>? activePoDrawerNavigatorKey;
String? activePoDrawerTabId;
String? visiblePoDrawerTabId;

void closeActivePoDrawer() {
  activePoDrawerCloser?.call();
}

bool isPoDrawerOpen() => activePoDrawerCloser != null;

OverlayState? resolveRootOverlay() {
  final overlayCtx = Get.overlayContext;
  if (overlayCtx != null) {
    final overlay = Overlay.maybeOf(overlayCtx, rootOverlay: true);
    if (overlay != null) return overlay;
  }
  final currentCtx = Get.context;
  if (currentCtx != null) {
    return Navigator.of(currentCtx, rootNavigator: true).overlay;
  }
  return null;
}

void dismissPoDrawerDropdowns() {
  activePoDrawerNavigatorKey?.currentState?.popUntil((route) => route.isFirst);
}

Future<T?> showPoAwareDialog<T>({
  required Widget Function(BuildContext context, void Function([T? result]) close)
  builder,
}) async {
  dismissPoDrawerDropdowns();

  final overlay = resolveRootOverlay();
  final fallbackContext = Get.overlayContext ?? Get.context;
  if (overlay == null && fallbackContext != null) {
    return showDialog<T>(
      context: fallbackContext,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => builder(context, ([value]) {
        Navigator.of(context).pop(value);
      }),
    );
  }
  if (overlay == null) return null;

  final completer = Completer<T?>();
  late OverlayEntry entry;

  void close([T? value]) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (dialogContext) {
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ModalBarrier(dismissible: false, color: Colors.black54),
            Center(
              child: builder(dialogContext, close),
            ),
          ],
        ),
      );
    },
  );

  overlay.insert(entry);
  return completer.future;
}

bool shouldConfirmLeavePurchaseOrders() => true;

Future<bool> confirmLeavePurchaseOrdersScreen(
  BuildContext context,
  AppLocalizations loc,
) async {
  if (!shouldConfirmLeavePurchaseOrders()) return true;

  final shouldLeave = await showPoAwareDialog<bool>(
    builder: (dialogContext, close) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        constraints: const BoxConstraints(maxWidth: 360),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text('Leave ${loc.tab_purchase_orders}?'),
        content: const Text(
          'Are you sure you want to leave this screen?',
        ),
        actions: [
          TextButton(
            onPressed: () => close(false),
            child: Text(loc.stay),
          ),
          ElevatedButton(
            onPressed: () => close(true),
            child: Text(loc.leave),
          ),
        ],
      );
    },
  );

  if (shouldLeave == true) {
    closeActivePoDrawer();
  }

  return shouldLeave ?? false;
}

void setVisiblePoDrawerTab(String tabId) {
  if (activePoDrawerTabId != null &&
      visiblePoDrawerTabId == activePoDrawerTabId &&
      tabId != activePoDrawerTabId) {
    dismissPoDrawerDropdowns();
  }
  visiblePoDrawerTabId = tabId;
  activePoDrawerOverlayRefresh?.call();
}

bool isPoDrawerOwnedByTab(String tabId) => activePoDrawerTabId == tabId;
