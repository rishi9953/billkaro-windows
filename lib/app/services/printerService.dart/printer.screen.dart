import 'package:billkaro/app/services/Network/api_handler.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key});

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  final ThermalPrinterService controller = ThermalPrinterService.instance;
  bool autoConnectEnabled = false;
  String? savedDeviceName;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await controller.isAutoConnectEnabled();
    final deviceName = await controller.getSavedDeviceName();
    setState(() {
      autoConnectEnabled = enabled;
      savedDeviceName = deviceName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thermal Printer"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Retry Connection',
            onPressed: () async {
              await controller.tryAutoConnect();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status Card
          _buildConnectionStatusCard(),

          const SizedBox(height: 8),

          // Auto-Connect Settings Card
          _buildAutoConnectCard(),

          const SizedBox(height: 8),

          // Scan Controls
          _buildScanControls(),

          const SizedBox(height: 8),

          // Scan Results List
          Expanded(child: _buildScanResultsList()),

          // Bottom Actions
          _buildBottomActions(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Obx(
                  () => Icon(
                    controller.isConnected.value
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    color: controller.isConnected.value
                        ? Colors.green
                        : Colors.grey,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Printer Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(
                        () => Text(
                          controller.isConnected.value
                              ? 'Connected to: ${controller.connectedDevice?.platformName ?? "Printer"}'
                              : controller.connectionStatus.value.isEmpty
                              ? 'Not Connected'
                              : controller.connectionStatus.value,
                          style: TextStyle(
                            color: controller.isConnected.value
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
                  () => controller.isConnected.value
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Text(
                            'READY',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(
              () => controller.isAutoConnecting.value
                  ? Column(
                      children: [
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          'Auto-connecting...',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoConnectCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Auto-Connect',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Automatically connect to saved printer on app start',
              style: TextStyle(fontSize: 12),
            ),
            value: autoConnectEnabled,
            activeColor: Colors.green,
            onChanged: (value) async {
              await controller.enableAutoConnect(value);
              setState(() {
                autoConnectEnabled = value;
              });
              showSuccess(
                description: value
                    ? 'Auto-Connect Enabled'
                    : 'Auto-Connect Disabled',
                title: value
                    ? 'Will connect automatically on app start'
                    : 'Manual connection required',
              );
            },
          ),
          if (savedDeviceName != null)
            ListTile(
              leading: const Icon(Icons.print, color: Colors.blue),
              title: const Text(
                'Saved Printer',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                savedDeviceName!,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Remove saved printer',
                onPressed: () async {
                  final confirm = await Get.dialog<bool>(
                    AlertDialog(
                      title: const Text('Remove Saved Printer?'),
                      content: const Text(
                        'This will clear the saved printer and disable auto-connect.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Get.back(result: true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await controller.clearSavedDevice();
                    setState(() {
                      savedDeviceName = null;
                      autoConnectEnabled = false;
                    });
                    showSuccess(description: 'Saved printer removed');
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => ElevatedButton.icon(
                icon: Icon(
                  controller.isScanning.value
                      ? Icons.hourglass_empty
                      : Icons.bluetooth_searching,
                ),
                label: Text(
                  controller.isScanning.value
                      ? 'Scanning...'
                      : 'Scan for Printers',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: controller.isScanning.value
                    ? null
                    : () async {
                        await controller.requestPermissions();
                        controller.startScan();
                      },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(
            () => controller.isConnected.value
                ? ElevatedButton(
                    onPressed: () async {
                      final confirm = await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('Disconnect Printer?'),
                          content: const Text(
                            'Are you sure you want to disconnect?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Disconnect'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await controller.disconnect();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Icon(Icons.bluetooth_disabled),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResultsList() {
    return Obx(() {
      if (controller.scanResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bluetooth_searching,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No devices found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap "Scan for Printers" to search for\navailable Bluetooth printers',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        physics: BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.scanResults.length,
        itemBuilder: (context, index) {
          final result = controller.scanResults[index];
          final device = result.device;
          final deviceName = device.platformName.isNotEmpty
              ? device.platformName
              : 'Unknown Device';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.print, color: Colors.blue),
              ),
              title: Text(
                deviceName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                device.remoteId.str,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: ElevatedButton(
                onPressed: () async {
                  final success = await controller.connectToDevice(device);
                  if (success) {
                    showSuccess(
                      title: 'Connected',
                      description: 'Successfully connected to $deviceName',
                    );

                    await _loadSettings();
                  } else {
                    AppSnackbar.show(
                      title: 'Connection Failed',
                      message: 'Unable to connect to printer',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                      margin: const EdgeInsets.all(16),
                      icon: const Icon(Icons.error, color: Colors.white),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Connect'),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.receipt_long),
                label: const Text(
                  'Print Test Invoice',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: controller.isConnected.value
                      ? Colors.green
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                onPressed: controller.isConnected.value
                    ? () async {
                        try {
                          await controller.printInvoice(
                            brandName: "Demo Brand",
                            businessName: "Demo Business",
                            address: "123 Street",
                            city: "Delhi",
                            zipcode: "110001",
                            state: "Delhi",
                            orderFrom: "Dine In",
                            customerName: "John Doe",
                            paymentMode: "Cash",
                            date: "05-12-2025",
                            time: "10:00 AM",
                            invoiceNo: "INV1001",
                            items: [
                              // InvoiceItem(
                              //   itemName: "Coffee",
                              //   quantity: 2,
                              //   price: 50,
                              //   amount: 100,
                              // ),
                              // InvoiceItem(
                              //   itemName: "Burger",
                              //   quantity: 1,
                              //   price: 120,
                              //   amount: 120,
                              // ),
                            ],
                            subtotal: 220,
                            totalTax: 20,
                            serviceCharge: 10,
                            discount: 0,
                            totalAmount: 250,
                            upiId: "demo@upi",
                          );

                          AppSnackbar.show(
                            title: 'Success',
                            message: 'Test invoice printed successfully',
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                            margin: const EdgeInsets.all(16),
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                            ),
                          );
                        } catch (e) {
                          AppSnackbar.show(
                            title: 'Print Error',
                            message: 'Failed to print: $e',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                            margin: const EdgeInsets.all(16),
                            icon: const Icon(Icons.error, color: Colors.white),
                          );
                        }
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
