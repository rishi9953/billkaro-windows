import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';

class BluetoothPrinterAutoConnect extends StatefulWidget {
  const BluetoothPrinterAutoConnect({super.key});

  @override
  State<BluetoothPrinterAutoConnect> createState() =>
      _BluetoothPrinterAutoConnectState();
}

class _BluetoothPrinterAutoConnectState
    extends State<BluetoothPrinterAutoConnect> {
  List<BluetoothDevice> devices = [];
  BluetoothConnection? connection;
  BluetoothDevice? selectedDevice;

  bool isConnecting = false;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  /// 🔥 INIT BLUETOOTH + AUTO CONNECT
  Future<void> _initBluetooth() async {
    await FlutterBluetoothSerial.instance.requestEnable();

    final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();

    setState(() {
      devices = bonded;
    });

    // 🔍 Auto-detect printer
    final printer = _findPrinter(bonded);

    if (printer != null) {
      debugPrint('Auto printer found: ${printer.name}');
      await _connect(printer);
    }
  }

  /// 🖨️ Detect inbuilt / POS printer
  BluetoothDevice? _findPrinter(List<BluetoothDevice> devices) {
    for (final d in devices) {
      final name = d.name?.toLowerCase() ?? '';
      if (name.contains('printer') ||
          name.contains('pos') ||
          name.contains('thermal') ||
          name.contains('inner')) {
        return d;
      }
    }
    return null;
  }

  /// 🔗 CONNECT
  Future<void> _connect(BluetoothDevice device) async {
    if (isConnecting || isConnected) return;

    setState(() {
      isConnecting = true;
    });

    try {
      connection = await BluetoothConnection.toAddress(device.address);

      setState(() {
        selectedDevice = device;
        isConnected = true;
      });

      debugPrint('Connected to ${device.name}');
    } catch (e) {
      debugPrint('Connection failed: $e');
    } finally {
      setState(() {
        isConnecting = false;
      });
    }
  }

  /// 🖨️ PRINT RECEIPT
  Future<void> printReceipt() async {
    if (connection == null || !isConnected) return;

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    List<int> bytes = [];

    bytes += generator.reset();

    bytes += generator.text(
      'BILLKARO',
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.hr();

    bytes += generator.text(
      'Invoice No: 12345',
      styles: const PosStyles(bold: true),
    );

    bytes += generator.text('Item A      x1   Rs 100');
    bytes += generator.text('Item B      x2   Rs 200');

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: 'Rs 300',
        width: 6,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);

    bytes += generator.feed(2);
    bytes += generator.text(
      'Thank you!',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    connection!.output.add(Uint8List.fromList(bytes));
  }

  /// ❌ DISCONNECT
  void disconnect() {
    connection?.finish();
    connection = null;

    setState(() {
      isConnected = false;
      selectedDevice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Bluetooth Printer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initBluetooth,
          ),
        ],
      ),
      body: Column(
        children: [
          if (isConnected)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.green.shade100,
              child: Row(
                children: [
                  const Icon(Icons.print, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connected: ${selectedDevice?.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: disconnect,
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final d = devices[index];
                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(d.name ?? 'Unknown'),
                  subtitle: Text(d.address),
                  trailing: ElevatedButton(
                    onPressed: isConnected ? null : () => _connect(d),
                    child: Text(
                      isConnected && selectedDevice?.address == d.address
                          ? 'CONNECTED'
                          : 'CONNECT',
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('PRINT TEST RECEIPT'),
                onPressed: isConnected ? printReceipt : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
