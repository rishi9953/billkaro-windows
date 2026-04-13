import 'package:billkaro/app/services/PrinterService2/printer_service2.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  final TextEditingController _bleSearchController = TextEditingController();
  final TextEditingController _usbSearchController = TextEditingController();
  String _bleSearchQuery = '';
  String _usbSearchQuery = '';
  bool get _isWindowsDesktop => Platform.isWindows;

  @override
  void initState() {
    super.initState();

    /// ✅ SAFE GetX resolution
    printerService = Get.put(PrinterService2());

    /// optional auto-init
    if (Platform.isWindows) {
      // On Windows we use BLE via `ThermalPrinterService` (flutter_blue_plus).
      thermalPrinter.startScan();
    } else {
      printerService.init();
      printerService.scanForDevices();
    }

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _bleSearchController.dispose();
    _usbSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Settings'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(icon: Icon(Icons.bluetooth), text: 'Bluetooth'),
            Tab(icon: Icon(Icons.usb), text: 'USB'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              if (Platform.isWindows) {
                await thermalPrinter.startScan();
              } else {
                await printerService.init();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _isWindowsDesktop ? 1080 : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _isWindowsDesktop ? 24 : 16,
                vertical: _isWindowsDesktop ? 20 : 16,
              ),
              child: Column(
                children: [
                  /// STATUS CARD (Bluetooth or USB)
                  Obx(() {
                    final bleConnected = thermalPrinter.isConnected.value;
                    final btConnected = printerService.isConnected.value;
                    final usbConnected = thermalPrinter.isUsbConnected.value;
                    final connected =
                        usbConnected || bleConnected || btConnected;

                    final isUsb = usbConnected;
                    final isBle = !usbConnected && bleConnected;
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;

                    final statusBg = connected
                        ? (isDark
                              ? Colors.green.withOpacity(0.18)
                              : Colors.green.shade100)
                        : (isDark
                              ? Colors.red.withOpacity(0.18)
                              : Colors.red.shade100);
                    final statusIcon = connected ? Colors.green : Colors.red;

                    final String connectionType;
                    final String connectionName;

                    if (!connected) {
                      connectionType = 'Not connected';
                      connectionName = 'Printer not connected';
                    } else if (isUsb) {
                      connectionType = 'USB';
                      connectionName =
                          thermalPrinter.connectedUsbPrinter?.name ?? 'Printer';
                    } else if (isBle) {
                      connectionType = 'Bluetooth';
                      final platformName =
                          thermalPrinter.connectedDevice?.platformName;
                      connectionName =
                          (platformName != null &&
                              platformName.trim().isNotEmpty)
                          ? platformName
                          : 'Printer';
                    } else {
                      connectionType = 'Bluetooth';
                      connectionName =
                          printerService.selectedPrinter.value?.name ??
                          'Printer';
                    }

                    return Card(
                      elevation: 0,
                      color: statusBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          _isWindowsDesktop ? 12 : 14,
                        ),
                        side: BorderSide(
                          color: connected
                              ? Colors.green.withOpacity(0.35)
                              : Colors.red.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(_isWindowsDesktop ? 18 : 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              connected ? Icons.print : Icons.print_disabled,
                              color: statusIcon,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    connectionType,
                                    style: textTheme.labelLarge?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    connectionName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (connected)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: IconButton(
                                  tooltip: 'Disconnect printer',
                                  icon: const Icon(Icons.close),
                                  onPressed: isUsb
                                      ? () => thermalPrinter
                                            .disconnectUsbPrinter()
                                      : isBle
                                      ? () => thermalPrinter.disconnect()
                                      : printerService.disconnect,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  /// TABS CONTENT
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: _isWindowsDesktop ? 0 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          _isWindowsDesktop ? 12 : 10,
                        ),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.2),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(_isWindowsDesktop ? 16 : 8),
                        child: TabBarView(
                          controller: _tabController,
                          children: [_buildBluetoothTab(), _buildUsbTab()],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBluetoothTab() {
    if (Platform.isWindows) {
      final textTheme = Theme.of(context).textTheme;
      return Column(
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.bluetooth),
              const SizedBox(width: 8),
              Text(
                'Nearby BLE devices',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bleSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search by device name or id...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        _isWindowsDesktop ? 10 : 8,
                      ),
                    ),
                    isDense: _isWindowsDesktop,
                  ),
                  onChanged: (v) => setState(() => _bleSearchQuery = v),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Clear search',
                onPressed: _bleSearchQuery.isEmpty
                    ? null
                    : () {
                        _bleSearchController.clear();
                        setState(() => _bleSearchQuery = '');
                      },
                icon: const Icon(Icons.clear),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              if (thermalPrinter.isScanning.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final results = thermalPrinter.scanResults;
              final query = _bleSearchQuery.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? results
                  : results.where((r) {
                      final device = r.device;
                      final name = device.platformName;
                      final remoteId = device.remoteId.toString();
                      return name.toLowerCase().contains(query) ||
                          remoteId.toLowerCase().contains(query);
                    }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bluetooth_disabled,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        query.isEmpty
                            ? 'No devices found'
                            : 'No devices match "$_bleSearchQuery"',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final r = filtered[index];
                    final BluetoothDevice device = r.device;
                    final name = device.platformName.isNotEmpty
                        ? device.platformName
                        : '(unknown)';
                    final isThisConnected =
                        thermalPrinter.isConnected.value &&
                        thermalPrinter.connectedDevice?.remoteId ==
                            device.remoteId;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      leading: const Icon(Icons.bluetooth),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        device.remoteId.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: SizedBox(
                        width: 130,
                        child: FilledButton.tonal(
                          onPressed: () async {
                            if (isThisConnected) {
                              await thermalPrinter.disconnect();
                            } else {
                              await thermalPrinter.connectToDevice(device);
                            }
                          },
                          child: Text(
                            isThisConnected ? 'Disconnect' : 'Connect',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 220,
                child: FilledButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Scan devices'),
                  onPressed: () => thermalPrinter.startScan(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      );
    }

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
          child: Obx(() {
            final devices = printerService.availableDevices;
            if (printerService.isScanning.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (devices.isEmpty) {
              return const Center(child: Text('No paired devices found'));
            }

            return Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                itemCount: devices.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final device = devices[index];

                  return ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      device.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Obx(() {
                      final isThisDeviceConnected =
                          printerService.isConnected.value &&
                          printerService.selectedPrinter.value?.address ==
                              device.address;

                      return SizedBox(
                        width: 130,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (isThisDeviceConnected) {
                              await printerService.disconnect();
                            } else {
                              await printerService.connect(device);
                            }
                          },
                          child: Text(
                            isThisDeviceConnected ? 'Disconnect' : 'Connect',
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            );
          }),
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
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.usb),
              const SizedBox(width: 8),
              Text(
                'USB printers (plug in cable first)',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _usbSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search by printer name or ids...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        _isWindowsDesktop ? 10 : 8,
                      ),
                    ),
                    isDense: _isWindowsDesktop,
                  ),
                  onChanged: (v) => setState(() => _usbSearchQuery = v),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Clear search',
                onPressed: _usbSearchQuery.isEmpty
                    ? null
                    : () {
                        _usbSearchController.clear();
                        setState(() => _usbSearchQuery = '');
                      },
                icon: const Icon(Icons.clear),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Connect the printer with a USB cable to this device, then tap "Scan for USB printers".',
            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final isScanning = thermalPrinter.isUsbScanning.value;
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 220,
                child: FilledButton.icon(
                  icon: isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.usb),
                  label: Text(
                    isScanning ? 'Scanning...' : 'Scan for USB printers',
                  ),
                  onPressed: isScanning
                      ? null
                      : () => thermalPrinter.scanUsbPrinters(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Expanded(
          child: Obx(() {
            final list = thermalPrinter.usbPrinters;
            final query = _usbSearchQuery.trim().toLowerCase();
            final filtered = query.isEmpty
                ? list
                : list.where((p) {
                    final name = (p.name ?? '').toLowerCase();
                    final vendor = p.vendorId?.toString().toLowerCase() ?? '';
                    final product = p.productId?.toString().toLowerCase() ?? '';
                    return name.contains(query) ||
                        vendor.contains(query) ||
                        product.contains(query);
                  }).toList();
            final _ = thermalPrinter
                .isUsbConnected
                .value; // rebuild when connection changes
            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.usb_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      thermalPrinter.isUsbScanning.value
                          ? 'Looking for USB printers...'
                          : query.isEmpty
                          ? 'No USB printers found.\nPlug in the printer and tap Scan.'
                          : 'No USB printers match "$_usbSearchQuery".',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final printer = filtered[index];
                  final isConnected =
                      thermalPrinter.isUsbConnected.value &&
                      thermalPrinter.connectedUsbPrinter == printer;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    leading: const Icon(Icons.usb),
                    title: Text(
                      printer.name ?? 'USB Printer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        if (printer.vendorId != null) '${printer.vendorId}',
                        if (printer.productId != null) '${printer.productId}',
                      ].join(' / '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: SizedBox(
                      width: 130,
                      child: FilledButton.tonal(
                        onPressed: () async {
                          if (isConnected) {
                            await thermalPrinter.disconnectUsbPrinter();
                          } else {
                            await thermalPrinter.connectUsbPrinter(printer);
                          }
                        },
                        child: Text(isConnected ? 'Disconnect' : 'Connect'),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}
