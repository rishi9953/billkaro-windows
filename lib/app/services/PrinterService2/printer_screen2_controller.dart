import 'package:billkaro/app/services/printerService.dart/thermal_printer/helpers/storage_helper.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/helpers/thermal_paper_size.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/config/config.dart';
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
  final selectedPaperSize = ThermalPaperSize.mm58.obs;

  final ipController = TextEditingController();
  final portController = TextEditingController(text: '9100');

  @override
  void onInit() {
    super.onInit();
    loadRolePrinters();
    loadPaperSize();
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

  String _roleLabel(PrintRole role) {
    final loc = AppLocalizations.of(Get.context!)!;
    return role == PrintRole.bill ? loc.bill_label : loc.kot_label;
  }

  String? _typeLabel(String? type) {
    final loc = AppLocalizations.of(Get.context!)!;
    if (type == 'usb') return loc.usb;
    if (type == 'bluetooth') return loc.bluetooth;
    if (type == 'network') return loc.ethernet;
    return null;
  }

  Future<void> loadPaperSize() async {
    final size = await StorageHelper.getThermalPaperSize();
    selectedPaperSize.value = size;
    thermalPrinter.selectedPaperSize.value = size;
  }

  String paperSizeLabel(ThermalPaperSize size) {
    final loc = AppLocalizations.of(Get.context!)!;
    switch (size) {
      case ThermalPaperSize.mm58:
        return loc.paper_size_2inch;
      case ThermalPaperSize.mm80:
        return loc.paper_size_3inch;
      case ThermalPaperSize.mm104:
        return loc.paper_size_4inch;
    }
  }

  Future<void> setPaperSize(ThermalPaperSize size) async {
    final loc = AppLocalizations.of(Get.context!)!;
    await thermalPrinter.setPaperSize(size);
    selectedPaperSize.value = size;
    showSuccess(
      title: loc.snackbar_success,
      description: loc.paper_size_saved(paperSizeLabel(size)),
    );
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
    final loc = AppLocalizations.of(Get.context!)!;
    final ip = ipController.text.trim();
    final port = _parsePort();
    if (!_isValidIp(ip)) {
      showError(
        title: loc.snackbar_error,
        description: loc.enter_valid_ip_example,
      );
      return;
    }
    if (port == null) {
      showError(
        title: loc.snackbar_error,
        description: loc.enter_valid_port_default,
      );
      return;
    }

    if (thermalPrinter.isNetworkConnected.value &&
        thermalPrinter.connectedNetworkLabel.value == '$ip:$port') {
      await thermalPrinter.disconnectNetworkPrinter();
      showSuccess(
        title: loc.snackbar_success,
        description: loc.ethernet_printer_disconnected,
      );
      return;
    }

    try {
      isRoleActionLoading.value = true;
      final ok = await thermalPrinter.connectNetworkPrinter(ip, port: port);
      if (ok) {
        showSuccess(
          title: loc.snackbar_success,
          description: loc.connected_to_endpoint('$ip:$port'),
        );
      } else {
        showError(
          title: loc.snackbar_error,
          description: loc.could_not_connect_network_printer,
        );
      }
    } finally {
      isRoleActionLoading.value = false;
    }
  }

  Future<void> assignNetworkToRole(PrintRole role) async {
    final loc = AppLocalizations.of(Get.context!)!;
    final ip = ipController.text.trim();
    final port = _parsePort();
    if (!_isValidIp(ip)) {
      showError(
        title: loc.snackbar_error,
        description: loc.enter_valid_ip_first,
      );
      return;
    }
    if (port == null) {
      showError(
        title: loc.snackbar_error,
        description: loc.enter_valid_port,
      );
      return;
    }

    try {
      isRoleActionLoading.value = true;
      if (!thermalPrinter.isNetworkConnected.value) {
        final connected =
            await thermalPrinter.connectNetworkPrinter(ip, port: port);
        if (!connected) {
          showError(
            title: loc.snackbar_error,
            description: loc.connect_printer_first,
          );
          return;
        }
      }
      await thermalPrinter.assignNetworkToRole(
        role,
        ip,
        port,
        name: loc.ethernet_printer_name(ip),
      );
      await loadRolePrinters();
      await thermalPrinter.restoreNetworkConnectionStatus();
      showSuccess(
        title: loc.snackbar_success,
        description: loc.role_printer_assigned(
          _roleLabel(role),
          '$ip:$port',
        ),
      );
    } catch (e) {
      showError(
        title: loc.snackbar_error,
        description: loc.operation_failed_error(e.toString()),
      );
    } finally {
      isRoleActionLoading.value = false;
    }
  }

  Future<void> assignBluetoothToRole(
    PrintRole role,
    BluetoothDevice device,
  ) async {
    final loc = AppLocalizations.of(Get.context!)!;
    try {
      isRoleActionLoading.value = true;
      await thermalPrinter.assignBluetoothToRole(role, device);
      await loadRolePrinters();
      showSuccess(
        title: loc.snackbar_success,
        description: loc.role_printer_assigned(
          _roleLabel(role),
          device.platformName,
        ),
      );
    } catch (e) {
      showError(
        title: loc.snackbar_error,
        description: loc.operation_failed_error(e.toString()),
      );
    } finally {
      isRoleActionLoading.value = false;
    }
  }

  Future<void> assignUsbToRole(PrintRole role, Printer printer) async {
    final loc = AppLocalizations.of(Get.context!)!;
    try {
      isRoleActionLoading.value = true;
      await thermalPrinter.assignUsbToRole(role, printer);
      await loadRolePrinters();
      showSuccess(
        title: loc.snackbar_success,
        description: loc.role_printer_assigned(
          _roleLabel(role),
          printer.name ?? loc.usb,
        ),
      );
    } catch (e) {
      showError(
        title: loc.snackbar_error,
        description: loc.operation_failed_error(e.toString()),
      );
    } finally {
      isRoleActionLoading.value = false;
    }
  }

  Future<void> assignClassicBluetoothToRole(
    PrintRole role, {
    required String address,
    required String name,
  }) async {
    final loc = AppLocalizations.of(Get.context!)!;
    try {
      isRoleActionLoading.value = true;
      final roleKey = role == PrintRole.bill ? 'bill' : 'kot';
      await StorageHelper.saveRoleBluetoothByAddress(roleKey, address, name);
      await loadRolePrinters();
      showSuccess(
        title: loc.snackbar_success,
        description: loc.role_printer_assigned(_roleLabel(role), name),
      );
    } catch (e) {
      showError(
        title: loc.snackbar_error,
        description: loc.operation_failed_error(e.toString()),
      );
    } finally {
      isRoleActionLoading.value = false;
    }
  }

  Future<void> clearRolePrinter(PrintRole role) async {
    final loc = AppLocalizations.of(Get.context!)!;
    await thermalPrinter.clearRolePrinter(role);
    await loadRolePrinters();
    showSuccess(
      title: loc.snackbar_removed,
      description: loc.role_printer_cleared(_roleLabel(role)),
    );
  }

  Future<void> testPrintForRole(PrintRole role) async {
    final loc = AppLocalizations.of(Get.context!)!;
    try {
      isRoleActionLoading.value = true;
      await thermalPrinter.testPrintForRole(role);
      showSuccess(
        title: loc.snackbar_success,
        description: loc.role_test_print_sent(_roleLabel(role)),
      );
    } catch (e) {
      showError(
        title: loc.snackbar_error,
        description: loc.print_failed_with_error(e.toString()),
      );
    } finally {
      isRoleActionLoading.value = false;
    }
  }

  Future<void> testOpenCashDrawer() async {
    final loc = AppLocalizations.of(Get.context!)!;
    try {
      isRoleActionLoading.value = true;
      await thermalPrinter.openCashDrawer();
      showSuccess(
        title: loc.snackbar_success,
        description: loc.cash_drawer_opened,
      );
    } catch (e) {
      showError(
        title: loc.snackbar_error,
        description: loc.cash_drawer_failed(e.toString()),
      );
    } finally {
      isRoleActionLoading.value = false;
    }
  }

  Future<void> useSamePrinterForKot() async {
    final loc = AppLocalizations.of(Get.context!)!;
    final billInfo = await StorageHelper.getRoleSavedPrinterInfo('bill');
    final type = billInfo['type'] as String?;
    if (type == null) {
      showError(
        title: loc.snackbar_error,
        description: loc.set_bill_printer_first,
      );
      return;
    }
    if (type == 'bluetooth') {
      final id = billInfo['id'] as String?;
      if (id == null || id.isEmpty) {
        showError(
          title: loc.snackbar_error,
          description: loc.bill_printer_not_configured,
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
          showSuccess(
            title: loc.snackbar_success,
            description: loc.kot_printer_same_as_bill,
          );
        } else {
          showError(
            title: loc.snackbar_error,
            description: loc.bill_printer_not_found,
          );
        }
      } catch (e) {
        showError(
          title: loc.snackbar_error,
          description: loc.operation_failed_error(e.toString()),
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
      showSuccess(
        title: loc.snackbar_success,
        description: loc.kot_printer_same_as_bill,
      );
    } else if (type == 'network') {
      final ip = billInfo['ip'] as String?;
      final port = billInfo['port'] as int? ?? 9100;
      if (ip == null || ip.isEmpty) {
        showError(
          title: loc.snackbar_error,
          description: loc.bill_printer_not_configured,
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
      showSuccess(
        title: loc.snackbar_success,
        description: loc.kot_printer_same_as_bill,
      );
    }
  }
}
