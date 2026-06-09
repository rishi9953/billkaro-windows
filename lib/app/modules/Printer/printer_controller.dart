import 'dart:async';
import 'dart:io' show Platform;

import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/helpers/storage_helper.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterController extends BaseController
    with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  // Get the singleton printer service instance
  final printerService = ThermalPrinterService.instance;

  // ------------------ Bluetooth ------------------
  var devices = <BluetoothDevice>[].obs;
  var isScanning = false.obs;
  var selectedTabIndex = 0.obs;
  var connectedDevice = Rx<BluetoothDevice?>(null);

  // Auto-connect settings
  final autoConnectEnabled = false.obs;
  final savedDeviceName = Rxn<String>();
  final savedBillPrinterName = Rxn<String>();
  final savedKotPrinterName = Rxn<String>();
  final savedBillPrinterType = Rxn<String>();
  final savedKotPrinterType = Rxn<String>();

  // ------------------ USB Printers ------------------
  var usbDevices = <Printer>[].obs;
  var isUsbConnected = false.obs;
  var isCheckingUsb = false.obs;
  var connectedUsbPrinter = Rx<Printer?>(null);

  final _flutterThermalPrinter = FlutterThermalPrinter.instance;
  StreamSubscription<List<Printer>>? _devicesStreamSubscription;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);

    tabController.addListener(() {
      selectedTabIndex.value = tabController.index;
      if (selectedTabIndex.value == 1) {
        startUsbScan();
      }
    });

    // Load auto-connect settings
    _loadAutoConnectSettings();

    // Listen to printer service changes
    _listenToPrinterService();

    checkBluetoothPermission();
    if (!kIsWeb && Platform.isWindows) {
      tabController.index = 1;
      selectedTabIndex.value = 1;
      startUsbScan();
    }
  }

  void _listenToPrinterService() {
    // Sync scan results from printer service
    ever(printerService.scanResults, (results) {
      devices.value = results.map((r) => r.device).toList();
    });

    // Sync scanning state
    ever(printerService.isScanning, (scanning) {
      isScanning.value = scanning;
    });

    // Sync connected device
    ever(printerService.isConnected, (connected) {
      if (connected) {
        connectedDevice.value = printerService.connectedDevice;
      } else {
        connectedDevice.value = null;
      }
    });
  }

  Future<void> _loadAutoConnectSettings() async {
    final enabled = await printerService.isAutoConnectEnabled();
    final deviceName = await printerService.getSavedDeviceName();
    autoConnectEnabled.value = enabled;
    savedDeviceName.value = deviceName;

    final billInfo = await StorageHelper.getRoleSavedPrinterInfo('bill');
    final kotInfo = await StorageHelper.getRoleSavedPrinterInfo('kot');
    savedBillPrinterName.value = (billInfo['name'] as String?)?.trim();
    savedKotPrinterName.value = (kotInfo['name'] as String?)?.trim();
    savedBillPrinterType.value = _typeLabel(billInfo['type'] as String?);
    savedKotPrinterType.value = _typeLabel(kotInfo['type'] as String?);
  }

  String? _typeLabel(String? type) {
    if (type == 'usb') return 'USB';
    if (type == 'bluetooth') return 'Bluetooth';
    return null;
  }

  Future<void> assignBluetoothToRole(
    PrintRole role,
    BluetoothDevice device,
  ) async {
    try {
      await printerService.assignBluetoothToRole(role, device);
      await _loadAutoConnectSettings();
      showSuccess(
        description:
            '${role == PrintRole.bill ? 'Bill' : 'KOT'} printer assigned to ${device.platformName}',
      );
    } catch (e) {
      showError(description: 'Failed to assign printer: $e');
    }
  }

  Future<void> assignUsbToRole(PrintRole role, Printer printer) async {
    try {
      await printerService.assignUsbToRole(role, printer);
      await _loadAutoConnectSettings();
      showSuccess(
        description:
            '${role == PrintRole.bill ? 'Bill' : 'KOT'} printer assigned to ${printer.name ?? 'USB Printer'}',
      );
    } catch (e) {
      showError(description: 'Failed to assign printer: $e');
    }
  }

  Future<void> clearRolePrinter(PrintRole role) async {
    await printerService.clearRolePrinter(role);
    await _loadAutoConnectSettings();
    showSuccess(
      description:
          '${role == PrintRole.bill ? 'Bill' : 'KOT'} printer removed',
    );
  }

  Future<void> testPrintForRole(PrintRole role) async {
    try {
      showAppLoader();
      await printerService.testPrintForRole(role);
      showSuccess(
        description:
            '${role == PrintRole.bill ? 'Bill' : 'KOT'} test print sent',
      );
    } catch (e) {
      showError(description: e.toString());
    } finally {
      dismissAppLoader();
    }
  }

  Future<void> setCurrentAsBillPrinter() async {
    if (printerService.isUsbConnected.value &&
        printerService.connectedUsbPrinter != null) {
      await assignUsbToRole(
        PrintRole.bill,
        printerService.connectedUsbPrinter!,
      );
    } else if (printerService.connectedDevice != null) {
      await assignBluetoothToRole(
        PrintRole.bill,
        printerService.connectedDevice!,
      );
    } else {
      showError(description: 'No printer connected');
    }
  }

  Future<void> setCurrentAsKotPrinter() async {
    if (printerService.isUsbConnected.value &&
        printerService.connectedUsbPrinter != null) {
      await assignUsbToRole(
        PrintRole.kot,
        printerService.connectedUsbPrinter!,
      );
    } else if (printerService.connectedDevice != null) {
      await assignBluetoothToRole(
        PrintRole.kot,
        printerService.connectedDevice!,
      );
    } else {
      showError(description: 'No printer connected');
    }
  }

  Future<void> useSamePrinterForKot() async {
    final billInfo = await StorageHelper.getRoleSavedPrinterInfo('bill');
    final type = billInfo['type'] as String?;
    if (type == null) {
      showError(description: 'Set a bill printer first');
      return;
    }
    if (type == 'bluetooth') {
      final id = billInfo['id'] as String?;
      if (id == null || id.isEmpty) {
        showError(description: 'Bill printer not configured');
        return;
      }
      try {
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
          await assignBluetoothToRole(PrintRole.kot, device!);
        } else {
          showError(description: 'Bill printer not found. Turn it on and retry.');
        }
      } catch (e) {
        showError(description: 'Failed: $e');
      }
    } else if (type == 'usb') {
      await StorageHelper.saveRoleUsbPrinter(
        'kot',
        (billInfo['name'] as String?) ?? '',
        vendorId: billInfo['vendorId'] as int?,
        productId: billInfo['productId'] as int?,
        address: billInfo['address'] as String?,
      );
      await _loadAutoConnectSettings();
      showSuccess(description: 'KOT printer set same as bill printer');
    }
  }

  Future<void> toggleAutoConnect(bool value) async {
    await printerService.enableAutoConnect(value);
    autoConnectEnabled.value = value;

    showSuccess(
      description: value
          ? 'Auto-connect enabled. Will connect automatically on app start'
          : 'Auto-connect disabled',
    );

    // Reload settings
    await _loadAutoConnectSettings();
  }

  Future<void> clearSavedDevice() async {
    await printerService.clearSavedDevice();
    savedDeviceName.value = null;
    autoConnectEnabled.value = false;

    showSuccess(description: 'Saved printer removed');
  }

  // ------------------ Bluetooth Permissions ------------------
  Future<void> checkBluetoothPermission() async {
    try {
      if (!kIsWeb && Platform.isWindows) {
        return;
      }
      if (await FlutterBluePlus.isSupported == false) {
        if (Platform.isAndroid) {
          showError(description: 'Bluetooth not supported on this device');
        }
        return;
      }
      // turnOn() is Android-only; desktop uses the OS Bluetooth toggle.
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      }
    } catch (e) {
      debugPrint('Bluetooth permission error: $e');
      if (Platform.isAndroid) {
        showError(
          description: 'Please enable Bluetooth permissions in settings',
        );
      }
    }
  }

  // ------------------ Bluetooth Scan ------------------
  Future<void> scanForDevices() async {
    try {
      if (Platform.isAndroid) {
        await printerService.requestPermissions();
        await ensureLocationService();
      }
      await printerService.startScan();
    } catch (e) {
      showError(description: 'Failed to scan Bluetooth: $e');
      debugPrint('Bluetooth scan error: $e');
    }
  }

  Future<void> ensureLocationService() async {
    final serviceStatus = await Permission.location.serviceStatus;

    if (serviceStatus == ServiceStatus.disabled) {
      await Permission.location.request();
    }

    if (!serviceStatus.isEnabled) {
      throw Exception("Location services (GPS) are OFF. Please enable it.");
    }
  }

  // ------------------ Connect to Device ------------------
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // Show loading
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final success = await printerService.connectToDevice(device);

      // Close loading dialog
      Get.back();

      if (success) {
        connectedDevice.value = device;

        // Reload settings to show saved device
        await _loadAutoConnectSettings();

        showSuccess(
          description:
              'Connected to ${device.platformName.isNotEmpty ? device.platformName : 'Printer'}',
        );
      } else {
        showError(description: 'Failed to connect to printer');
      }
    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      showError(description: 'Connection error: ${e.toString()}');
      debugPrint('Connection error: $e');
    }
  }

  // ------------------ Disconnect Device ------------------
  Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      await printerService.disconnect();
      connectedDevice.value = null;
      showSuccess(description: 'Disconnected from printer');
    } catch (e) {
      showError(description: 'Failed to disconnect: $e');
    }
  }

  // ------------------ USB Printer Handling -----------------

  Future<void> startUsbScan() async {
    debugPrint('Starting USB printer scan...');
    await printerService.requestPermissions(); // <-- IMPORTANT FIX
    isCheckingUsb.value = true;
    usbDevices.clear();
    isUsbConnected.value = false;

    try {
      // Get USB printers
      await _flutterThermalPrinter.getPrinters(
        connectionTypes: [ConnectionType.USB],
      );

      // Cancel previous subscription
      _devicesStreamSubscription?.cancel();

      // Listen to devices stream
      _devicesStreamSubscription = _flutterThermalPrinter.devicesStream.listen((
        List<Printer> devices,
      ) {
        debugPrint('Raw USB devices found: ${devices.length}');

        // Filter devices
        final filtered = devices.toList();

        usbDevices.assignAll(filtered);

        debugPrint('USB Printers found: ${usbDevices.length}');
        for (var printer in usbDevices) {
          debugPrint(
            'Printer: ${printer.name ?? 'Unknown'} - ${printer.address}',
          );
        }
      });
    } catch (e) {
      debugPrint('Error scanning USB printers: $e');
      showError(description: 'Error scanning USB: $e');
      isUsbConnected.value = false;
    } finally {
      isCheckingUsb.value = false;
    }
  }

  Future<void> connectUsbPrinter(Printer printer) async {
    try {
      final connected = await _flutterThermalPrinter.connect(printer);
      if (connected && await _isUsbPrinterStillAvailable(printer)) {
        connectedUsbPrinter.value = printer;
        isUsbConnected.value = true;
        showSuccess(
          description: 'Connected to ${printer.name ?? 'USB Printer'}',
        );
      } else {
        connectedUsbPrinter.value = null;
        isUsbConnected.value = false;
        showError(description: 'USB printer is not connected');
      }
    } catch (e) {
      connectedUsbPrinter.value = null;
      isUsbConnected.value = false;
      showError(description: 'Failed to connect to USB printer: $e');
      debugPrint('USB connection error: $e');
    }
  }

  Future<bool> _isUsbPrinterStillAvailable(Printer targetPrinter) async {
    try {
      await _flutterThermalPrinter.getPrinters(
        connectionTypes: [ConnectionType.USB],
      );
      final devices = await _flutterThermalPrinter.devicesStream.first.timeout(
        const Duration(seconds: 2),
      );
      return devices.any((p) => _isSameUsbPrinter(p, targetPrinter));
    } catch (_) {
      return false;
    }
  }

  bool _isSameUsbPrinter(Printer a, Printer b) {
    final aAddress = (a.address ?? '').trim();
    final bAddress = (b.address ?? '').trim();
    if (aAddress.isNotEmpty && bAddress.isNotEmpty) {
      return aAddress == bAddress;
    }

    final aVendor = '${a.vendorId ?? ''}'.trim();
    final bVendor = '${b.vendorId ?? ''}'.trim();
    final aProduct = '${a.productId ?? ''}'.trim();
    final bProduct = '${b.productId ?? ''}'.trim();
    if (aVendor.isNotEmpty &&
        bVendor.isNotEmpty &&
        aProduct.isNotEmpty &&
        bProduct.isNotEmpty) {
      return aVendor == bVendor && aProduct == bProduct;
    }

    final aName = (a.name ?? '').trim();
    final bName = (b.name ?? '').trim();
    return aName.isNotEmpty && bName.isNotEmpty && aName == bName;
  }

  Future<void> disconnectUsbPrinter() async {
    try {
      await _flutterThermalPrinter.disconnect(Printer.fromJson({}));
      connectedUsbPrinter.value = null;
      isUsbConnected.value = false;
      showSuccess(description: 'Disconnected from USB printer');
    } catch (e) {
      showError(description: 'Failed to disconnect: $e');
    }
  }

  // ------------------ Test Print ------------------
  Future<void> printTestReceipt() async {
    // Check which printer is connected
    if (connectedDevice.value != null) {
      // Bluetooth printer
      await _printBluetoothTest();
    } else if (connectedUsbPrinter.value != null) {
      // USB printer
      await _printUsbTest();
    } else {
      showError(description: 'No printer connected');
    }
  }

  Future<void> _printBluetoothTest() async {
    try {
      if (!printerService.isConnected.value) {
        showError(description: 'Bluetooth printer not connected');
        return;
      }
      showAppLoader();
      await printerService.printInvoice(
        brandName: "Test Restaurant",
        businessName: "Test Business Ltd",
        address: "123 Test Street",
        city: "Test City",
        zipcode: "123456",
        state: "Test State",
        orderFrom: "Test Order",
        customerName: "Test Customer",
        paymentMode: "Cash",
        date: DateTime.now().toString().split(' ')[0],
        time: TimeOfDay.now().format(Get.context!),
        invoiceNo: "TEST-${DateTime.now().millisecondsSinceEpoch}",
        items: [
          // InvoiceItem(
          //   itemName: "Test Item 1",
          //   quantity: 2,
          //   price: 100.0,
          //   amount: 200.0,
          // ),
          // InvoiceItem(
          //   itemName: "Test Item 2",
          //   quantity: 1,
          //   price: 150.0,
          //   amount: 150.0,
          // ),
        ],
        subtotal: 350.0,
        totalTax: 63.0,
        serviceCharge: 0.0,
        discount: 0.0,
        totalAmount: 413.0,
        upiId: "test@upi",
      );

      showSuccess(description: 'Bluetooth test receipt printed successfully');
    } catch (e) {
      showError(description: 'Failed to print via Bluetooth: $e');
      debugPrint('Bluetooth print error: $e');
    }
  }

  Future<void> _printUsbTest() async {
    try {
      _flutterThermalPrinter.printInfo(
        info: "Test print successful ✅\n\nBillKaro Printer Test",
      );
      showSuccess(description: 'USB test receipt printed successfully');
    } catch (e) {
      showError(description: 'Failed to print via USB: $e');
      debugPrint('USB print error: $e');
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    _devicesStreamSubscription?.cancel();

    // Disconnect any connected devices
    if (connectedDevice.value != null) {
      printerService.disconnect();
    }

    super.onClose();
  }
}
