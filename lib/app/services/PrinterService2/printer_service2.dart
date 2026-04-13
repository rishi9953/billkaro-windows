import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';

class PrinterService2 extends GetxService {
  static PrinterService2 get to => Get.find();

  final FlutterBluetoothClassic _bluetooth = FlutterBluetoothClassic();

  /// 🔁 Reactive selected printer
  final Rx<BluetoothDevice?> selectedPrinter = Rx<BluetoothDevice?>(null);

  /// 📡 Scanned / paired devices
  final RxList<BluetoothDevice> availableDevices = <BluetoothDevice>[].obs;

  final isConnected = false.obs;
  final isConnecting = false.obs;
  final isScanning = false.obs;

  bool _pluginAvailable = true;

  // `flutter_bluetooth_classic_serial` exposes Android (Classic BT/SPP) APIs.
  // On desktop platforms (Windows/macOS/Linux) it won’t have a native
  // implementation, so calling it throws MissingPluginException.
  bool get _bluetoothSupported =>
      !kIsWeb && _pluginAvailable && Platform.isAndroid;

  /// 🔥 INIT SERVICE (call once at app start)
  Future<PrinterService2> init() async {
    if (!_bluetoothSupported) {
      debugPrint(
        'ℹ️ [PRINTER] Bluetooth printing not supported on this platform.',
      );
      return this;
    }

    try {
      final supported = await _bluetooth.isBluetoothSupported();
      if (!supported) {
        debugPrint('⚠️ [PRINTER] Bluetooth adapter not supported.');
        return this;
      }

      final enabled = await _bluetooth.isBluetoothEnabled();
      if (!enabled) {
        await _enableBluetooth();
      }
    } catch (e) {
      if (e is MissingPluginException) {
        _pluginAvailable = false;
        debugPrint(
          '⚠️ [PRINTER] Bluetooth plugin not registered (MissingPluginException). '
          'On Windows, you must do a full rebuild after adding the plugin.',
        );
        return this;
      }
      debugPrint('⚠️ [PRINTER] Failed to enable Bluetooth: $e');
      // Continue without Bluetooth
    }
    
    try {
      await _autoConnectPrinter();
    } catch (e) {
      if (e is MissingPluginException) {
        _pluginAvailable = false;
        debugPrint(
          '⚠️ [PRINTER] Bluetooth plugin not registered (MissingPluginException). '
          'Skipping auto-connect.',
        );
        return this;
      }
      debugPrint('⚠️ [PRINTER] Failed to auto-connect printer: $e');
      // Continue without auto-connect
    }
    
    return this;
  }

  /// Enable bluetooth
  Future<void> _enableBluetooth() async {
    if (!_bluetoothSupported) return;
    await _bluetooth.enableBluetooth();
  }

  /// Auto detect printer
  BluetoothDevice? _findPrinter(List<BluetoothDevice> devices) {
    for (final d in devices) {
      final name = d.name.toLowerCase();
      if (name.contains('printer') ||
          name.contains('pos') ||
          name.contains('thermal') ||
          name.contains('inner')) {
        return d;
      }
    }
    return null;
  }

  /// Auto connect printer
  Future<void> _autoConnectPrinter() async {
    if (!_bluetoothSupported) return;
    if (isConnected.value || isConnecting.value) return;

    final bonded = await _bluetooth.getPairedDevices();
    final printer = _findPrinter(bonded);

    if (printer != null) {
      await connect(printer);
    }
  }

  /// Manual connect
  Future<void> connect(BluetoothDevice device) async {
    if (!_bluetoothSupported) {
      debugPrint(
        '⚠️ [PRINTER] Bluetooth connect not supported on this platform.',
      );
      return;
    }
    if (isConnecting.value) return;

    isConnecting.value = true;

    try {
      // If we're already connected to some device, disconnect first to avoid
      // stale sockets / "already connected" failures (common on Windows).
      if (isConnected.value) {
        try {
          await _bluetooth.disconnect();
        } catch (_) {}
        selectedPrinter.value = null;
        isConnected.value = false;
      }

      final ok = await _bluetooth.connect(device.address);
      selectedPrinter.value = device;
      isConnected.value = ok;
      if (!ok) {
        selectedPrinter.value = null;
      }
    } catch (e) {
      isConnected.value = false;
      selectedPrinter.value = null;
    } finally {
      isConnecting.value = false;
    }
  }

