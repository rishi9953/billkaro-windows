import 'package:billkaro/app/services/printerService.dart/thermal_printer/helpers/storage_helper.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/utils/app_snackbar.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:get/get.dart';

/// Role printer settings for [PrinterScreen2] (no scan tabs — avoids TabController clash).
class PrinterScreen2Controller extends GetxController {
  final thermalPrinter = ThermalPrinterService.instance;

  final savedBillPrinterName = Rxn<String>();
  final savedKotPrinterName = Rxn<String>();
  final savedBillPrinterType = Rxn<String>();
  final savedKotPrinterType = Rxn<String>();
  final billRoleInfo = Rx<Map<String, dynamic>>({});
  final kotRoleInfo = Rx<Map<String, dynamic>>({});
  final isRoleActionLoading = false.obs;
  final networkFormTick = 0.obs;

  final ipController = TextEditingController();
  final portController = TextEditingController(text: '9100');

  @override
  void onInit() {
    super.onInit();
    loadRolePrinters();
    _loadLastNetworkSettings();
    unawaited(thermalPrinter.restoreNetworkConnectionStatus());
    void bumpNetworkForm() => networkFormTick.value++;
    ipController.addListener(bumpNetworkForm);
    portController.addListener(bumpNetworkForm);
  }

  @override
  void onClose() {
    ipController.dispose();
    portController.dispose();
    super.onClose();
  }

  Future<void> _loadLastNetworkSettings() async {
    final settings = await thermalPrinter.getLastNetworkSettings();
    final ip = settings['ip'];
    if (ip != null && ip.isNotEmpty) {
      ipController.text = ip;
    }
    final port = settings['port'];
    if (port != null && port.isNotEmpty) {
      portController.text = port;
    }
  }

  String? _typeLabel(String? type) {
    if (type == 'usb') return 'USB';
    if (type == 'bluetooth') return 'Bluetooth';
    if (type == 'network') return 'Ethernet';
    return null;
  }

  Future<void> loadRolePrinters() async {
    final billInfo = await StorageHelper.getRoleSavedPrinterInfo('bill');
    final kotInfo = await StorageHelper.getRoleSavedPrinterInfo('kot');
    billRoleInfo.value = billInfo;
    kotRoleInfo.value = kotInfo;
    savedBillPrinterName.value = (billInfo['name'] as String?)?.trim();
    savedKotPrinterName.value = (kotInfo['name'] as String?)?.trim();
    savedBillPrinterType.value = _typeLabel(billInfo['type'] as String?);
    savedKotPrinterType.value = _typeLabel(kotInfo['type'] as String?);
  }

  bool _matchesBleRole(Map<String, dynamic> info, BluetoothDevice device) {
    if (info['type'] != 'bluetooth') return false;
    final savedId = (info['id'] as String?)?.trim();
    if (savedId == null || savedId.isEmpty) return false;
    return savedId == device.remoteId.toString();
  }

  bool _matchesClassicBtRole(Map<String, dynamic> info, String address) {
    if (info['type'] != 'bluetooth') return false;
    final savedId = (info['id'] as String?)?.trim();
    if (savedId == null || savedId.isEmpty) return false;
    return savedId == address.trim();
  }

  bool _matchesUsbRole(Map<String, dynamic> info, Printer printer) {
    if (info['type'] != 'usb') return false;
    final savedAddr = (info['address'] as String?)?.trim() ?? '';
    final printerAddr = (printer.address ?? '').trim();
    if (savedAddr.isNotEmpty && printerAddr.isNotEmpty) {
      return savedAddr == printerAddr;
    }
    final savedVendor = info['vendorId'] as int?;
    final savedProduct = info['productId'] as int?;
    final pVendor = int.tryParse('${printer.vendorId ?? ''}');
    final pProduct = int.tryParse('${printer.productId ?? ''}');
    if (savedVendor != null &&
        savedProduct != null &&
        pVendor != null &&
        pProduct != null &&
        savedVendor == pVendor &&
        savedProduct == pProduct) {
      return true;
    }
    final savedName = (info['name'] as String?)?.trim() ?? '';
    final printerName = (printer.name ?? '').trim();
    return savedName.isNotEmpty &&
        printerName.isNotEmpty &&
        savedName == printerName;
  }

  bool isBillBleDevice(BluetoothDevice device) =>
      _matchesBleRole(billRoleInfo.value, device);

  bool isKotBleDevice(BluetoothDevice device) =>
      _matchesBleRole(kotRoleInfo.value, device);

  bool isBillUsbPrinter(Printer printer) =>
      _matchesUsbRole(billRoleInfo.value, printer);

