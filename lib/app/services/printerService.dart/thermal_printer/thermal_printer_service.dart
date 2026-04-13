import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:billkaro/app/services/PrinterService2/printer_service2.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/printer_dialog_widget.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart' hide Printer;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:billkaro/utils/app_snackbar.dart';
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
    // FlutterBluePlus on Windows uses WinRT; startup listeners / auto-scan have
    // triggered native `abort()` in debug builds on some setups. USB thermal
    // printing does not need BLE here.
    if (kIsWeb || Platform.isWindows) {
      debugPrint(
        'ℹ️ [ThermalPrinter] Skipping BLE listener/auto-connect on '
        '${kIsWeb ? "web" : "Windows"}',
      );
      return;
    }
    BluetoothHelper.listenToConnectionState(this);
    _initAutoConnect();
  }

  bool _shouldAutoConnectPrinter() {
    if (!Get.isRegistered<AppPref>()) return false;
    return Get.find<AppPref>().isLogin;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  // Public API - Permissions
  Future<void> requestPermissions() async {
    // `permission_handler` only meaningfully applies on mobile platforms.
    // On desktop (Windows/macOS/Linux) these permissions are not used and can
    // cause confusing failures or no-ops.
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.location.request();
      return;
    }
    if (Platform.isIOS) {
      // iOS does not use the Android 12+ Bluetooth permissions; scanning is gated
      // by system prompts/Info.plist.
      return;
    }
  }

  // Public API - Bluetooth Scanning
  Future<void> startScan() async {
    if (kIsWeb || Platform.isWindows) {
      debugPrint('ℹ️ [ThermalPrinter] BLE scan not available on this platform');
      isScanning.value = false;
      return;
    }
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
    if (kIsWeb || Platform.isWindows) {
      isScanning.value = false;
      return;
    }
    await FlutterBluePlus.stopScan();
    isScanning.value = false;
  }

  // Public API - USB Scanning and Connection
  List<Printer> printers = [];
  StreamSubscription<List<Printer>>? _devicesStreamSubscription;

  Future<void> checkForUsbPermission() async {
    // USB printer discovery does not require storage permission on desktop.
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  Future<void> scanUsbPrinters() async {
    try {
      await checkForUsbPermission();
      _devicesStreamSubscription?.cancel();
      isUsbScanning.value = true;
      usbPrinters.clear();

      // Trigger discovery
      await FlutterThermalPrinter.instance.getPrinters(
        connectionTypes: [ConnectionType.USB],
      );

      // IMPORTANT:
      // The plugin reports devices asynchronously via `devicesStream`.
      // The previous implementation checked `printers` immediately (still empty),
      // so it often showed "No USB printers found" even when devices existed.
      List<Printer> discovered = const [];
      try {
        discovered = await FlutterThermalPrinter.instance.devicesStream.first
            .timeout(const Duration(seconds: 4));
      } on TimeoutException {
        discovered = const [];
      }

      printers = discovered.toList();
      printers.removeWhere((p) => (p.name ?? '').trim().isEmpty);

      // Some Windows USB printers report generic names; don't aggressively filter.
      usbPrinters.assignAll(printers);
      debugPrint('Found ${usbPrinters.length} USB printer(s)');

      // Keep subscription to reflect late-arriving devices (optional but useful)
      _devicesStreamSubscription = FlutterThermalPrinter.instance.devicesStream
          .listen((List<Printer> event) {
            final list = event.toList()
              ..removeWhere((p) => (p.name ?? '').trim().isEmpty);
            usbPrinters.assignAll(list);
          });
    } catch (e) {
      debugPrint('USB Scan Error: $e');
      AppSnackbar.show(
        title: 'USB Scan Error',
        message: 'Failed to scan for USB printers: $e',
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

        return true;
      } else {
        connectionStatus.value = 'Failed to connect USB printer';
        return false;
      }
    } catch (e) {
      debugPrint('USB Connect Error: $e');
      connectionStatus.value = 'USB connection error: $e';
      AppSnackbar.show(
        title: 'Connection Error',
        message: 'Failed to connect to USB printer: $e',
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

        AppSnackbar.show(
          title: 'Disconnected',
          message: 'USB printer disconnected',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('USB Disconnect Error: $e');
    }
  }

  // Public API - Bluetooth Connection
  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (kIsWeb || Platform.isWindows) return false;
    return await BluetoothHelper.connectToDevice(device, this);
  }

  Future<bool> ensureConnected() async {
    // Check if already connected (Bluetooth or USB)
    if (isConnected.value) {
      return true;
    }

    // Windows: BLE stack is not registered; use USB only.
    if (!kIsWeb && Platform.isWindows) {
      await scanUsbPrinters();
      if (usbPrinters.isNotEmpty) {
        await Get.dialog(
          PrinterConnectionDialog(printerService: this),
          barrierDismissible: true,
        );
      } else {
        showError(
          title: 'No USB printer',
          description: 'Connect a USB thermal printer and use the USB tab.',
        );
      }
      return isConnected.value;
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
    if (enable && !isConnected.value && _shouldAutoConnectPrinter()) {
      await tryAutoConnect();
    }
  }

  Future<bool> isAutoConnectEnabled() => StorageHelper.isAutoConnectEnabled();
  Future<String?> getSavedDeviceName() => StorageHelper.getSavedDeviceName();
  Future<void> clearSavedDevice() => StorageHelper.clearAll();

  Future<bool> tryAutoConnect() async {
    if (!_shouldAutoConnectPrinter()) return false;
    if (isConnected.value) return true;
    // Try Bluetooth auto-connect first
    final bluetoothConnected = await BluetoothHelper.tryAutoConnect(this);
    if (bluetoothConnected) return true;

    // Try USB auto-connect as fallback
    final savedUsbPrinter = await StorageHelper.getSavedUsbPrinter();
    if (savedUsbPrinter != null && savedUsbPrinter.isNotEmpty) {
      await scanUsbPrinters();
      final printer = usbPrinters.firstWhereOrNull(
        (p) => (p.name ?? '') == savedUsbPrinter,
      );
      if (printer != null) {
        return await connectUsbPrinter(printer);
      }
    }

    return false;
  }

  String _roleKey(PrintRole role) => role == PrintRole.bill ? 'bill' : 'kot';

  int _detectReceiptWidth() {
    // Prefer best-effort inference from connected device/printer name.
    final name =
        (connectedUsbPrinter?.name ??
                connectedDevice?.platformName ??
                connectedDevice?.advName ??
                '')
            .toLowerCase();

    // Heuristics: many models advertise 80/58 or 3inch/2inch in the name.
    if (name.contains('80') ||
        name.contains('3 inch') ||
        name.contains('3inch') ||
        name.contains('80mm')) {
      return 48;
    }
    if (name.contains('58') ||
        name.contains('2 inch') ||
        name.contains('2inch') ||
        name.contains('58mm')) {
      return 32;
    }

    // Default to 32 for safety (less clipping).
    return 32;
  }

  ({int w, int item, int qty, int price, int amount}) _invoiceColumns(int w) {
    if (w >= 48) {
      // 80mm
      return (w: w, item: 24, qty: 6, price: 8, amount: 10);
    }
    // 58mm
    return (w: w, item: 12, qty: 4, price: 8, amount: 8);
  }

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
      if (!kIsWeb && Platform.isWindows) {
        // BLE not available on Windows desktop build; fall through to dialog.
      } else {
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
    // Windows default: use OS print dialog (PDF).
    // BUT if a BLE printer is connected (writeCharacteristic available), send raw ESC/POS bytes.
    final hasBlePrinter =
        isConnected.value &&
        connectedDevice != null &&
        writeCharacteristic != null;
    if (!kIsWeb && Platform.isWindows && !hasBlePrinter) {
      await _printKotWindowsPdf(
        kotNumber: kotNumber,
        businessName: businessName,
        orderFrom: orderFrom,
        tableNumber: tableNumber,
        customerName: customerName,
        waiterName: waiterName,
        date: date,
        time: time,
        items: items,
        specialInstructions: specialInstructions,
        totalQuantity: totalQuantity,
      );
      return;
    }

    final ok = await ensureConnectedForRole(PrintRole.kot);
    if (!ok) throw Exception('No KOT printer connected');

    final receiptW = _detectReceiptWidth();
    final builder = PrintBuilder(receiptWidth: receiptW);

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
    if (receiptW >= 48) {
      builder.bold(
        TextHelper.padRight('Item', 36) + TextHelper.padLeft('Qty', 12) + '\n',
      );
    } else {
      builder.bold(
        TextHelper.padRight('Item', 20) + TextHelper.padLeft('Qty', 12) + '\n',
      );
    }
    builder.line();

    for (var item in items) {
      final itemMax = receiptW >= 48 ? 34 : 20;
      String itemName = item.itemName.length > itemMax
          ? item.itemName.substring(0, itemMax)
          : item.itemName;
      String qty = 'x${item.quantity}';
      builder.text(
        (receiptW >= 48
                ? TextHelper.padRight(itemName, 36)
                : TextHelper.padRight(itemName, 20)) +
            TextHelper.padLeft(qty, 12) +
            '\n',
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
    // Windows default: use OS print dialog (PDF).
    // BUT if a BLE printer is connected (writeCharacteristic available), send raw ESC/POS bytes.
    final hasBlePrinter =
        isConnected.value &&
        connectedDevice != null &&
        writeCharacteristic != null;
    if (!kIsWeb && Platform.isWindows && !hasBlePrinter) {
      await _printInvoiceWindowsPdf(
        brandName: brandName,
        businessName: businessName,
        address: address,
        city: city,
        zipcode: zipcode,
        state: state,
        gstinNumber: gstinNumber,
        fssaiNumber: fssaiNumber,
        phoneNumber: phoneNumber,
        orderFrom: orderFrom,
        customerName: customerName,
        paymentMode: paymentMode,
        date: date,
        time: time,
        invoiceNo: invoiceNo,
        items: items,
        subtotal: subtotal,
        totalTax: totalTax,
        serviceCharge: serviceCharge,
        discount: discount,
        totalAmount: totalAmount,
        upiId: upiId,
      );
      return;
    }

    debugPrint('Printer is ${PrinterService2.to.isConnected.value}');

    // final ok = await ensureConnectedForRole(PrintRole.bill);
    // if (!ok) throw Exception('No bill printer connected');

    final receiptW = _detectReceiptWidth();
    final cols = _invoiceColumns(receiptW);
    final builder = PrintBuilder(receiptWidth: receiptW);
    // Header
    builder
      ..center()
      ..boldDoubleHeight('$brandName\n')
      ..boldNormal('')
      ..text('$businessName\n')
      ..text('$address\n');

    final gst = (gstinNumber ?? '').trim();
    final fssai = (fssaiNumber ?? '').trim();
    final phone = (phoneNumber ?? '').trim();

    if (gst.isNotEmpty) builder.text('GSTIN: $gst\n');
    if (fssai.isNotEmpty) builder.text('FSSAI: $fssai\n');
    if (phone.isNotEmpty) builder.text('Ph: $phone\n');

    builder.line()
      ..bold('INVOICE\n')
      ..line()
      ..bold('*** $orderFrom ***\n')
      ..text('\n')
      ..left();

    // Bill details (Bill To and Date on separate lines to avoid overlap with long names)
    final w = cols.w;
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
        TextHelper.padRight('Item', cols.item) +
        TextHelper.padRight('Qty', cols.qty) +
        TextHelper.padRight('Price', cols.price) +
        TextHelper.padLeft('Amount', cols.amount);
    builder.bold('$itemHeader\n');

    // Items
    for (var item in items) {
      String itemName = item.itemName.length > cols.item
          ? item.itemName.substring(0, cols.item)
          : item.itemName;
      String qty = 'x${item.quantity}';
      String price = item.salePrice.toStringAsFixed(0);
      String amount = (item.quantity * item.salePrice).toStringAsFixed(2);

      String row =
          TextHelper.padRight(itemName, cols.item) +
          TextHelper.padRight(qty, cols.qty) +
          TextHelper.padRight(price, cols.price) +
          TextHelper.padLeft(amount, cols.amount);
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

  Future<void> _printInvoiceWindowsPdf({
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
    String? upiId,
  }) async {
    final doc = pw.Document();

    // IMPORTANT:
    // `pdf` requires a finite page height for `pw.MultiPage`.
    // Use a receipt-like width with a standard finite height; MultiPage will
    // paginate automatically for longer receipts.
    // Many Windows thermal printer drivers have non‑printable margins.
    // If we render at full 80mm width, right-aligned text can get clipped.
    // Use a slightly narrower effective page width + smaller margins.
    final pageFormat = PdfPageFormat(
      76 * PdfPageFormat.mm,
      297 * PdfPageFormat.mm, // finite height; MultiPage paginates
      marginAll: 4 * PdfPageFormat.mm,
    );

    pw.TextStyle t({double s = 9, bool b = false}) =>
        pw.TextStyle(fontSize: s, fontWeight: b ? pw.FontWeight.bold : null);

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        build: (_) => [
          pw.Center(child: pw.Text(brandName, style: t(s: 13, b: true))),
          if (businessName.isNotEmpty)
            pw.Center(child: pw.Text(businessName, style: t(b: true))),
          if (address.isNotEmpty)
            pw.Center(child: pw.Text(address, style: t())),
          // pw.Center(child: pw.Text('$city, $zipcode', style: t())),
          // pw.Center(child: pw.Text(state, style: t())),
          if ((gstinNumber ?? '').trim().isNotEmpty)
            pw.Center(
              child: pw.Text('GSTIN: ${gstinNumber!.trim()}', style: t()),
            ),
          if ((fssaiNumber ?? '').trim().isNotEmpty)
            pw.Center(
              child: pw.Text('FSSAI: ${fssaiNumber!.trim()}', style: t()),
            ),
          if ((phoneNumber ?? '').trim().isNotEmpty)
            pw.Center(child: pw.Text('Ph: ${phoneNumber!.trim()}', style: t())),
          pw.SizedBox(height: 6),
          pw.Divider(),
          pw.Center(child: pw.Text('INVOICE', style: t(b: true))),
          pw.Center(child: pw.Text(orderFrom, style: t(b: true))),
          pw.Divider(),
          pw.Text('Bill To: $customerName', style: t(b: true)),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Payment: $paymentMode', style: t()),
              pw.Text('Date: $date', style: t()),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Invoice: $invoiceNo', style: t()),
              pw.Text('Time: $time', style: t()),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            // Give right-side numbers more space to avoid clipping.
            columnWidths: const {
              0: pw.FlexColumnWidth(6.5), // Item
              1: pw.FlexColumnWidth(1.5), // Qty
              2: pw.FlexColumnWidth(2.0), // Price
              3: pw.FlexColumnWidth(2.0), // Amount
            },
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(
                width: 0.4,
                color: PdfColors.grey,
              ),
              top: pw.BorderSide(width: 0.6),
              bottom: pw.BorderSide(width: 0.6),
            ),
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text('Item', style: t(b: true)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Align(
                      alignment: pw.Alignment.center,
                      child: pw.Text('Qty', style: t(b: true)),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text('Price', style: t(b: true)),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text('Amt', style: t(b: true)),
                    ),
                  ),
                ],
              ),
              ...items.map((it) {
                final qty = it.quantity;
                final price = it.salePrice;
                final amt = qty * price;
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Text(it.itemName, style: t()),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Align(
                        alignment: pw.Alignment.center,
                        child: pw.Text('x$qty', style: t()),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(price.toStringAsFixed(2), style: t()),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(amt.toStringAsFixed(2), style: t()),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(),
          _totRow('Subtotal', subtotal, t),
          if (totalTax > 0) _totRow('Tax (GST)', totalTax, t),
          if (serviceCharge > 0) _totRow('Service Charge', serviceCharge, t),
          if (discount > 0) _totRow('Discount', -discount, t),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL', style: t(s: 11, b: true)),
              pw.Text(totalAmount.toStringAsFixed(2), style: t(s: 11, b: true)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text('Thank you for doing business with us.', style: t()),
          ),
          if ((upiId ?? '').trim().isNotEmpty)
            pw.Center(child: pw.Text('UPI: ${upiId!.trim()}', style: t(s: 8))),
        ],
      ),
    );

    // If UPI is present, generate QR bytes before final layout and inject a page
    // overlay by rebuilding doc content with the QR image.
    if ((upiId ?? '').trim().isNotEmpty) {
      try {
        final qrBytes = await generateUpiQrImage(
          upiId: upiId!.trim(),
          amount: totalAmount,
          payeeName: businessName.isNotEmpty ? businessName : 'Payment',
          note: 'Invoice: $invoiceNo',
        );

        final withQr = pw.Document();
        withQr.addPage(
          pw.MultiPage(
            pageFormat: pageFormat,
            build: (_) => [
              pw.Center(child: pw.Text(brandName, style: t(s: 13, b: true))),
              if (businessName.isNotEmpty)
                pw.Center(child: pw.Text(businessName, style: t(b: true))),
              if (address.isNotEmpty)
                pw.Center(child: pw.Text(address, style: t())),
              if ((gstinNumber ?? '').trim().isNotEmpty)
                pw.Center(
                  child: pw.Text('GSTIN: ${gstinNumber!.trim()}', style: t()),
                ),
              if ((fssaiNumber ?? '').trim().isNotEmpty)
                pw.Center(
                  child: pw.Text('FSSAI: ${fssaiNumber!.trim()}', style: t()),
                ),
              if ((phoneNumber ?? '').trim().isNotEmpty)
                pw.Center(
                  child: pw.Text('Ph: ${phoneNumber!.trim()}', style: t()),
                ),
              pw.SizedBox(height: 6),
              pw.Divider(),
              pw.Center(child: pw.Text('INVOICE', style: t(b: true))),
              pw.Center(child: pw.Text(orderFrom, style: t(b: true))),
              pw.Divider(),
              pw.Text('Bill To: $customerName', style: t(b: true)),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Payment: $paymentMode', style: t()),
                  pw.Text('Date: $date', style: t()),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Invoice: $invoiceNo', style: t()),
                  pw.Text('Time: $time', style: t()),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(6),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2),
                },
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(
                    width: 0.4,
                    color: PdfColors.grey,
                  ),
                  top: pw.BorderSide(width: 0.6),
                  bottom: pw.BorderSide(width: 0.6),
                ),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Text('Item', style: t(b: true)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Align(
                          alignment: pw.Alignment.center,
                          child: pw.Text('Qty', style: t(b: true)),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text('Price', style: t(b: true)),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text('Amt', style: t(b: true)),
                        ),
                      ),
                    ],
                  ),
                  ...items.map((it) {
                    final qty = it.quantity;
                    final price = it.salePrice;
                    final amt = qty * price;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 3),
                          child: pw.Text(it.itemName, style: t()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 3),
                          child: pw.Align(
                            alignment: pw.Alignment.center,
                            child: pw.Text('x$qty', style: t()),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 3),
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              price.toStringAsFixed(2),
                              style: t(),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 3),
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(amt.toStringAsFixed(2), style: t()),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(),
              _totRow('Subtotal', subtotal, t),
              if (totalTax > 0) _totRow('Tax (GST)', totalTax, t),
              if (serviceCharge > 0)
                _totRow('Service Charge', serviceCharge, t),
              if (discount > 0) _totRow('Discount', -discount, t),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: t(s: 11, b: true)),
                  pw.Text(
                    totalAmount.toStringAsFixed(2),
                    style: t(s: 11, b: true),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Thank you for doing business with us.',
                  style: t(),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text('Scan to Pay', style: t(b: true))),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Image(pw.MemoryImage(qrBytes), width: 90, height: 90),
              ),
              pw.SizedBox(height: 6),
              pw.Center(child: pw.Text('UPI: ${upiId.trim()}', style: t(s: 8))),
            ],
          ),
        );

        await Printing.layoutPdf(onLayout: (_) async => withQr.save());
        return;
      } catch (e) {
        debugPrint('⚠️ Failed to render UPI QR in PDF: $e');
      }
    }

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  pw.Widget _totRow(
    String label,
    double value,
    pw.TextStyle Function({double s, bool b}) t,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: t()),
        pw.Text(value.toStringAsFixed(2), style: t()),
      ],
    );
  }

  Future<void> _printKotWindowsPdf({
    required String kotNumber,
    required String businessName,
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
    final doc = pw.Document();
    final pageFormat = PdfPageFormat(
      76 * PdfPageFormat.mm,
      297 * PdfPageFormat.mm, // finite height; MultiPage paginates if needed
      marginAll: 4 * PdfPageFormat.mm,
    );

    pw.TextStyle t({double s = 9, bool b = false}) =>
        pw.TextStyle(fontSize: s, fontWeight: b ? pw.FontWeight.bold : null);

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        build: (_) => [
          pw.Center(child: pw.Text('KOT', style: t(s: 14, b: true))),
          if (businessName.isNotEmpty)
            pw.Center(child: pw.Text(businessName, style: t(b: true))),
          pw.Divider(),
          pw.Text('KOT No: $kotNumber', style: t(b: true)),
          pw.Text('Date: $date', style: t()),
          pw.Text('Time: $time', style: t()),
          if (tableNumber.isNotEmpty)
            pw.Text('Table: $tableNumber', style: t()),
          if (waiterName.isNotEmpty) pw.Text('Staff: $waiterName', style: t()),
          if (orderFrom.isNotEmpty)
            pw.Center(
              child: pw.Text(orderFrom.toUpperCase(), style: t(b: true)),
            ),
          if (customerName.isNotEmpty)
            pw.Text('Customer: $customerName', style: t()),
          pw.Divider(),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(8),
              1: pw.FlexColumnWidth(4),
            },
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(
                width: 0.4,
                color: PdfColors.grey,
              ),
              top: pw.BorderSide(width: 0.6),
              bottom: pw.BorderSide(width: 0.6),
            ),
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text('Item', style: t(b: true)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text('Qty', style: t(b: true)),
                    ),
                  ),
                ],
              ),
              ...items.map(
                (it) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Text(it.itemName, style: t()),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text('x${it.quantity}', style: t()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Items', style: t(b: true)),
              pw.Text('$totalQuantity', style: t(b: true)),
            ],
          ),
          if (specialInstructions.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Divider(),
            pw.Text('SPECIAL INSTRUCTIONS', style: t(b: true)),
            pw.Text(specialInstructions, style: t()),
          ],
          pw.SizedBox(height: 10),
          pw.Center(child: pw.Text('--- End of KOT ---', style: t())),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
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
    // BLE path (Windows/macOS/Linux + Android BLE)
    final dev = connectedDevice;
    final ch = writeCharacteristic;
    if (isConnected.value && dev != null && ch != null) {
      final withoutResponse = ch.properties.writeWithoutResponse;

      // Keep chunks conservative for broad BLE printer compatibility.
      const int chunkSize = 180;
      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize < bytes.length)
            ? i + chunkSize
            : bytes.length;
        final chunk = bytes.sublist(i, end);
        await ch.write(chunk, withoutResponse: withoutResponse);
      }
      return;
    }

    // Classic BT / legacy path (Android)
    final printerservice2 = PrinterService2.to;
    if (!printerservice2.isConnected.value) {
      throw Exception('No Bluetooth printer connected');
    }
    await printerservice2.sendBytes(bytes);
  }

  Future<void> _initAutoConnect() async {
    if (!_shouldAutoConnectPrinter()) return;
    final autoConnectEnabled = await StorageHelper.isAutoConnectEnabled();
    if (autoConnectEnabled) await tryAutoConnect();
  }

  // Utility method to show error dialogs
  void showError({required String title, required String description}) {
    AppSnackbar.show(
      title: title,
      message: description,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
      colorText: Get.theme.colorScheme.onError,
    );
  }
}
