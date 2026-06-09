import 'dart:async';

import 'package:billkaro/app/services/Modals/kds/kds_order_placed_event.dart';
import 'package:billkaro/app/services/kds/kds_realtime_service.dart';
import 'package:billkaro/app/services/notification/kitchen_new_order_notification_service.dart';
import 'package:billkaro/config/app_pref.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Listens for new order events over WebSocket and notifies the POS device.
class KitchenNewOrderMonitor {
  KitchenNewOrderMonitor._();
  static final KitchenNewOrderMonitor instance = KitchenNewOrderMonitor._();

  StreamSubscription<KdsOrderPlacedEvent>? _orderSub;
  final Set<String> _notifiedKeys = {};

  AppPref? get _pref {
    if (!Get.isRegistered<AppPref>()) return null;
    return Get.find<AppPref>();
  }

  void start() {
    if (_orderSub != null) return;
    _loadNotifiedKeys();
    _orderSub =
        KdsRealtimeService.instance.orderPlacedStream.listen(_onOrderPlaced);
    _connectForCurrentOutlet();
    debugPrint('✅ [NEW ORDER] Monitor started (WebSocket)');
  }

  void stop() {
    _orderSub?.cancel();
    _orderSub = null;
  }

  void onOutletChanged() {
    final pref = _pref;
    if (pref == null) return;
    _notifiedKeys.clear();
    pref.clearKitchenNewOrderNotifiedKeys();
    _connectForCurrentOutlet();
  }

  void _connectForCurrentOutlet() {
    final pref = _pref;
    if (pref == null || !pref.isLogin || !pref.notificationsEnabled) return;
    final outletId = pref.selectedOutlet?.id;
    if (outletId == null) return;
    KdsRealtimeService.instance.connect(outletId);
  }

  Future<void> _onOrderPlaced(KdsOrderPlacedEvent event) async {
    final pref = _pref;
    if (pref == null || !pref.notificationsEnabled) return;

    final outletId = pref.selectedOutlet?.id;
    if (outletId == null || event.outletId != outletId) return;

    final key = event.dedupeKey;
    if (_notifiedKeys.contains(key)) return;

    await KitchenNewOrderNotificationService.instance.notifyOrderPlaced(event);
    _notifiedKeys.add(key);
    _trimNotifiedKeys();
    _persistNotifiedKeys(pref);
  }

  void _loadNotifiedKeys() {
    final pref = _pref;
    if (pref == null) return;
    final raw = pref.kitchenNewOrderNotifiedKeys;
    if (raw.isEmpty) return;
    for (final part in raw.split('|')) {
      if (part.isNotEmpty) _notifiedKeys.add(part);
    }
  }

  void _persistNotifiedKeys(AppPref pref) {
    if (_notifiedKeys.isEmpty) return;
    pref.kitchenNewOrderNotifiedKeys = _notifiedKeys.join('|');
  }

  void _trimNotifiedKeys() {
    if (_notifiedKeys.length <= 200) return;
    final list = _notifiedKeys.toList();
    _notifiedKeys
      ..clear()
      ..addAll(list.sublist(list.length - 150));
  }
}