  bool isKotUsbPrinter(Printer printer) =>
      _matchesUsbRole(kotRoleInfo.value, printer);

  bool isBillClassicBt(String address) =>
      _matchesClassicBtRole(billRoleInfo.value, address);

  bool isKotClassicBt(String address) =>
      _matchesClassicBtRole(kotRoleInfo.value, address);

  bool _matchesNetworkRole(Map<String, dynamic> info, String ip, int port) {
    if (info['type'] != 'network') return false;
    final savedIp = (info['ip'] as String?)?.trim() ?? '';
    if (savedIp.isEmpty || savedIp != ip.trim()) return false;
    final savedPort = info['port'] as int? ?? 9100;
    return savedPort == port;
  }

  bool isBillNetworkPrinter(String ip, int port) =>
      _matchesNetworkRole(billRoleInfo.value, ip, port);

  bool isKotNetworkPrinter(String ip, int port) =>
      _matchesNetworkRole(kotRoleInfo.value, ip, port);

  int? _parsePort() {
    final p = int.tryParse(portController.text.trim());
    if (p == null || p < 1 || p > 65535) return null;
    return p;
  }

  bool _isValidIp(String ip) {
    final parts = ip.trim().split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      final n = int.tryParse(part);
      if (n == null || n < 0 || n > 255) return false;
    }
    return true;
  }

  Future<void> connectEthernet() async {
    final ip = ipController.text.trim();
    final port = _parsePort();
    if (!_isValidIp(ip)) {
      AppSnackbar.show(
        title: 'Error',
        message: 'Enter a valid IP address (e.g. 192.168.1.100)',
      );
      return;
    }
    if (port == null) {
      AppSnackbar.show(
        title: 'Error',
        message: 'Enter a valid port (default 9100)',
      );
      return;
    }

    if (thermalPrinter.isNetworkConnected.value &&
        thermalPrinter.connectedNetworkLabel.value == '$ip:$port') {
      await thermalPrinter.disconnectNetworkPrinter();
      AppSnackbar.show(
        title: 'Success',
        message: 'Ethernet printer disconnected',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      isRoleActionLoading.value = true;
      final ok = await thermalPrinter.connectNetworkPrinter(ip, port: port);
      AppSnackbar.show(
        title: ok ? 'Success' : 'Error',
        message: ok
            ? 'Connected to $ip:$port'
            : 'Could not connect. Check IP, port, and that the printer is on the same network.',
        duration: const Duration(seconds: 2),
      );
    } finally {
      isRoleActionLoading.value = false;
    }
  }

  Future<void> assignNetworkToRole(PrintRole role) async {
    final ip = ipController.text.trim();
    final port = _parsePort();
    if (!_isValidIp(ip)) {
      AppSnackbar.show(title: 'Error', message: 'Enter a valid IP address first');
      return;
    }
    if (port == null) {
      AppSnackbar.show(title: 'Error', message: 'Enter a valid port');
      return;
    }

    try {
      isRoleActionLoading.value = true;
      if (!thermalPrinter.isNetworkConnected.value) {
        final connected =
            await thermalPrinter.connectNetworkPrinter(ip, port: port);
        if (!connected) {
          AppSnackbar.show(
            title: 'Error',
            message: 'Connect to the printer first',
          );
          return;
        }
      }
      await thermalPrinter.assignNetworkToRole(
        role,
        ip,
        port,
        name: 'Ethernet $ip',
      );
      await loadRolePrinters();
      await thermalPrinter.restoreNetworkConnectionStatus();
      AppSnackbar.show(
        title: 'Success',
        message: '${role == PrintRole.bill ? 'Bill' : 'KOT'} printer: $ip:$port',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppSnackbar.show(title: 'Error', message: 'Failed: $e');
    } finally {
      isRoleActionLoading.value = false;
    }
  }

  Future<void> assignBluetoothToRole(
    PrintRole role,
    BluetoothDevice device,
  ) async {
    try {
      isRoleActionLoading.value = true;
      await thermalPrinter.assignBluetoothToRole(role, device);
      await loadRolePrinters();
      AppSnackbar.show(
        title: 'Success',
        message:
            '${role == PrintRole.bill ? 'Bill' : 'KOT'} printer: ${device.platformName}',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppSnackbar.show(title: 'Error', message: '$e');
    } finally {
      isRoleActionLoading.value = false;
    }
  }

  Future<void> assignUsbToRole(PrintRole role, Printer printer) async {
    try {
      isRoleActionLoading.value = true;
      await thermalPrinter.assignUsbToRole(role, printer);
      await loadRolePrinters();
      AppSnackbar.show(
        title: 'Success',
        message:
            '${role == PrintRole.bill ? 'Bill' : 'KOT'} printer: ${printer.name ?? 'USB'}',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppSnackbar.show(title: 'Error', message: '$e');
    } finally {
      isRoleActionLoading.value = false;
    }
  }

  Future<void> assignClassicBluetoothToRole(
    PrintRole role, {
    required String address,
    required String name,
  }) async {
    try {
      isRoleActionLoading.value = true;
      final roleKey = role == PrintRole.bill ? 'bill' : 'kot';
      await StorageHelper.saveRoleBluetoothByAddress(roleKey, address, name);
      await loadRolePrinters();
      AppSnackbar.show(
        title: 'Success',
        message: '${role == PrintRole.bill ? 'Bill' : 'KOT'} printer: $name',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppSnackbar.show(
        title: 'Error',
        message: '$e',
        duration: const Duration(seconds: 2),
      );
    } finally {
      isRoleActionLoading.value = false;
    }
  }

  Future<void> clearRolePrinter(PrintRole role) async {
    await thermalPrinter.clearRolePrinter(role);
    await loadRolePrinters();
    AppSnackbar.show(
      title: 'Removed',
      message: '${role == PrintRole.bill ? 'Bill' : 'KOT'} printer cleared',
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> testPrintForRole(PrintRole role) async {
    try {
      isRoleActionLoading.value = true;
      await thermalPrinter.testPrintForRole(role);
      AppSnackbar.show(
        title: 'Success',
        message: '${role == PrintRole.bill ? 'Bill' : 'KOT'} test print sent',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppSnackbar.show(
        title: 'Print failed',
        message: '$e',
        duration: const Duration(seconds: 2),
      );
    } finally {
      isRoleActionLoading.value = false;
    }
  }

  Future<void> useSamePrinterForKot() async {
    final billInfo = await StorageHelper.getRoleSavedPrinterInfo('bill');
    final type = billInfo['type'] as String?;
    if (type == null) {
      AppSnackbar.show(
        title: 'Error',
        message: 'Set a bill printer first',
        duration: const Duration(seconds: 2),
      );
      return;
    }
    if (type == 'bluetooth') {
      final id = billInfo['id'] as String?;
      if (id == null || id.isEmpty) {
        AppSnackbar.show(
          title: 'Error',
          message: 'Bill printer not configured',
          duration: const Duration(seconds: 2),
        );
        return;
      }
      try {
        isRoleActionLoading.value = true;
        await FlutterBluePlus.stopScan();
        BluetoothDevice? device;
        final sub = FlutterBluePlus.scanResults.listen((results) {
          for (final r in results) {
            if (r.device.remoteId.toString() == id) {
              device = r.device;
            }
          }
        });
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
        await Future.delayed(const Duration(seconds: 6));
        await FlutterBluePlus.stopScan();
        await sub.cancel();
        if (device != null) {
          await thermalPrinter.assignBluetoothToRole(PrintRole.kot, device!);
          await loadRolePrinters();
          AppSnackbar.show(
            title: 'Success',
            message: 'KOT printer set same as bill printer',
            duration: const Duration(seconds: 2),
          );
        } else {
          AppSnackbar.show(
            title: 'Error',
            message: 'Bill printer not found. Turn it on and retry.',
            duration: const Duration(seconds: 2),
          );
        }
      } catch (e) {
        AppSnackbar.show(
          title: 'Error',
          message: '$e',
          duration: const Duration(seconds: 2),
        );
      } finally {
        isRoleActionLoading.value = false;
      }
    } else if (type == 'usb') {
      await StorageHelper.saveRoleUsbPrinter(
        'kot',
        (billInfo['name'] as String?) ?? '',
        vendorId: billInfo['vendorId'] as int?,
        productId: billInfo['productId'] as int?,
        address: billInfo['address'] as String?,
      );
      await loadRolePrinters();
      AppSnackbar.show(
        title: 'Success',
        message: 'KOT printer set same as bill printer',
        duration: const Duration(seconds: 2),
      );
    } else if (type == 'network') {
      final ip = billInfo['ip'] as String?;
      final port = billInfo['port'] as int? ?? 9100;
      if (ip == null || ip.isEmpty) {
        AppSnackbar.show(
          title: 'Error',
          message: 'Bill printer not configured',
          duration: const Duration(seconds: 2),
        );
        return;
      }
      await StorageHelper.saveRoleNetworkPrinter(
        'kot',
        ip,
        port,
        name: billInfo['name'] as String?,
      );
      await loadRolePrinters();
      AppSnackbar.show(
        title: 'Success',
        message: 'KOT printer set same as bill printer',
        duration: const Duration(seconds: 2),
      );
    }
  }
}
