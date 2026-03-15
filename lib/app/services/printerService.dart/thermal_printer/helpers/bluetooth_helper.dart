import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get_utils/src/platform/platform.dart';
import '../thermal_printer_service.dart';
import 'storage_helper.dart';

class BluetoothHelper {
  // =========================
  // LISTEN CONNECTION STATE
  // =========================
  static void listenToConnectionState(ThermalPrinterService service) {
    FlutterBluePlus.events.onConnectionStateChanged.listen((event) async {
      if (event.device == service.connectedDevice) {
        if (event.connectionState == BluetoothConnectionState.disconnected) {
          debugPrint('🔌 Device disconnected');

          service.isConnected.value = false;
          service.connectionStatus.value = 'Disconnected';
          service.connectedDevice = null;
          service.writeCharacteristic = null;

          await _attemptAutoReconnect(service);
        } else if (event.connectionState ==
            BluetoothConnectionState.connected) {
          debugPrint('🔗 Device connected');

          service.isConnected.value = true;
          service.connectionStatus.value = 'Connected';
        }
      }
    });
  }

  // =========================
  // LISTEN ADAPTER STATE
  // =========================
  static void listenToAdapterState(ThermalPrinterService service) {
    FlutterBluePlus.adapterState.listen((state) async {
      debugPrint('📡 Adapter state: $state');

      if (state == BluetoothAdapterState.on) {
        await Future.delayed(const Duration(seconds: 3)); // 🔥 TABLET FIX
        await _onBluetoothEnabled(service);
      } else if (state == BluetoothAdapterState.off) {
        service.isConnected.value = false;
        service.connectionStatus.value = 'Bluetooth Off';
        service.connectedDevice = null;
        service.writeCharacteristic = null;
      }
    });
  }

  static Future<void> _onBluetoothEnabled(ThermalPrinterService service) async {
    final autoConnectEnabled = await StorageHelper.isAutoConnectEnabled();

    if (autoConnectEnabled &&
        !service.isConnected.value &&
        !service.isAutoConnecting.value) {
      await tryAutoConnect(service);
    }
  }

