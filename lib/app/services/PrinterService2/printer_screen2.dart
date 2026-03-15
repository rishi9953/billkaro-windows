import 'package:billkaro/app/services/PrinterService2/printer_service2.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';

class PrinterScreen2 extends StatefulWidget {
  const PrinterScreen2({super.key});

  @override
  State<PrinterScreen2> createState() => _PrinterScreen2State();
}

class _PrinterScreen2State extends State<PrinterScreen2>
    with SingleTickerProviderStateMixin {
  late final PrinterService2 printerService;
  ThermalPrinterService get thermalPrinter => ThermalPrinterService.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    /// ✅ SAFE GetX resolution
    printerService = Get.put(PrinterService2());

    /// optional auto-init
    printerService.init();

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Settings'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: const [
            Tab(
              icon: Icon(Icons.bluetooth),
              text: 'Bluetooth',
            ),
            Tab(
              icon: Icon(Icons.usb),
              text: 'USB',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await printerService.init();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          /// 🔵 STATUS CARD (Bluetooth or USB)
          Obx(
            () {
              final btConnected = printerService.isConnected.value;
              final usbConnected = thermalPrinter.isUsbConnected.value;
              final connected = btConnected || usbConnected;
              final isUsb = usbConnected && !btConnected;
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: connected
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      connected ? Icons.print : Icons.print_disabled,
                      color: connected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        connected
                            ? (isUsb
                                ? 'USB: ${thermalPrinter.connectedUsbPrinter?.name ?? 'Printer'}'
                                : 'Bluetooth: ${printerService.selectedPrinter.value?.name ?? 'Printer'}')
                            : 'Printer Not Connected',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (connected)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: isUsb
                            ? () => thermalPrinter.disconnectUsbPrinter()
                            : printerService.disconnect,
                      ),
                  ],
                ),
              );
            },
          ),

          /// TABS CONTENT
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBluetoothTab(),
                _buildUsbTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothTab() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: const [
              Icon(Icons.bluetooth),
              SizedBox(width: 8),
              Text(
                'Paired Bluetooth Devices',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<BluetoothDevice>>(
            future: FlutterBluetoothSerial.instance.getBondedDevices(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final devices = snapshot.data!;

              if (devices.isEmpty) {
                return const Center(
                  child: Text('No paired devices found'),
                );
              }

              return ListView.separated(
                itemCount: devices.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final device = devices[index];

                  return ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(device.name ?? 'Unknown'),
                    subtitle: Text(device.address),
                    trailing: Obx(() {
                      final isThisDeviceConnected =
                          printerService.isConnected.value &&
                              printerService.selectedPrinter.value?.address ==
                                  device.address;

                      return ElevatedButton(
                        onPressed: () async {
                          if (isThisDeviceConnected) {
                            printerService.disconnect();
                          } else {
                            await printerService.connect(device);
                          }
                        },
                        child: Text(
                          isThisDeviceConnected ? 'DISCONNECT' : 'CONNECT',
                        ),
                      );
                    }),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Scan Devices'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                printerService.scanForDevices();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsbTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: const [
              Icon(Icons.usb),
              SizedBox(width: 8),
              Text(
                'USB printers (plug in cable first)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Connect the printer with a USB cable to this device, then tap "Scan for USB printers".',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: thermalPrinter.isUsbScanning.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.usb),
                label: Text(
                  thermalPrinter.isUsbScanning.value
                      ? 'Scanning...'
                      : 'Scan for USB printers',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: thermalPrinter.isUsbScanning.value
                    ? null
                    : () => thermalPrinter.scanUsbPrinters(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Obx(() {
            final list = thermalPrinter.usbPrinters;
            final _ = thermalPrinter.isUsbConnected.value; // rebuild when connection changes
            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.usb_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      thermalPrinter.isUsbScanning.value
                          ? 'Looking for USB printers...'
                          : 'No USB printers found.\nPlug in the printer and tap Scan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final printer = list[index];
                final isConnected = thermalPrinter.isUsbConnected.value &&
                    thermalPrinter.connectedUsbPrinter == printer;
                return ListTile(
                  leading: const Icon(Icons.usb),
                  title: Text(printer.name ?? 'USB Printer'),
                  subtitle: Text(
                    [
                      if (printer.vendorId != null) '${printer.vendorId}',
                      if (printer.productId != null) '${printer.productId}',
                    ].join(' / '),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      if (isConnected) {
                        await thermalPrinter.disconnectUsbPrinter();
                      } else {
                        await thermalPrinter.connectUsbPrinter(printer);
                      }
                    },
                    child: Text(isConnected ? 'DISCONNECT' : 'CONNECT'),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
