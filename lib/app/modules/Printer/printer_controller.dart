import 'dart:async';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/helpers/storage_helper.dart';
import 'package:billkaro/config/config.dart';
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
  }

  Future<void> setCurrentAsBillPrinter() async {
    try {
      if (printerService.isUsbConnected.value &&
          printerService.connectedUsbPrinter != null) {
        final p = printerService.connectedUsbPrinter!;
        await StorageHelper.saveRoleUsbPrinter(
          'bill',
          p.name ?? '',
          vendorId: int.tryParse('${p.vendorId ?? ''}'),
          productId: int.tryParse('${p.productId ?? ''}'),
        );
      } else if (printerService.connectedDevice != null) {
        await StorageHelper.saveRoleBluetoothDevice(
          'bill',
          printerService.connectedDevice!,
        );
      } else {
        showError(description: 'No printer connected');
        return;
      }

      await _loadAutoConnectSettings();
      showSuccess(description: 'Bill printer set successfully');
    } catch (e) {
      showError(description: 'Failed to set bill printer: $e');
    }
  }

  Future<void> setCurrentAsKotPrinter() async {
    try {
      if (printerService.isUsbConnected.value &&
          printerService.connectedUsbPrinter != null) {
        final p = printerService.connectedUsbPrinter!;
        await StorageHelper.saveRoleUsbPrinter(
          'kot',
          p.name ?? '',
          vendorId: int.tryParse('${p.vendorId ?? ''}'),
          productId: int.tryParse('${p.productId ?? ''}'),
        );
      } else if (printerService.connectedDevice != null) {
        await StorageHelper.saveRoleBluetoothDevice(
          'kot',
          printerService.connectedDevice!,
        );
      } else {
        showError(description: 'No printer connected');
        return;
      }

      await _loadAutoConnectSettings();
      showSuccess(description: 'KOT printer set successfully');
    } catch (e) {
      showError(description: 'Failed to set KOT printer: $e');
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
      // Check if Bluetooth is available
      if (await FlutterBluePlus.isSupported == false) {
        showError(description: 'Bluetooth not supported on this device');
        return;
      }

      // Request to turn on Bluetooth if off
      await FlutterBluePlus.turnOn();
    } catch (e) {
      debugPrint('Bluetooth permission error: $e');
      showError(description: 'Please enable Bluetooth permissions in settings');
    }
  }

  // ------------------ Bluetooth Scan ------------------
  Future<void> scanForDevices() async {
    try {
      await printerService.requestPermissions(); // <-- IMPORTANT FIX
      await ensureLocationService();
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
        isUsbConnected.value = usbDevices.isNotEmpty;

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
      await _flutterThermalPrinter.connect(printer);
      connectedUsbPrinter.value = printer;
      showSuccess(description: 'Connected to ${printer.name ?? 'USB Printer'}');
    } catch (e) {
      showError(description: 'Failed to connect to USB printer: $e');
      debugPrint('USB connection error: $e');
    }
  }

  Future<void> disconnectUsbPrinter() async {
    try {
      await _flutterThermalPrinter.disconnect(Printer.fromJson({}));
      connectedUsbPrinter.value = null;
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
