// ignore_for_file: deprecated_member_use

import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Printer/printer_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:get/get.dart';

class PrinterScreen extends GetView<PrinterController> {
  const PrinterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(PrinterController());
    var loc = AppLocalizations.of(Get.context!)!;
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          loc.printer,
          style: TextStyle(
            color: AppColor.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          // Refresh/Retry connection button
          IconButton(
            icon: Icon(Icons.refresh, color: AppColor.white),
            onPressed: () async {
              await controller.printerService.tryAutoConnect();
            },
            tooltip: 'Retry Connection',
          ),
        ],
        bottom: TabBar(
          controller: controller.tabController,
          indicatorColor: AppColor.white,
          indicatorWeight: 3,
          labelColor: AppColor.white,
          unselectedLabelColor: Colors.grey,
          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          tabs: [
            Tab(text: loc.bluetooth),
            Tab(text: loc.usb),
          ],
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: [_buildBluetoothTab(), _buildUSBTab()],
      ),
    );
  }

  Widget _buildBluetoothTab() {
    var loc = AppLocalizations.of(Get.context!)!;

    return Column(
      children: [
        // Connection Status Card
        _buildConnectionStatusCard(),

        // Auto-Connect Settings Card
        _buildAutoConnectCard(),

        // Device List
        Expanded(
          child: Obx(() {
            if (controller.isScanning.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF1E5EFF)),
                    SizedBox(height: 16),
                    Text(
                      '${loc.scanning_for_devices}...',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            if (controller.devices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bluetooth_disabled,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      loc.no_new_devices_found,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the button below to scan',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              physics: BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: controller.devices
                  .where((d) => d.platformName.isNotEmpty)
                  .length,
              itemBuilder: (context, index) {
                final devices = controller.devices;

                final device = devices[index];

                final isConnected =
                    controller.connectedDevice.value?.remoteId ==
                    device.remoteId;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Icon(
                      isConnected ? Icons.print : Icons.print_outlined,
                      color: isConnected ? Colors.green : AppColor.primary,
                    ),
                    title: Text(
                      device.platformName, // no unknown now
                      style: TextStyle(
                        fontWeight: isConnected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      isConnected ? 'Connected' : device.remoteId.toString(),
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    trailing: isConnected
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.print,
                                  color: AppColor.primary,
                                ),
                                onPressed: controller.printTestReceipt,
                                tooltip: 'Test Print',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    controller.disconnectDevice(device),
                                tooltip: 'Disconnect',
                              ),
                            ],
                          )
                        : ElevatedButton(
                            onPressed: () => controller.connectToDevice(device),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            child: const Text('Connect'),
                          ),
                  ),
                );
              },
            );
          }),
        ),
        Container(
          padding: EdgeInsets.all(16),
          child: Obx(
            () => SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.isScanning.value
                    ? null
                    : controller.scanForDevices,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  controller.isScanning.value
                      ? '${loc.scanning_for_devices}...'
                      : loc.scan_for_new_devices,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatusCard() {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Obx(
                  () => Icon(
                    controller.printerService.isConnected.value
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    color: controller.printerService.isConnected.value
                        ? Colors.green
                        : Colors.grey,
                    size: 36,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Printer Status',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Obx(
                        () => Text(
                          controller.printerService.isConnected.value
                              ? 'Connected to: ${controller.printerService.connectedDevice?.platformName ?? "Printer"}'
                              : controller
                                    .printerService
                                    .connectionStatus
                                    .value
                                    .isEmpty
                              ? 'Not Connected'
                              : controller
                                    .printerService
                                    .connectionStatus
                                    .value,
                          style: TextStyle(
                            color: controller.printerService.isConnected.value
                                ? Colors.green
                                : Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(
                  () => controller.printerService.isConnected.value
                      ? Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Text(
                            'READY',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : SizedBox(),
                ),
              ],
            ),
            SizedBox(height: 12),
            Obx(() {
              if (Get.isRegistered<HomeScreenController>()) {
                Get.find<HomeScreenController>().selectedOutlet.value;
              }
              final bill = controller.savedBillPrinterName.value;
              final kot = controller.savedKotPrinterName.value;
              final showKot = HomeMainRoutes.outletIsCafeOrRestaurant();
              if ((bill == null || bill.isEmpty) &&
                  (!showKot || kot == null || kot.isEmpty)) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bill != null && bill.isNotEmpty)
                      Text(
                        'Bill Printer: $bill',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    if (showKot && kot != null && kot.isNotEmpty)
                      Text(
                        'KOT Printer: $kot',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                  ],
                ),
              );
            }),
            Obx(() {
              if (Get.isRegistered<HomeScreenController>()) {
                Get.find<HomeScreenController>().selectedOutlet.value;
              }
              final showKot = HomeMainRoutes.outletIsCafeOrRestaurant();
              final connected =
                  controller.printerService.isConnected.value ||
                  controller.printerService.isUsbConnected.value;
              if (!connected) return const SizedBox.shrink();
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.setCurrentAsBillPrinter,
                      child: const Text('Set as Bill Printer'),
                    ),
                  ),
                  if (showKot) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.setCurrentAsKotPrinter,
                        child: const Text('Set as KOT Printer'),
                      ),
                    ),
                  ],
                ],
              );
            }),
            Obx(
              () => controller.printerService.isAutoConnecting.value
                  ? Column(
                      children: [
                        LinearProgressIndicator(
                          color: AppColor.primary,
                          backgroundColor: AppColor.primary.withOpacity(0.2),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Auto-connecting...',
                          style: TextStyle(
                            color: AppColor.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoConnectCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      elevation: 2,
      child: Column(
        children: [
          Obx(
            () => SwitchListTile(
              title: Text(
                'Auto-Connect',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: Text(
                'Automatically connect to saved printer on app start',
                style: TextStyle(fontSize: 12),
              ),
              value: controller.autoConnectEnabled.value,
              activeColor: Colors.green,
              onChanged: (value) async {
                await controller.toggleAutoConnect(value);
              },
            ),
          ),
          Obx(() {
            if (controller.savedDeviceName.value != null) {
              return ListTile(
                leading: Icon(Icons.print, color: AppColor.primary),
                title: Text(
                  'Saved Printer',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  controller.savedDeviceName.value!,
                  style: TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove saved printer',
                  onPressed: () async {
                    final confirm = await Get.dialog<bool>(
                      AlertDialog(
                        title: Text('Remove Saved Printer?'),
                        content: Text(
                          'This will clear the saved printer and disable auto-connect.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Get.back(result: true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text('Remove'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await controller.clearSavedDevice();
                    }
                  },
                ),
              );
            }
            return SizedBox();
          }),
        ],
      ),
    );
  }

  Widget _buildUSBTab() {
    var loc = AppLocalizations.of(Get.context!)!;

    return Obx(() {
      // Show loading state
      if (controller.isCheckingUsb.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF1E5EFF)),
              SizedBox(height: 16),
              Text(
                'Checking for USB devices...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      // Show USB devices if found
      if (controller.usbDevices.isNotEmpty) {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(16),
                itemCount: controller.usbDevices.length,
                itemBuilder: (context, index) {
                  final printer = controller.usbDevices[index];
                  final isConnected =
                      controller.connectedUsbPrinter.value?.address ==
                      printer.address;

                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        isConnected ? Icons.usb : Icons.usb_outlined,
                        color: isConnected ? Colors.green : AppColor.primary,
                        size: 32,
                      ),
                      title: Text(
                        printer.name ?? 'USB Printer',
                        style: TextStyle(
                          fontWeight: isConnected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        isConnected
                            ? 'Connected'
                            : printer.address ?? 'Unknown Address',
                        style: TextStyle(
                          color: isConnected ? Colors.green : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isConnected
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.print,
                                    color: AppColor.primary,
                                  ),
                                  onPressed: controller.printTestReceipt,
                                  tooltip: 'Test Print',
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: controller.disconnectUsbPrinter,
                                  tooltip: 'Disconnect',
                                ),
                              ],
                            )
                          : ElevatedButton(
                              onPressed: () =>
                                  controller.connectUsbPrinter(printer),
                              child: Text('Connect'),
                            ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: controller.startUsbScan,
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh USB Devices'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }

      // Show "not connected" message if no devices found
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/ConnectionLost.json',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 32),
              Text(
                loc.usb_device_not_connected,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Text(
                loc.usb_device_not_found_message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: controller.startUsbScan,
                icon: Icon(Icons.refresh),
                label: Text('Check Again'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
