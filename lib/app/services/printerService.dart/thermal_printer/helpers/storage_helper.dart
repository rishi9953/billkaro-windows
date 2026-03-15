import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class StorageHelper {
  // Role keys
  // We keep the legacy single-printer keys for backward compatibility.
  static const String _roleBill = 'bill';
  static const String _roleKot = 'kot';

  // Bluetooth device keys
  static const String _deviceIdKey = 'last_printer_device_id';
  static const String _deviceNameKey = 'last_printer_device_name';
  static const String _autoConnectKey = 'auto_connect_enabled';

  // USB printer keys
  static const String _usbPrinterNameKey = 'last_usb_printer_name';
  static const String _usbPrinterVendorIdKey = 'last_usb_printer_vendor_id';
  static const String _usbPrinterProductIdKey = 'last_usb_printer_product_id';
  static const String _printerTypeKey =
      'last_printer_type'; // 'bluetooth' or 'usb'

  // Role-based keys (Bill / KOT)
  static String _rolePrinterTypeKey(String role) => '${role}_printer_type';
  static String _roleBtDeviceIdKey(String role) => '${role}_printer_device_id';
  static String _roleBtDeviceNameKey(String role) =>
      '${role}_printer_device_name';
  static String _roleUsbPrinterNameKey(String role) =>
      '${role}_usb_printer_name';
  static String _roleUsbPrinterVendorIdKey(String role) =>
      '${role}_usb_printer_vendor_id';
  static String _roleUsbPrinterProductIdKey(String role) =>
      '${role}_usb_printer_product_id';

  // Bluetooth Device Methods
  static Future<void> saveDevice(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceIdKey, device.remoteId.toString());
    await prefs.setString(_deviceNameKey, device.platformName);
    await prefs.setString(_printerTypeKey, 'bluetooth');
  }

  /// Save printer for a specific role ('bill' / 'kot')
  static Future<void> saveRoleBluetoothDevice(
    String role,
    BluetoothDevice device,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleBtDeviceIdKey(role), device.remoteId.toString());
    await prefs.setString(_roleBtDeviceNameKey(role), device.platformName);
    await prefs.setString(_rolePrinterTypeKey(role), 'bluetooth');
  }

  static Future<String?> getSavedDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceIdKey);
  }

  static Future<String?> getSavedDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceNameKey);
  }

  static Future<String?> getRoleSavedDeviceId(String role) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleBtDeviceIdKey(role));
  }

  static Future<String?> getRoleSavedDeviceName(String role) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleBtDeviceNameKey(role));
  }

  // USB Printer Methods
  static Future<void> saveUsbPrinter(
    String printerName, {
    int? vendorId,
    int? productId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usbPrinterNameKey, printerName);
    await prefs.setString(_printerTypeKey, 'usb');

    if (vendorId != null) {
      await prefs.setInt(_usbPrinterVendorIdKey, vendorId);
    }
    if (productId != null) {
      await prefs.setInt(_usbPrinterProductIdKey, productId);
    }
  }

  static Future<void> saveRoleUsbPrinter(
    String role,
    String printerName, {
    int? vendorId,
    int? productId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleUsbPrinterNameKey(role), printerName);
    await prefs.setString(_rolePrinterTypeKey(role), 'usb');

    if (vendorId != null) {
      await prefs.setInt(_roleUsbPrinterVendorIdKey(role), vendorId);
    }
    if (productId != null) {
      await prefs.setInt(_roleUsbPrinterProductIdKey(role), productId);
    }
  }

  static Future<String?> getSavedUsbPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usbPrinterNameKey);
  }

  static Future<String?> getRoleSavedUsbPrinter(String role) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleUsbPrinterNameKey(role));
  }

  static Future<int?> getRoleSavedUsbVendorId(String role) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_roleUsbPrinterVendorIdKey(role));
  }

  static Future<int?> getRoleSavedUsbProductId(String role) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_roleUsbPrinterProductIdKey(role));
  }

  static Future<int?> getSavedUsbVendorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_usbPrinterVendorIdKey);
  }

  static Future<int?> getSavedUsbProductId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_usbPrinterProductIdKey);
  }

  // Get last used printer type
  static Future<String?> getLastPrinterType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_printerTypeKey);
  }

  static Future<String?> getRoleLastPrinterType(String role) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rolePrinterTypeKey(role));
  }

  // Auto-connect Methods
  static Future<void> setAutoConnect(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoConnectKey, enabled);
  }

  static Future<bool> isAutoConnectEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoConnectKey) ?? false;
  }

  // Clear Methods
  static Future<void> clearBluetoothDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    await prefs.remove(_deviceNameKey);
  }

  static Future<void> clearUsbPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usbPrinterNameKey);
    await prefs.remove(_usbPrinterVendorIdKey);
    await prefs.remove(_usbPrinterProductIdKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear Bluetooth
    await prefs.remove(_deviceIdKey);
    await prefs.remove(_deviceNameKey);
    // Clear USB
    await prefs.remove(_usbPrinterNameKey);
    await prefs.remove(_usbPrinterVendorIdKey);
    await prefs.remove(_usbPrinterProductIdKey);
    // Clear common
    await prefs.remove(_autoConnectKey);
    await prefs.remove(_printerTypeKey);

    // Clear role-based printers
    for (final role in [_roleBill, _roleKot]) {
      await prefs.remove(_rolePrinterTypeKey(role));
      await prefs.remove(_roleBtDeviceIdKey(role));
      await prefs.remove(_roleBtDeviceNameKey(role));
      await prefs.remove(_roleUsbPrinterNameKey(role));
      await prefs.remove(_roleUsbPrinterVendorIdKey(role));
      await prefs.remove(_roleUsbPrinterProductIdKey(role));
    }
  }

  static Future<void> clearRolePrinter(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rolePrinterTypeKey(role));
    await prefs.remove(_roleBtDeviceIdKey(role));
    await prefs.remove(_roleBtDeviceNameKey(role));
    await prefs.remove(_roleUsbPrinterNameKey(role));
    await prefs.remove(_roleUsbPrinterVendorIdKey(role));
    await prefs.remove(_roleUsbPrinterProductIdKey(role));
  }

  // Check if any printer is saved
  static Future<bool> hasSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final hasBluetoothDevice = prefs.getString(_deviceIdKey) != null;
    final hasUsbPrinter = prefs.getString(_usbPrinterNameKey) != null;
    return hasBluetoothDevice || hasUsbPrinter;
  }

  // Get saved printer info for display
  static Future<Map<String, dynamic>> getSavedPrinterInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final printerType = prefs.getString(_printerTypeKey);

    if (printerType == 'bluetooth') {
      return {
        'type': 'bluetooth',
        'name': prefs.getString(_deviceNameKey),
        'id': prefs.getString(_deviceIdKey),
      };
    } else if (printerType == 'usb') {
      return {
        'type': 'usb',
        'name': prefs.getString(_usbPrinterNameKey),
        'vendorId': prefs.getInt(_usbPrinterVendorIdKey),
        'productId': prefs.getInt(_usbPrinterProductIdKey),
      };
    }

    return {'type': null};
  }

  static Future<Map<String, dynamic>> getRoleSavedPrinterInfo(
    String role,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final printerType = prefs.getString(_rolePrinterTypeKey(role));

    if (printerType == 'bluetooth') {
      return {
        'type': 'bluetooth',
        'name': prefs.getString(_roleBtDeviceNameKey(role)),
        'id': prefs.getString(_roleBtDeviceIdKey(role)),
      };
    } else if (printerType == 'usb') {
      return {
        'type': 'usb',
        'name': prefs.getString(_roleUsbPrinterNameKey(role)),
        'vendorId': prefs.getInt(_roleUsbPrinterVendorIdKey(role)),
        'productId': prefs.getInt(_roleUsbPrinterProductIdKey(role)),
      };
    }

    return {'type': null};
  }
}
