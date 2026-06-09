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
  static const String keyKitchenBumpLastSince = 'kitchen_bump_last_since_iso';
  static const String keyKitchenBumpNotifiedKeys = 'kitchen_bump_notified_keys';
  static const String keyKitchenNewOrderNotifiedKeys =
      'kitchen_new_order_notified_keys';
  static const String keyAppNotificationsJson = 'app_notifications_json';
  static const String keyShowQrOnBill = 'show_qr_on_bill';
  static const String keyShowAddDetailsOnCreateOrder =
      'show_add_details_on_create_order';
  static const String keyDownloadPath = 'download_path';
  static const String keyQrMenuBaseUrl = 'qr_menu_base_url';

  /// True when the user signed in via the staff tab (`auth/staff/login`).
  static const String keyStaffSession = 'staff_session';
  static const String keyStaffPermissions = 'staff_permissions';

  AppPref(this._preferences);

  /// Login
  bool get isLogin => token.isNotEmpty;

  String get token => _preferences.getString('token') ?? '';
  set token(String value) => _preferences.setString('token', value);

  User? get user => _preferences.containsKey(keyUser)
      ? User.fromJson(
          jsonDecode(_preferences.getString(keyUser) ?? '')
              as Map<String, dynamic>,
        )
      : null;

  set user(User? value) {
    if (value == null) {
      _preferences.remove(keyUser);
    } else {
      _preferences.setString(keyUser, jsonEncode(value.toJson()));
    }
  }

  /// 👉 Selected Outlet
  OutletData? get selectedOutlet {
    if (!_preferences.containsKey(keySelectedOutlet)) return null;
    try {
      return OutletData.fromJson(
        jsonDecode(_preferences.getString(keySelectedOutlet) ?? ''),
      );
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
  bool get isShowcaseCompleted =>
      _preferences.getBool(keyShowcaseCompleted) ?? false;
  set isShowcaseCompleted(bool value) =>
      _preferences.setBool(keyShowcaseCompleted, value);

  /// 👉 Notifications enabled
  bool get notificationsEnabled =>
      _preferences.getBool(keyNotificationsEnabled) ?? true;
  set notificationsEnabled(bool value) =>
      _preferences.setBool(keyNotificationsEnabled, value);

  String get kitchenBumpLastSinceIso =>
      _preferences.getString(keyKitchenBumpLastSince) ?? '';
  set kitchenBumpLastSinceIso(String value) =>
      _preferences.setString(keyKitchenBumpLastSince, value);

  String get kitchenBumpNotifiedKeys =>
      _preferences.getString(keyKitchenBumpNotifiedKeys) ?? '';
  set kitchenBumpNotifiedKeys(String value) =>
      _preferences.setString(keyKitchenBumpNotifiedKeys, value);

  void clearKitchenBumpNotifiedKeys() =>
      _preferences.remove(keyKitchenBumpNotifiedKeys);

  String get kitchenNewOrderNotifiedKeys =>
      _preferences.getString(keyKitchenNewOrderNotifiedKeys) ?? '';
  set kitchenNewOrderNotifiedKeys(String value) =>
      _preferences.setString(keyKitchenNewOrderNotifiedKeys, value);

  void clearKitchenNewOrderNotifiedKeys() =>
      _preferences.remove(keyKitchenNewOrderNotifiedKeys);

  String get appNotificationsJson =>
      _preferences.getString(keyAppNotificationsJson) ?? '';
  set appNotificationsJson(String value) =>
      _preferences.setString(keyAppNotificationsJson, value);

  /// 👉 Show QR code on bill/invoice (UPI scan to pay)
  bool get showQrOnBill => _preferences.getBool(keyShowQrOnBill) ?? true;
  set showQrOnBill(bool value) => _preferences.setBool(keyShowQrOnBill, value);

  /// 👉 Show "Add Details" on create order (customer, table, discounts, etc.)
  bool get showAddDetailsOnCreateOrder =>
      _preferences.getBool(keyShowAddDetailsOnCreateOrder) ?? true;
  set showAddDetailsOnCreateOrder(bool value) =>
      _preferences.setBool(keyShowAddDetailsOnCreateOrder, value);

  /// 👉 Preferred download directory for saved files
  String get downloadPath => _preferences.getString(keyDownloadPath) ?? '';
  set downloadPath(String value) =>
      _preferences.setString(keyDownloadPath, value);

  /// 👉 Custom base URL for table QR menu (empty = use API URL from .env)
  String get qrMenuBaseUrl => _preferences.getString(keyQrMenuBaseUrl) ?? '';
  set qrMenuBaseUrl(String value) =>
      _preferences.setString(keyQrMenuBaseUrl, value.trim());

  /// 👉 Staff sign-in path (role from API may be missing or inconsistent).
  bool get isStaffSession => _preferences.getBool(keyStaffSession) ?? false;
  set isStaffSession(bool value) =>
      _preferences.setBool(keyStaffSession, value);

  List<String> get staffPermissions {
    final raw = _preferences.getString(keyStaffPermissions);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return const [];
  }

  set staffPermissions(List<String> value) {
    if (value.isEmpty) {
      _preferences.remove(keyStaffPermissions);
    } else {
      _preferences.setString(keyStaffPermissions, jsonEncode(value));
    }
  }

  /// Clear all
  Future<bool> clear() async => await _preferences.clear();

  /// Clear only auth data
  Future<bool> clearAuthData() async {
    await _preferences.remove(keyToken);
    await _preferences.remove(keyUser);
    await _preferences.remove(keyCurrentUser);
    await _preferences.remove(keySelectedOutlet);
    await _preferences.remove(keyIsKOT);
    await _preferences.remove(keyStaffSession);
    await _preferences.remove(keyStaffPermissions);
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
