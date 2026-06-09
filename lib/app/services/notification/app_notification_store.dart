import 'dart:convert';

import 'package:billkaro/app/services/notification/app_notification_item.dart';
import 'package:billkaro/config/app_pref.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// In-app notification inbox (persisted locally).
class AppNotificationStore extends GetxService {
  static AppNotificationStore get to => Get.find<AppNotificationStore>();

  static const int _maxItems = 100;

  final RxList<AppNotificationItem> items = <AppNotificationItem>[].obs;

  int get unreadCount => items.where((e) => !e.read).length;

  Future<AppNotificationStore> init() async {
    await load();
    return this;
  }

  Future<void> load() async {
    if (!Get.isRegistered<AppPref>()) return;
    final pref = Get.find<AppPref>();
    final raw = pref.appNotificationsJson;
    if (raw.isEmpty) {
      items.clear();
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      items.assignAll(
        list
            .whereType<Map>()
            .map((e) => AppNotificationItem.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList(),
      );
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION STORE] load failed: $e');
      items.clear();
    }
  }

  Future<void> add(AppNotificationItem item) async {
    if (items.any((e) => e.id == item.id)) return;
    items.insert(0, item);
    while (items.length > _maxItems) {
      items.removeLast();
    }
    await _persist();
  }

  Future<void> markRead(String id) async {
    final i = items.indexWhere((e) => e.id == id);
    if (i < 0 || items[i].read) return;
    items[i] = items[i].copyWith(read: true);
    items.refresh();
    await _persist();
  }

  Future<void> markAllRead() async {
    var changed = false;
    for (var i = 0; i < items.length; i++) {
      if (!items[i].read) {
        items[i] = items[i].copyWith(read: true);
        changed = true;
      }
    }
    if (changed) {
      items.refresh();
      await _persist();
    }
  }

  Future<void> clearAll() async {
    items.clear();
    await _persist();
  }

  Future<void> _persist() async {
    if (!Get.isRegistered<AppPref>()) return;
    final pref = Get.find<AppPref>();
    pref.appNotificationsJson =
        jsonEncode(items.map((e) => e.toJson()).toList());
  }
}
