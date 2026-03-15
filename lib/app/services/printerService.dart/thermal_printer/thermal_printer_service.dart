import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/app/services/PrinterService2/printer_service2.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/printer_dialog_widget.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'helpers/storage_helper.dart';
import 'helpers/bluetooth_helper.dart';
import 'builders/print_builder.dart';
import 'generators/qr_generator.dart';
import 'helpers/text_helper.dart';

enum PrintRole { bill, kot }

class ThermalPrinterService extends GetxController {
  // Singleton pattern
  static ThermalPrinterService? _instance;
  factory ThermalPrinterService() =>
      _instance ??= ThermalPrinterService._internal();
  ThermalPrinterService._internal();
  static ThermalPrinterService get instance => ThermalPrinterService();

  // Bluetooth connection state
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;

  // Observable states
  final isScanning = false.obs;
  final isConnected = false.obs;
  final scanResults = <ScanResult>[].obs;
  final connectionStatus = ''.obs;
  final isAutoConnecting = false.obs;

  // USB connection state
  Printer? connectedUsbPrinter;
  final isUsbConnected = false.obs;
  final usbPrinters = <Printer>[].obs;
  final isUsbScanning = false.obs;

  @override
  void onInit() {
    super.onInit();
    BluetoothHelper.listenToConnectionState(this);
    _initAutoConnect();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  // Public API - Permissions
  Future<void> requestPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  // Public API - Bluetooth Scanning
  Future<void> startScan() async {
    try {
      isScanning.value = true;
      scanResults.clear();
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      FlutterBluePlus.scanResults.listen(
        (results) => scanResults.value = results,
      );
      await Future.delayed(const Duration(seconds: 10));
      await stopScan();
    } catch (e) {
      debugPrint('Scan error: $e');
      isScanning.value = false;
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    isScanning.value = false;
  }

  // Public API - USB Scanning and Connection
  List<Printer> printers = [];
  StreamSubscription<List<Printer>>? _devicesStreamSubscription;

  Future<void> checkForUsbPermission() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  Future<void> scanUsbPrinters() async {
    try {
      await checkForUsbPermission();
      _devicesStreamSubscription?.cancel();
      isUsbScanning.value = true;
      usbPrinters.clear();

      await FlutterThermalPrinter.instance.getPrinters(
        connectionTypes: [ConnectionType.USB],
      );

      _devicesStreamSubscription = FlutterThermalPrinter.instance.devicesStream
          .listen((List<Printer> event) {
            printers = event;
            printers.removeWhere(
              (element) =>
                  element.name == null ||
                  element.name == '' ||
                  element.name!.toLowerCase().contains("print") == false,
            );
          });
      if (printers.isNotEmpty) {
        usbPrinters.value = printers;
        debugPrint('Found ${printers.length} USB printer(s)');
      } else {
        debugPrint('No USB printers found');
      }
    } catch (e) {
      debugPrint('USB Scan Error: $e');
      Get.snackbar(
        'USB Scan Error',
        'Failed to scan for USB printers: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUsbScanning.value = false;
    }
  }

  Future<bool> connectUsbPrinter(Printer printer) async {
    try {
      connectionStatus.value = 'Connecting to USB printer...';

      final connected = await FlutterThermalPrinter.instance.connect(printer);

      if (connected) {
        connectedUsbPrinter = printer;
        isUsbConnected.value = true;
        isConnected.value = true;
        connectionStatus.value =
            'USB Printer Connected: ${printer.name ?? "Unknown"}';

        // Save USB printer info for auto-connect
        await StorageHelper.saveUsbPrinter(printer.name ?? '');

        Get.snackbar(
          'Success',
          'USB printer connected successfully',
          snackPosition: SnackPosition.BOTTOM,
        );

        return true;
      } else {
        connectionStatus.value = 'Failed to connect USB printer';
        return false;
      }
    } catch (e) {
      debugPrint('USB Connect Error: $e');
      connectionStatus.value = 'USB connection error: $e';
      Get.snackbar(
        'Connection Error',
        'Failed to connect to USB printer: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<void> disconnectUsbPrinter() async {
    try {
      if (connectedUsbPrinter != null) {
        await FlutterThermalPrinter.instance.disconnect(connectedUsbPrinter!);
        connectedUsbPrinter = null;
        isUsbConnected.value = false;
        isConnected.value = false;
        connectionStatus.value = 'USB printer disconnected';

        Get.snackbar(
          'Disconnected',
          'USB printer disconnected',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('USB Disconnect Error: $e');
    }
  }

  // Public API - Bluetooth Connection
  Future<bool> connectToDevice(BluetoothDevice device) async {
    return await BluetoothHelper.connectToDevice(device, this);
  }

  Future<bool> ensureConnected() async {
    // Check if already connected (Bluetooth or USB)
    if (isConnected.value) {
      return true;
    }

    // 1️⃣ Check Bluetooth status
    final bluetoothEnabled = await BluetoothHelper().isBluetoothEnabled();
    debugPrint('Bluetooth enabled: $bluetoothEnabled');

    if (!bluetoothEnabled) {
      // Try USB connection as fallback
      await scanUsbPrinters();
      if (usbPrinters.isNotEmpty) {
        // Show dialog to select USB printer
        await Get.dialog(
          PrinterConnectionDialog(printerService: this),
          barrierDismissible: true,
        );
      } else {
        showError(
          title: 'No Printer Available',
          description: 'Please enable Bluetooth or connect a USB printer',
        );
        return false;
      }
    } else {
      // Show dialog to enable Bluetooth / connect printer
      await Get.dialog(
        PrinterConnectionDialog(printerService: this),
        barrierDismissible: true,
      );
    }

    // 2️⃣ Final connection status
    return isConnected.value;
  }

  Future<void> disconnect() async {
    if (isUsbConnected.value) {
      await disconnectUsbPrinter();
    } else {
      await BluetoothHelper.disconnect(this);
    }
  }

  // Public API - Auto-Connect
  Future<void> enableAutoConnect(bool enable) async {
    await StorageHelper.setAutoConnect(enable);
    if (enable && !isConnected.value) {
      await tryAutoConnect();
    }
  }

  Future<bool> isAutoConnectEnabled() => StorageHelper.isAutoConnectEnabled();
  Future<String?> getSavedDeviceName() => StorageHelper.getSavedDeviceName();
  Future<void> clearSavedDevice() => StorageHelper.clearAll();

  Future<bool> tryAutoConnect() async {
    // Try Bluetooth auto-connect first
    final bluetoothConnected = await BluetoothHelper.tryAutoConnect(this);
    if (bluetoothConnected) return true;

    // Try USB auto-connect as fallback
    final savedUsbPrinter = await StorageHelper.getSavedUsbPrinter();
    if (savedUsbPrinter != null && savedUsbPrinter.isNotEmpty) {
      await scanUsbPrinters();
      final printer = usbPrinters.firstWhereOrNull((p) => p == savedUsbPrinter);
      if (printer != null) {
        return await connectUsbPrinter(printer);
      }
    }

    return false;
  }

  String _roleKey(PrintRole role) => role == PrintRole.bill ? 'bill' : 'kot';

  Future<bool> ensureConnectedForRole(PrintRole role) async {
    // 1) If role printer saved, connect/switch to it.
    final roleKey = _roleKey(role);
    final type = await StorageHelper.getRoleLastPrinterType(roleKey);

    if (type == 'usb') {
      final savedName = await StorageHelper.getRoleSavedUsbPrinter(roleKey);
      if (savedName != null && savedName.isNotEmpty) {
        await scanUsbPrinters();
        final match = usbPrinters.firstWhereOrNull(
          (p) => (p.name ?? '') == savedName,
        );
        if (match != null) {
          if (isUsbConnected.value && connectedUsbPrinter == match) {
            return true;
          }
          await disconnect();
          return await connectUsbPrinter(match);
        }
      }
      // Fall through to interactive connect
    }

    if (type == 'bluetooth') {
      final savedId = await StorageHelper.getRoleSavedDeviceId(roleKey);
      if (savedId != null && savedId.isNotEmpty) {
        // Already connected to the right device
        if (isConnected.value &&
            connectedDevice != null &&
            connectedDevice!.remoteId.toString() == savedId) {
          return true;
        }

        // Switch to the saved device by scanning briefly for it
        try {
          await disconnect();
        } catch (_) {}

        BluetoothDevice? targetDevice;
        await FlutterBluePlus.stopScan();
        final sub = FlutterBluePlus.scanResults.listen((results) {
          for (final r in results) {
            if (r.device.remoteId.toString() == savedId) {
              targetDevice = r.device;
            }
          }
        });

        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
        await Future.delayed(const Duration(seconds: 6));
        await FlutterBluePlus.stopScan();
        await sub.cancel();

        if (targetDevice != null) {
          return await connectToDevice(targetDevice!);
        }
      }
      // Fall through to interactive connect
    }

    // 2) No role printer saved (or not found): use existing connection UI
    final ok = await ensureConnected();

    // If user connected something, and role isn't configured yet, save it as role.
    if (ok) {
      if (isUsbConnected.value && connectedUsbPrinter != null) {
        final name = connectedUsbPrinter!.name ?? '';
        if (name.isNotEmpty) {
          await StorageHelper.saveRoleUsbPrinter(
            roleKey,
            name,
            vendorId: int.tryParse('${connectedUsbPrinter!.vendorId ?? ''}'),
            productId: int.tryParse('${connectedUsbPrinter!.productId ?? ''}'),
          );
        }
      } else if (connectedDevice != null) {
        await StorageHelper.saveRoleBluetoothDevice(roleKey, connectedDevice!);
      }
    }

    return ok;
  }

  // Public API - Printing
  Future<void> printKOT({
    required String kotNumber,
    required String brandName,
    required String businessName,
    required String address,
    required String city,
    required String zipcode,
    required String state,
    required String orderFrom,
    required String tableNumber,
    required String customerName,
    required String waiterName,
    required String date,
    required String time,
    required List<OrderItem> items,
    required String specialInstructions,
    required int totalQuantity,
  }) async {
    final ok = await ensureConnectedForRole(PrintRole.kot);
    if (!ok) throw Exception('No KOT printer connected');

    final builder = PrintBuilder();

    // Header
    builder
      ..center()
      ..text('(This is an internal document\n')
      ..text('and not a BILL)\n\n');

    if (businessName.isNotEmpty) {
      builder.bold(businessName + '\n');
    }

    builder
      ..boldDoubleHeight('KOT\n')
      ..boldNormal('Kitchen Order Ticket\n')
      ..line()
      ..left();

    // Order details
    builder
      ..text('KOT No: $kotNumber\n')
      ..text('Date: $date\n')
      ..text('Time: $time\n');

    if (tableNumber.isNotEmpty) {
      builder.text('Table: $tableNumber\n');
    }

    builder
      ..text('Staff: $waiterName\n')
      ..line();

    if (orderFrom.isNotEmpty) {
      builder.center().bold('*** ${orderFrom.toUpperCase()} ***\n').left();
    }

    if (customerName.isNotEmpty) {
      builder.text('Customer: $customerName\n');
    }

    builder.line();

    // Items
    builder.bold(
      TextHelper.padRight('Item', 36) + TextHelper.padLeft('Qty', 12) + '\n',
    );
    builder.line();

    for (var item in items) {
      String itemName = item.itemName.length > 34
          ? item.itemName.substring(0, 34)
          : item.itemName;
      String qty = 'x${item.quantity}';
      builder.text(
        TextHelper.padRight(itemName, 36) + TextHelper.padLeft(qty, 12) + '\n',
      );

      if (item.category.isNotEmpty) {
        builder.text('  (${item.category})\n');
      }
    }

    builder
      ..line()
      ..bold(TextHelper.formatRow('Total Items', '$totalQuantity', 48) + '\n');

    if (specialInstructions.isNotEmpty) {
      builder
        ..line()
        ..bold('SPECIAL INSTRUCTIONS:\n')
        ..text('$specialInstructions\n');
    }

    builder
      ..center()
      ..line()
      ..text('--- End of KOT ---\n')
      ..text('Prepared by: $waiterName\n')
      ..feed(3)
      ..cut();

    await _printBytes(builder.bytes);
  }

  Future<Uint8List> generateUpiQrImage({
    required String upiId,
    required double amount,
    required String payeeName,
    required String note,
  }) async {
    final upiUri = 'upi://pay?pa=$upiId&pn=Payment&am=$amount&cu=INR&tn=$note';

    final qrPainter = QrPainter(
      data: upiUri,
      version: QrVersions.auto,
      gapless: true,
    );

    final ui.Image image = await qrPainter.toImage(200);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  Future<void> printInvoice({
    required String brandName,
    required String businessName,
    required String address,
    required String city,
    required String zipcode,
    required String state,
    String? gstinNumber,
    String? fssaiNumber,
    String? phoneNumber,
    required String orderFrom,
    required String customerName,
    required String paymentMode,
    required String date,
    required String time,
    required String invoiceNo,
    required List<OrderItem> items,
    required double subtotal,
    required double totalTax,
    required double serviceCharge,
    required double discount,
    required double totalAmount,
    bool isBluetooth = false,
    String? upiId,
  }) async {
    debugPrint('Printer is ${PrinterService2.to.isConnected.value}');

    // final ok = await ensureConnectedForRole(PrintRole.bill);
    // if (!ok) throw Exception('No bill printer connected');

    final builder = PrintBuilder();
    // Header
    builder
      ..center()
      ..boldDoubleHeight('$brandName\n')
      ..boldNormal('')
      ..text('$businessName\n')
      ..text('$address\n')
      ..text('$city, $zipcode\n')
      ..text('$state\n');

    if (gstinNumber != null) builder.text('GSTIN: $gstinNumber\n');
    if (fssaiNumber != null) builder.text('FSSAI: $fssaiNumber\n');
    if (phoneNumber != null) builder.text('Ph: $phoneNumber\n');

    builder.line()
      ..bold('INVOICE\n')
      ..line()
      ..bold('*** $orderFrom ***\n')
      ..text('\n')
      ..left();

    // Bill details (Bill To and Date on separate lines to avoid overlap with long names)
    final w = PrintBuilder.receiptWidth;
    final billToLine = 'Bill To: $customerName';
    builder.bold(
      '${billToLine.length <= w ? billToLine : billToLine.substring(0, w)}\n',
    );
    builder.bold('${TextHelper.formatRow('', 'Date: $date', w)}\n');
    builder
      ..bold(
        '${TextHelper.formatRow('Sale In: $paymentMode', 'Time: $time', w)}\n',
      )
      ..text('${TextHelper.formatRow('', 'Invoice No: $invoiceNo', w)}\n')
      ..line();

    // Items header (32 chars total for 2" / 58mm paper)
    final itemHeader =
        TextHelper.padRight('Item', 12) +
        TextHelper.padRight('Qty', 4) +
        TextHelper.padRight('Price', 8) +
        TextHelper.padLeft('Amount', 8);
    builder.bold('$itemHeader\n');

    // Items
    for (var item in items) {
      String itemName = item.itemName.length > 12
          ? item.itemName.substring(0, 12)
          : item.itemName;
      String qty = 'x${item.quantity}';
      String price = item.salePrice.toStringAsFixed(0);
      String amount = (item.quantity * item.salePrice).toStringAsFixed(2);

      String row =
          TextHelper.padRight(itemName, 12) +
          TextHelper.padRight(qty, 4) +
          TextHelper.padRight(price, 8) +
          TextHelper.padLeft(amount, 8);
      builder.text('$row\n');
    }

    builder
      ..line()
      ..text(
        '${TextHelper.formatRow('Subtotal', 'Rs${subtotal.toStringAsFixed(2)}', w)}\n',
      );

    if (totalTax > 0) {
      builder.text(
        '${TextHelper.formatRow('Tax (GST)', 'Rs${totalTax.toStringAsFixed(2)}', w)}\n',
      );
    }
    if (serviceCharge > 0) {
      builder.text(
        '${TextHelper.formatRow('Service Charge', 'Rs${serviceCharge.toStringAsFixed(2)}', w)}\n',
      );
    }
    if (discount > 0) {
      builder.text(
        '${TextHelper.formatRow('Discount', '-Rs${discount.toStringAsFixed(2)}', w)}\n',
      );
    }

    builder
      ..line()
      ..boldDoubleHeight(
        '${TextHelper.formatRow('TOTAL', 'Rs${totalAmount.toStringAsFixed(2)}', w)}\n',
      )
      ..boldNormal('')
      ..line()
      ..center()
      ..text('\n')
      ..bold('Terms & Conditions\n')
      ..text('Thank you for doing\n')
      ..text('business with us.\n');

    // UPI QR Code (only if setting enabled)
    final appPref = Get.find<AppPref>();
    if (appPref.showQrOnBill && (upiId?.trim().isNotEmpty ?? false)) {
      builder
        ..text('\n')
        ..bold('Scan to Pay\n')
        ..text('\n');

      String transactionNote = 'Invoice: $invoiceNo';
      List<int> qrCode = await QRGenerator.generate(
        upiId!.trim(),
        totalAmount,
        businessName,
        transactionNote,
      );

      if (qrCode.isEmpty) {
        qrCode = await QRGenerator.generateBitmap(
          upiId.trim(),
          totalAmount,
          businessName,
          transactionNote,
        );
      }

      if (qrCode.isNotEmpty) {
        builder.bytes.addAll(qrCode);
        builder.text('\n');
      }
      builder.feed(3).cut();

      builder
        ..text('UPI ID: $upiId\n')
        ..text('Amount: ₹${totalAmount.toStringAsFixed(2)}\n');
    }

    builder.feed(3).cut();
    await _printBytes(builder.bytes);
  }

  // Private helper - Universal print method for both Bluetooth and USB
  Future<void> _printBytes(List<int> bytes) async {
    try {
      if (isUsbConnected.value && connectedUsbPrinter != null) {
        await FlutterThermalPrinter.instance.printData(
          connectedUsbPrinter!,
          Uint8List.fromList(bytes),
          longData: true,
        );
        return;
      }

      await _writeBluetoothBytes(bytes);
    } catch (e) {
      debugPrint('Print error: $e');
      rethrow;
    }
  }

  // Private helper - Bluetooth specific write
  Future<void> _writeBluetoothBytes(List<int> bytes) async {
    final printerservice2 = PrinterService2.to;
    if (!printerservice2.isConnected.value) {
      throw Exception('No Bluetooth printer connected');
    }

    printerservice2.connection!.output.add(Uint8List.fromList(bytes));
    await printerservice2.connection!.output.allSent;
  }

  Future<void> _initAutoConnect() async {
    final autoConnectEnabled = await StorageHelper.isAutoConnectEnabled();
    if (autoConnectEnabled) await tryAutoConnect();
  }

  // Utility method to show error dialogs
  void showError({required String title, required String description}) {
    Get.snackbar(
      title,
      description,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
      colorText: Get.theme.colorScheme.onError,
    );
  }
}
