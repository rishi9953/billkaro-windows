import 'dart:typed_data';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum PrinterType { bluetooth, network, usb }

class PrinterService {
  final _thermalPrinter = FlutterThermalPrinter.instance;

  Printer? _connectedPrinter;

  /// Check and request permissions
  Future<bool> checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  /// Get list of available printers (Bluetooth, USB, Network)
  Future<void> getPrinters({
    List<ConnectionType> connectionTypes = const [
      ConnectionType.BLE,
      ConnectionType.USB,
    ],
  }) async {
    try {
      await checkPermissions();
      final printers = await _thermalPrinter.getPrinters(
        connectionTypes: connectionTypes,
      );
      return printers;
    } catch (e) {
      print('Error getting printers: $e');
      return;
    }
  }

  /// Connect to printer
  Future<bool> connect(Printer printer) async {
    try {
      final result = await _thermalPrinter.connect(printer);
      if (result == true) {
        _connectedPrinter = printer;
        return true;
      }
      return false;
    } catch (e) {
      print('Error connecting: $e');
      return false;
    }
  }

  /// Disconnect printer
  Future<void> disconnect() async {
    try {
      if (_connectedPrinter != null) {
        await _thermalPrinter.disconnect(_connectedPrinter!);
        _connectedPrinter = null;
      }
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  /// Check if printer is connected
  bool get isConnected => _connectedPrinter != null;

  /// Get connected printer
  Printer? get connectedPrinter => _connectedPrinter;

  /// Print bill
  Future<bool> printBill(BillData bill) async {
    try {
      if (_connectedPrinter == null) {
        print('No printer connected');
        return false;
      }

      // Generate receipt bytes
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      // Header
      bytes += generator.text(
        bill.storeName,
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );

      bytes += generator.text(
        bill.storeAddress,
        styles: const PosStyles(align: PosAlign.center),
      );

      bytes += generator.emptyLines(1);

      // Bill details
      bytes += generator.row([
        PosColumn(
          text: 'Bill No:',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: bill.billNumber,
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.row([
        PosColumn(
          text: 'Date:',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: bill.date,
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.emptyLines(1);

      // Separator
      bytes += generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Items header
      bytes += generator.row([
        PosColumn(
          text: 'Item',
          width: 6,
          styles: const PosStyles(align: PosAlign.left, bold: true),
        ),
        PosColumn(
          text: 'Qty',
          width: 2,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
        PosColumn(
          text: 'Price',
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);

      bytes += generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Items
      for (var item in bill.items) {
        bytes += generator.row([
          PosColumn(
            text: item.name,
            width: 6,
            styles: const PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: '${item.quantity}',
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: '\$${(item.price * item.quantity).toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Subtotal, Tax, Total
      if (bill.tax > 0) {
        bytes += generator.row([
          PosColumn(
            text: 'Subtotal:',
            width: 8,
            styles: const PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: '\$${bill.subtotal.toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);

        bytes += generator.row([
          PosColumn(
            text: 'Tax:',
            width: 8,
            styles: const PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: '\$${bill.tax.toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.row([
        PosColumn(
          text: 'TOTAL:',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
        PosColumn(
          text: '\$${bill.total.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
      ]);

      bytes += generator.emptyLines(1);

      // Payment method
      if (bill.paymentMethod.isNotEmpty) {
        bytes += generator.text(
          'Payment: ${bill.paymentMethod}',
          styles: const PosStyles(align: PosAlign.center),
        );
      }

      // Footer
      bytes += generator.emptyLines(1);
      bytes += generator.text(
        'Thank you for your business!',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );

      if (bill.footer.isNotEmpty) {
        bytes += generator.text(
          bill.footer,
          styles: const PosStyles(align: PosAlign.center),
        );
      }

      bytes += generator.emptyLines(2);

      // Cut paper
      bytes += generator.cut();

      // Print
      await _thermalPrinter.printData(
        _connectedPrinter!,
        Uint8List.fromList(bytes),
        longData: true,
      );

      return true;
    } catch (e) {
      print('Error printing: $e');
      return false;
    }
  }

  /// Print test receipt
  Future<bool> printTest() async {
    try {
      if (_connectedPrinter == null) {
        print('No printer connected');
        return false;
      }

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      bytes += generator.text(
        'TEST PRINT',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );

      bytes += generator.emptyLines(1);
      bytes += generator.text(
        'Printer connected successfully!',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.emptyLines(1);
      bytes += generator.text(
        DateTime.now().toString(),
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.emptyLines(2);
      bytes += generator.cut();

      await _thermalPrinter.printData(
        _connectedPrinter!,
        Uint8List.fromList(bytes),
      );

      return true;
    } catch (e) {
      print('Error printing test: $e');
      return false;
    }
  }

  /// Add network printer manually
  Future<Printer?> addNetworkPrinter(
    String ipAddress, {
    int port = 9100,
  }) async {
    try {
      final printer = Printer(
        name: 'Network Printer',
        address: ipAddress,
        // productId: port,
        connectionType: ConnectionType.NETWORK,
      );
      return printer;
    } catch (e) {
      print('Error adding network printer: $e');
      return null;
    }
  }
}

/// Bill data model
class BillData {
  final String storeName;
  final String storeAddress;
  final String billNumber;
  final String date;
  final List<BillItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentMethod;
  final String footer;

  BillData({
    required this.storeName,
    required this.storeAddress,
    required this.billNumber,
    required this.date,
    required this.items,
    this.tax = 0.0,
    this.paymentMethod = '',
    this.footer = '',
  }) : subtotal = items.fold(
         0.0,
         (sum, item) => sum + (item.price * item.quantity),
       ),
       total =
           items.fold(0.0, (sum, item) => sum + (item.price * item.quantity)) +
           tax;
}

/// Bill item model
class BillItem {
  final String name;
  final int quantity;
  final double price;

  BillItem({required this.name, required this.quantity, required this.price});
}
