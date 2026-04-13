import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrinterConnectionDialog extends StatelessWidget {
  final ThermalPrinterService printerService;

  const PrinterConnectionDialog({Key? key, required this.printerService})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Assets.svg.print.svg(
                  width: 28,
                  height: 28,
                  color: AppColor.primary,
                ),
                // const Icon(Icons.print, size: 28, color: Colors.blue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Connect Printer',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Warning Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No printer connected. Please connect a Bluetooth printer.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Scan Button
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: printerService.isScanning.value
                      ? null
                      : () async {
                          await printerService.requestPermissions();
                          await printerService.startScan();
                        },
                  icon: printerService.isScanning.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.bluetooth_searching),
                  label: Text(
                    printerService.isScanning.value
                        ? 'Scanning...'
                        : 'Scan for Devices',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Device List
            Expanded(
              child: Obx(() {
                if (printerService.scanResults.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_disabled,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          printerService.isScanning.value
                              ? 'Looking for devices...'
                              : 'No devices found.\nTap "Scan for Devices" to start.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: BouncingScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: printerService.scanResults.length,
                  itemBuilder: (context, index) {
                    final result = printerService.scanResults[index];
                    final device = result.device;
                    final deviceName = device.platformName.isNotEmpty
                        ? device.platformName
                        : 'Unknown Device';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColor.primary.withOpacity(0.1),
                          child: Assets.svg.print.svg(
                            width: 20,
                            height: 20,
                            color: AppColor.primary,
                          ),
                          // child: Icon(Icons.print, color: Colors.white),
                        ),
                        title: Text(
                          deviceName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          device.remoteId.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Obx(() {
                          final isConnecting = printerService
                              .connectionStatus
                              .value
                              .contains(device.remoteId.toString());

                          if (isConnecting) {
                            return const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }

                          return const Icon(Icons.chevron_right);
                        }),
                        onTap: () async {
                          final success = await printerService.connectToDevice(
                            device,
                          );
                          if (success) {
                            Get.back();
                            AppSnackbar.show(
                              title: 'Success',
                              message: 'Connected to $deviceName',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                            );
                          } else {
                            AppSnackbar.show(
                              title: 'Error',
                              message: 'Failed to connect to $deviceName',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              }),
            ),

            // Connection Status
            Obx(() {
              if (printerService.connectionStatus.value.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    printerService.connectionStatus.value,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  // Static method to show dialog
  static Future<void> show() async {
    final printerService = ThermalPrinterService.instance;

    return Get.dialog(
      PrinterConnectionDialog(printerService: printerService),
      barrierDismissible: true,
    );
  }
}

// Extension method for easy usage
extension PrinterServiceExtension on ThermalPrinterService {
  Future<bool> ensureConnected() async {
    if (!isConnected.value) {
      await PrinterConnectionDialog.show();
      return isConnected.value;
    }
    return true;
  }
}