  // =========================
  // 🔥 MAIN CONNECT LOGIC - FIXED FOR RUGTEK P2
  // =========================
  static Future<bool> connectToDevice(
    BluetoothDevice device,
    ThermalPrinterService service, {
    int retryCount = 2,
  }) async {
    for (int attempt = 1; attempt <= retryCount; attempt++) {
      try {
        service.connectionStatus.value = 'Connecting... (Attempt $attempt)';

        // 1️⃣ Wait for Bluetooth adapter to be fully ON
        final adapterState = await FlutterBluePlus.adapterState.firstWhere(
          (state) => state == BluetoothAdapterState.on,
          orElse: () => BluetoothAdapterState.off,
        );

        if (adapterState != BluetoothAdapterState.on) {
          debugPrint('❌ Bluetooth is OFF');
          service.connectionStatus.value = 'Bluetooth is OFF';
          return false;
        }

        debugPrint('📡 Bluetooth adapter is ON');

        // 2️⃣ Stop any ongoing scan
        try {
          await FlutterBluePlus.stopScan();
        } catch (_) {}

        // 3️⃣ Disconnect if already connected
        try {
          await device.disconnect();
        } catch (_) {}

        await Future.delayed(const Duration(milliseconds: 500));

        // 4️⃣ Android-specific: check bond state
        if (GetPlatform.isAndroid) {
          try {
            final bondState = await device.bondState.first;
            debugPrint('🔐 Current bond state: $bondState');
          } catch (e) {
            debugPrint('Bond state check error: $e');
          }
        }

        // 5️⃣ Connect to device
        debugPrint('🔗 Connecting to ${device.name}');
        await device.connect(
          mtu: 512,
          timeout: const Duration(seconds: 40),
          license: License.free,
        );

        debugPrint('✅ Physical connection success');
        await Future.delayed(const Duration(seconds: 1));

        // 6️⃣ Android-specific MTU adjustment
        if (GetPlatform.isAndroid) {
          try {
            final mtu = await device.requestMtu(256);
            debugPrint('📦 MTU set to: $mtu');
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (e) {
            debugPrint('⚠️ MTU request failed: $e (continuing anyway)');
          }
        }

        // 7️⃣ Discover services
        debugPrint('🔍 Discovering services...');
        final services = await device.discoverServices();
        if (services.isEmpty) {
          debugPrint('❌ No services discovered');
          await device.disconnect();
          throw Exception('No services found');
        }

        BluetoothCharacteristic? writableChar;

        // 8️⃣ Find writable characteristic
        for (final serviceItem in services) {
          debugPrint('📋 Service UUID: ${serviceItem.uuid}');
          for (final char in serviceItem.characteristics) {
            debugPrint('  📝 Characteristic UUID: ${char.uuid}');
            debugPrint(
              '     WriteWithoutResponse: ${char.properties.writeWithoutResponse}',
            );
            debugPrint('     Write: ${char.properties.write}');
            debugPrint('     Read: ${char.properties.read}');
            debugPrint('     Notify: ${char.properties.notify}');

            if (char.properties.writeWithoutResponse) {
              writableChar = char;
              debugPrint(
                '✅ Selected writeWithoutResponse characteristic: ${char.uuid}',
              );
              break;
            } else if (char.properties.write && writableChar == null) {
              writableChar = char;
              debugPrint(
                '⚠️ Selected fallback write characteristic: ${char.uuid}',
              );
            }
          }
          if (writableChar != null) break;
        }

        if (writableChar == null) {
          debugPrint('❌ No writable characteristic found');
          await device.disconnect();
          throw Exception('No writable characteristic');
        }

        // 9️⃣ Save connection info
        service.connectedDevice = device;
        service.writeCharacteristic = writableChar;
        service.isConnected.value = true;
        service.connectionStatus.value =
            'Connected to ${device.name.isNotEmpty ? device.name : 'Rugtek P2'}';

        await StorageHelper.saveDevice(device);

        debugPrint('✅ FULL BLE CONNECTION SUCCESS TO RUGTEK P2');
        return true;
      } catch (e, s) {
        debugPrint('❌ BLE Connection attempt $attempt failed');
        debugPrint('Error: $e');
        debugPrint('Stack trace: $s');

        service.connectionStatus.value = 'Connection failed, retrying...';

        try {
          await device.disconnect();
        } catch (_) {}

        await Future.delayed(const Duration(seconds: 1));
      }
    }

    service.connectionStatus.value = 'Failed to connect after retries';
    return false;
  }

  // =========================
  // RECOVER STATE FROM EXISTING BLE CONNECTION
  // (Fixes "No Bluetooth printer connected" when app state was lost but device is still connected)
  // =========================
  static Future<bool> tryRecoverFromExistingConnection(
    ThermalPrinterService service,
  ) async {
    try {
      // 1) Devices already connected to our app (e.g. state was cleared but BLE still connected)
      final connectedList = FlutterBluePlus.connectedDevices;
      if (connectedList.isNotEmpty) {
        final savedId = await StorageHelper.getSavedDeviceId();
        BluetoothDevice? device;
        if (savedId != null) {
          try {
            device = connectedList.firstWhere(
                (d) => d.remoteId.toString() == savedId);
          } catch (_) {}
        }
        device ??= connectedList.first;

        final writableChar = await _discoverWritableCharacteristic(device);
        if (writableChar != null) {
          service.connectedDevice = device;
          service.writeCharacteristic = writableChar;
          service.isConnected.value = true;
          service.connectionStatus.value =
              'Reconnected to ${device.platformName.isNotEmpty ? device.platformName : "printer"}';
          debugPrint('✅ Recovered Bluetooth state from existing connection');
          return true;
        }
      }

      // 2) Devices connected at system level (e.g. after app restart) – connect and adopt
      final systemDevices = await FlutterBluePlus.connectedSystemDevices;
      if (systemDevices.isNotEmpty) {
        final savedId = await StorageHelper.getSavedDeviceId();
        BluetoothDevice? target;
        if (savedId != null) {
          try {
            target = systemDevices.firstWhere(
                (d) => d.remoteId.toString() == savedId);
          } catch (_) {}
        }
        target ??= systemDevices.first;
        debugPrint('🔗 Adopting system-connected device for printing...');
        return await connectToDevice(target, service, retryCount: 1);
      }
    } catch (e) {
      debugPrint('⚠️ Recovery from existing connection failed: $e');
    }
    return false;
  }

  static Future<BluetoothCharacteristic?> _discoverWritableCharacteristic(
    BluetoothDevice device,
  ) async {
    try {
      final services = await device.discoverServices();
      for (final serviceItem in services) {
        for (final char in serviceItem.characteristics) {
          if (char.properties.writeWithoutResponse) return char;
          if (char.properties.write) return char;
        }
      }
    } catch (_) {}
    return null;
  }

  // =========================
  // DISCONNECT
  // =========================
  static Future<void> disconnect(ThermalPrinterService service) async {
    if (service.connectedDevice != null) {
      try {
        debugPrint('🔌 Disconnecting from device...');
        await service.connectedDevice!.disconnect();
      } catch (e) {
        debugPrint('⚠️ Disconnect error: $e');
      }

      service.connectedDevice = null;
      service.writeCharacteristic = null;
      service.isConnected.value = false;
      service.connectionStatus.value = 'Disconnected';
    }
  }

  // =========================
  // AUTO CONNECT - ENHANCED FOR RUGTEK P2
  // =========================
  static Future<bool> tryAutoConnect(ThermalPrinterService service) async {
    try {
      service.isAutoConnecting.value = true;
      service.connectionStatus.value = 'Auto-connecting...';

      final lastDeviceId = await StorageHelper.getSavedDeviceId();
      if (lastDeviceId == null) {
        debugPrint('⚠️ No saved device ID for auto-connect');
        service.isAutoConnecting.value = false;
        return false;
      }

      debugPrint('🔍 Searching for saved device: $lastDeviceId');

      await FlutterBluePlus.stopScan();

      BluetoothDevice? targetDevice;

      final sub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          if (r.device.remoteId.toString() == lastDeviceId) {
            debugPrint('✅ Found saved device: ${r.device.platformName}');
            targetDevice = r.device;
          }
        }
      });

