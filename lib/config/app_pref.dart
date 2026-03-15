// ignore_for_file: unnecessary_null_comparison
import 'dart:convert';

import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPref {
  final SharedPreferences _preferences;
  static String keyUsers = 'saved_users';
  static const String keyCurrentUser = 'current_user';
  static const String keyToken = 'token';
  static const String keyUser = 'user';
  static const String keySelectedOutlet = 'selected_outlet';
  static const String prefixUserPassword = 'user_password_';
  static const String keyRecentusers = 'recent_users';
  static const String keyIsKOT = 'is_kot';
  static const String keyShowcaseCompleted = 'showcase_completed';
  static const String keyIsListView = 'is_list_view';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyHapticEnabled = 'haptic_enabled';
  static const String keyShowQrOnBill = 'show_qr_on_bill';

  AppPref(this._preferences);

  /// Login
  bool get isLogin => token.isNotEmpty;

  String get token => _preferences.getString('token') ?? '';
  set token(String value) => _preferences.setString('token', value);

  User? get user => _preferences.containsKey('user') ? User.fromJson(jsonDecode(_preferences.getString('user') ?? '')) : null;

  set user(User? value) => _preferences.setString('user', jsonEncode(value));

  /// 👉 Selected Outlet
  OutletData? get selectedOutlet {
    if (!_preferences.containsKey(keySelectedOutlet)) return null;
    try {
      return OutletData.fromJson(jsonDecode(_preferences.getString(keySelectedOutlet) ?? ''));
    } catch (e) {
      return null;
    }
  }

  set selectedOutlet(OutletData? value) {
    if (value == null) {
      _preferences.remove(keySelectedOutlet);
    } else {
      _preferences.setString(keySelectedOutlet, jsonEncode(value.toJson()));
    }
  }

  /// Get all outlets from user
  List<OutletData> get allOutlets => user?.outletData ?? [];

  /// Check if outlet is selected
  bool get hasSelectedOutlet => selectedOutlet != null;

  /// Select outlet by ID
  bool selectOutletById(String outletId) {
    final outlets = allOutlets;
    try {
      final outlet = outlets.firstWhere((o) => o.id == outletId);
      selectedOutlet = outlet;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Select first outlet (useful for auto-selection)
  bool selectFirstOutlet() {
    final outlets = allOutlets;
    if (outlets.isEmpty) return false;
    selectedOutlet = outlets.first;
    return true;
  }

  bool selectLastOutlet() {
    final outlets = allOutlets;
    if (outlets.isEmpty) return false;
    selectedOutlet = outlets.last;
    return true;
  }

  /// Clear selected outlet
  void clearSelectedOutlet() {
    selectedOutlet = null;
  }

  /// 👉 KOT flag
  bool get isKOT => _preferences.getBool(keyIsKOT) ?? false;
  set isKOT(bool value) => _preferences.setBool(keyIsKOT, value);

  /// 👉 Billing View preference (true = List View, false = Image View)
  bool get isListView => _preferences.getBool(keyIsListView) ?? false;
  set isListView(bool value) => _preferences.setBool(keyIsListView, value);

  /// 👉 Showcase completion flag
  bool get isShowcaseCompleted => _preferences.getBool(keyShowcaseCompleted) ?? false;
  set isShowcaseCompleted(bool value) => _preferences.setBool(keyShowcaseCompleted, value);

  /// 👉 Notifications enabled
  bool get notificationsEnabled => _preferences.getBool(keyNotificationsEnabled) ?? true;
  set notificationsEnabled(bool value) => _preferences.setBool(keyNotificationsEnabled, value);

  /// 👉 Sound enabled
  bool get soundEnabled => _preferences.getBool(keySoundEnabled) ?? true;
  set soundEnabled(bool value) => _preferences.setBool(keySoundEnabled, value);

  /// 👉 Haptic feedback enabled
  bool get hapticEnabled => _preferences.getBool(keyHapticEnabled) ?? true;
  set hapticEnabled(bool value) => _preferences.setBool(keyHapticEnabled, value);

  /// 👉 Show QR code on bill/invoice (UPI scan to pay)
  bool get showQrOnBill => _preferences.getBool(keyShowQrOnBill) ?? true;
  set showQrOnBill(bool value) => _preferences.setBool(keyShowQrOnBill, value);

  /// Clear all
  Future<bool> clear() async => await _preferences.clear();

  /// Clear only auth data
  Future<bool> clearAuthData() async {
    await _preferences.remove(keyToken);
    await _preferences.remove(keyUser);
    await _preferences.remove(keyCurrentUser);
    await _preferences.remove(keySelectedOutlet);
    await _preferences.remove(keyIsKOT);
    await _preferences.remove(keyShowcaseCompleted); // Reset showcase on logout
    // Keeping saved users & recent users
    return true;
  }

  /// Clear all data including saved users (complete logout)
  Future<bool> clearAllData() async {
    await clearAuthData();
    await _preferences.remove(keyUsers);
    await _preferences.remove(keyRecentusers);
    return true;
  }
}
