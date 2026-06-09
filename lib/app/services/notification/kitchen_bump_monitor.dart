import 'dart:async';

import 'package:billkaro/app/services/Modals/kds/kds_bump_events_response.dart';
import 'package:billkaro/app/services/kds/kds_realtime_service.dart';
import 'package:billkaro/app/services/notification/kitchen_bump_notification_service.dart';
import 'package:billkaro/config/app_pref.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Listens for KDS bump events over WebSocket and notifies the owner POS.
class KitchenBumpMonitor {
  KitchenBumpMonitor._();
  static final KitchenBumpMonitor instance = KitchenBumpMonitor._();

  StreamSubscription<KdsBumpEvent>? _bumpSub;
  final Set<String> _notifiedKeys = {};

  AppPref? get _pref {
    if (!Get.isRegistered<AppPref>()) return null;
    return Get.find<AppPref>();
  }

  void start() {
    if (_bumpSub != null) return;
    _loadNotifiedKeys();
    _bumpSub = KdsRealtimeService.instance.bumpStream.listen(_onBump);
    _connectForCurrentOutlet();
    debugPrint('✅ [KITCHEN BUMP] Owner monitor started (WebSocket)');
  }

  void stop() {
    _bumpSub?.cancel();
    _bumpSub = null;
  }

  void onOutletChanged() {
    final pref = _pref;
    if (pref == null) return;
    _notifiedKeys.clear();
    pref.clearKitchenBumpNotifiedKeys();
    _connectForCurrentOutlet();
  }

  void _connectForCurrentOutlet() {
    final pref = _pref;
    if (pref == null || !pref.isLogin || !pref.notificationsEnabled) return;
    final outletId = pref.selectedOutlet?.id;
    if (outletId == null) return;
    KdsRealtimeService.instance.connect(outletId);
  }

  Future<void> _onBump(KdsBumpEvent event) async {
    final pref = _pref;
    if (pref == null || !pref.notificationsEnabled) return;

    final outletId = pref.selectedOutlet?.id;
    if (outletId == null || event.outletId != outletId) return;

    final key = event.dedupeKey;
    if (_notifiedKeys.contains(key)) return;

    await KitchenBumpNotificationService.instance.notifyBump(event);
    _notifiedKeys.add(key);
    _trimNotifiedKeys();
    _persistNotifiedKeys(pref);
  }

  void _loadNotifiedKeys() {
    final pref = _pref;
    if (pref == null) return;
    final raw = pref.kitchenBumpNotifiedKeys;
    if (raw.isEmpty) return;
    for (final part in raw.split('|')) {
      if (part.isNotEmpty) _notifiedKeys.add(part);
    }
  }

  void _persistNotifiedKeys(AppPref pref) {
    if (_notifiedKeys.isEmpty) return;
    pref.kitchenBumpNotifiedKeys = _notifiedKeys.join('|');
  }

  void _trimNotifiedKeys() {
    if (_notifiedKeys.length <= 200) return;
    final list = _notifiedKeys.toList();
    _notifiedKeys
      ..clear()
      ..addAll(list.sublist(list.length - 150));
  }
}