      // 🔥 RUGTEK P2 FIX: Longer scan time for better discovery
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));

      await Future.delayed(const Duration(seconds: 8));

      await FlutterBluePlus.stopScan();
      await sub.cancel();

      if (targetDevice != null) {
        debugPrint('🔗 Attempting to connect to saved device...');
        final success = await connectToDevice(targetDevice!, service);
        service.isAutoConnecting.value = false;
        return success;
      } else {
        debugPrint('⚠️ Saved device not found in scan results');
      }

      service.isAutoConnecting.value = false;
      return false;
    } catch (e) {
      debugPrint('❌ Auto-connect error: $e');
      service.isAutoConnecting.value = false;
      return false;
    }
  }

  // =========================
  // AUTO RECONNECT
  // =========================
  static Future<void> _attemptAutoReconnect(
    ThermalPrinterService service,
  ) async {
    final enabled = await StorageHelper.isAutoConnectEnabled();

    if (enabled && !service.isAutoConnecting.value) {
      debugPrint('🔄 Attempting auto-reconnect...');
      await Future.delayed(const Duration(seconds: 2));
      await tryAutoConnect(service);
    }
  }

  // =========================
  // BLUETOOTH STATE HELPERS
  // =========================
  Future<bool> isBluetoothEnabled() async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  Future<bool> turnOnBluetooth() async {
    if (GetPlatform.isAndroid) {
      await FlutterBluePlus.turnOn();
      await Future.delayed(const Duration(seconds: 2));
      return isBluetoothEnabled();
    }
    return false;
  }

  // =========================
  // 🔥 RUGTEK P2 DIAGNOSTIC HELPER
  // =========================
  static Future<void> printDiagnostics(BluetoothDevice device) async {
    try {
      debugPrint('');
      debugPrint('═══════════════════════════════════════');
      debugPrint('🔍 RUGTEK P2 DIAGNOSTICS');
      debugPrint('═══════════════════════════════════════');
      debugPrint('Device Name: ${device.platformName}');
      debugPrint('Device ID: ${device.remoteId}');

      if (GetPlatform.isAndroid) {
        final bondState = await device.bondState.first;
        debugPrint('Bond State: $bondState');
      }

      final services = await device.discoverServices();
      debugPrint('Services Found: ${services.length}');
      debugPrint('');

      for (final service in services) {
        debugPrint('📋 Service: ${service.uuid}');
        for (final char in service.characteristics) {
          debugPrint('  📝 Characteristic: ${char.uuid}');
          debugPrint('     - Read: ${char.properties.read}');
          debugPrint('     - Write: ${char.properties.write}');
          debugPrint(
            '     - WriteNoResponse: ${char.properties.writeWithoutResponse}',
          );
          debugPrint('     - Notify: ${char.properties.notify}');
          debugPrint('     - Indicate: ${char.properties.indicate}');
        }
      }

      debugPrint('═══════════════════════════════════════');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Diagnostics failed: $e');
    }
  }
}