  /// 🔍 SCAN FOR DEVICES (PAIRED)
  Future<void> scanForDevices() async {
    if (!_bluetoothSupported) {
      availableDevices.clear();
      debugPrint(
        'ℹ️ [PRINTER] Bluetooth scan not supported on this platform.',
      );
      return;
    }
    if (isScanning.value) return;

    isScanning.value = true;
    try {
      final devices = await _bluetooth.getPairedDevices();
      availableDevices.assignAll(devices);
    } catch (e) {
      if (e is MissingPluginException) {
        _pluginAvailable = false;
        availableDevices.clear();
        debugPrint(
          '⚠️ [PRINTER] Bluetooth plugin not registered (MissingPluginException).',
        );
        return;
      }
      availableDevices.clear();
    } finally {
      isScanning.value = false;
    }
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
    PaperSize paperSize = PaperSize.mm80, // Add paperSize parameter
  }) async {
    if (!isConnected.value) {
      await _autoConnectPrinter();
      if (!isConnected.value) return;
    }

    final profile = await CapabilityProfile.load();
    final gen = Generator(paperSize, profile, spaceBetweenRows: 2);

    List<int> bytes = [];

    // Determine column widths based on paper size
    final bool isLargePaper = paperSize == PaperSize.mm80 ? false : true;

    // Column widths for different sections - using 12-column grid system
    // Total must equal 12: Item Name(6) + Qty(2) + Price(2) + Amount(2) = 12
    final int itemNameWidth = 6;
    final int qtyWidth = 2;
    final int priceWidth = 2;
    final int amountWidth = 2;

    final int labelWidth = isLargePaper ? 10 : 8;
    final int valueWidth = isLargePaper ? 10 : 4;

    bytes += gen.reset();

    /// 🔹 HEADER - Phone number at top (left-aligned)
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      bytes += gen.text(
        'Phone: $phoneNumber',
        styles: const PosStyles(align: PosAlign.left),
      );
    }

    bytes += gen.hr();

    /// 🧾 INVOICE TITLE
    bytes += gen.text(
      'Tax Invoice',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      ),
    );

    bytes += gen.hr();

    /// 📄 SALE DETAILS - Order type left, date/time/invoice right-aligned
    bytes += gen.row([
      PosColumn(
        text: orderFrom,
        width: 6,
        styles: const PosStyles(align: PosAlign.left),
      ),
      PosColumn(
        text: 'Date: $date',
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += gen.row([
      PosColumn(text: '', width: 6),
      PosColumn(
        text: 'Time: $time',
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += gen.row([
      PosColumn(text: '', width: 6),
      PosColumn(
        text: 'Invoice no: $invoiceNo',
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += gen.hr();

    /// 🛒 TABLE HEADER - Ensured single line with proper column widths
    bytes += gen.row([
      PosColumn(
        text: 'Item Name',
        width: itemNameWidth,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: 'Qty',
        width: qtyWidth,
        styles: const PosStyles(bold: true, align: PosAlign.center),
      ),
      PosColumn(
        text: 'Price',
        width: priceWidth,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
      PosColumn(
        text: 'Amount',
        width: amountWidth,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);

    bytes += gen.hr();

    /// 📦 ITEMS - Item name on first line, quantity on second line below it
    for (final item in items) {
      // First line: Item name (left) | Price (right) | Amount (right)
      bytes += gen.row([
        PosColumn(text: item.itemName, width: itemNameWidth),
        PosColumn(text: '', width: qtyWidth), // Empty space for Qty column
        PosColumn(
          text: item.salePrice.toStringAsFixed(2),
          width: priceWidth,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: (item.salePrice * item.quantity).toStringAsFixed(2),
          width: amountWidth,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      // Second line: Quantity (left-aligned below item name)
      bytes += gen.row([
        PosColumn(
          text: 'x${item.quantity}',
          width: itemNameWidth,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(text: '', width: qtyWidth),
        PosColumn(text: '', width: priceWidth),
        PosColumn(text: '', width: amountWidth),
      ]);
    }

    bytes += gen.hr();

    /// 💰 TOTALS - Format: "Subtotal:" and "Total:" with colons, no currency symbol
    bytes += gen.row([
      PosColumn(text: 'Subtotal:', width: labelWidth),
      PosColumn(
        text: subtotal.toStringAsFixed(2),
        width: valueWidth,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += gen.row([
      PosColumn(
        text: 'Total:',
        width: labelWidth,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: totalAmount.toStringAsFixed(2),
        width: valueWidth,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);

    bytes += gen.hr();

    /// 📜 FOOTER
    bytes += gen.text(
      'Terms & Conditions',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += gen.text(
      'Thank you for doing business with us.',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += gen.feed(3);
    bytes += gen.cut();

    await sendBytes(bytes);
  }

  Future<void> sendBytes(List<int> bytes) async {
    if (!_bluetoothSupported) {
      throw Exception('Bluetooth not supported on this platform');
    }
    if (!isConnected.value) {
      throw Exception('No Bluetooth printer connected');
    }
    try {
      await _bluetooth.sendData(Uint8List.fromList(bytes));
    } on MissingPluginException {
      _pluginAvailable = false;
      throw Exception(
        'Bluetooth plugin not registered. Please do a full rebuild.',
      );
    }
  }

  /// Disconnect
  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
    } catch (_) {}
    selectedPrinter.value = null;
    isConnected.value = false;
  }
}
