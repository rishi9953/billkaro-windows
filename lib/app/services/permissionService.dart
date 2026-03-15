import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._(); // private constructor

  static bool _isRequesting = false;

  /// --------------------------------------------------
  /// REQUEST ALL REQUIRED PERMISSIONS (SAFE)
  /// --------------------------------------------------
  static Future<bool> requestAllRequiredPermissions() async {
    if (_isRequesting) return false; // prevent duplicate calls
    _isRequesting = true;

    try {
      final List<Permission> permissions = [];

      // ---------- LOCATION ----------
      permissions.add(Permission.location);
      permissions.add(Permission.locationWhenInUse);

      // ---------- BLUETOOTH ----------
      if (Platform.isAndroid) {
        permissions.addAll([
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ]);
      }

      // ---------- STORAGE / FILES ----------
      if (Platform.isAndroid) {
        permissions.add(Permission.storage);
        permissions.add(Permission.manageExternalStorage);
      }

      // ---------- CAMERA ----------
      permissions.add(Permission.camera);

      // ---------- CONTACTS ----------
      permissions.add(Permission.contacts);

      // ---------- NOTIFICATIONS (Android 13+) ----------
      if (Platform.isAndroid) {
        permissions.add(Permission.notification);
      }

      final statuses = await permissions.request();

      return statuses.values.every((status) => status.isGranted);
    } finally {
      _isRequesting = false;
    }
  }

  /// --------------------------------------------------
  /// INDIVIDUAL PERMISSIONS (USE WHEN NEEDED)
  /// --------------------------------------------------

  static Future<bool> requestLocation() async {
    return await _safeRequest([
      Permission.location,
      Permission.locationWhenInUse,
    ]);
  }

  static Future<bool> requestBluetooth() async {
    if (!Platform.isAndroid) return true;

    return await _safeRequest([
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location, // required for Android <= 11
    ]);
  }

  static Future<bool> requestStorage() async {
    if (!Platform.isAndroid) return true;

    return await _safeRequest([
      Permission.storage,
      Permission.manageExternalStorage,
    ]);
  }

  static Future<bool> requestCamera() async {
    return await _safeRequest([Permission.camera]);
  }

  static Future<bool> requestContacts() async {
    return await _safeRequest([Permission.contacts]);
  }

  static Future<bool> requestNotification() async {
    if (!Platform.isAndroid) return true; // iOS handles this differently
    try {
      return await _safeRequest([Permission.notification]);
    } catch (e) {
      debugPrint('⚠️ [PermissionService] requestNotification error: $e');
      return false;
    }
  }

  /// --------------------------------------------------
  /// SAFE REQUEST (NO PARALLEL CALLS)
  /// --------------------------------------------------
  static Future<bool> _safeRequest(List<Permission> permissions) async {
    if (_isRequesting) return false;
    _isRequesting = true;

    try {
      final statuses = await permissions.request();
      return statuses.values.every((status) => status.isGranted);
    } finally {
      _isRequesting = false;
    }
  }

  /// --------------------------------------------------
  /// APP SETTINGS
  /// --------------------------------------------------
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// --------------------------------------------------
  /// CHECK PERMISSION STATUS
  /// --------------------------------------------------
  static Future<bool> hasPermission(Permission permission) async {
    return await permission.isGranted;
  }
}
