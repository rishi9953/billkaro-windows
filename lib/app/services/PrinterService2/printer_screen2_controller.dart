import 'package:billkaro/app/services/printerService.dart/thermal_printer/helpers/storage_helper.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/utils/app_snackbar.dart';
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

  @override
  void onInit() {
    super.onInit();
    loadRolePrinters();
  }

  String? _typeLabel(String? type) {
    if (type == 'usb') return 'USB';
    if (type == 'bluetooth') return 'Bluetooth';
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
    }
  }
}
