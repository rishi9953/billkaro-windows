import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

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
import 'helpers/cash_drawer_helper.dart';
import 'helpers/storage_helper.dart';
import 'helpers/thermal_paper_size.dart';
import 'helpers/bluetooth_helper.dart';
import 'helpers/network_printer_helper.dart';
import 'helpers/windows_usb_printer_probe.dart';
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

  /// Reactive ids so list rows / banners rebuild without manual refresh.
  final connectedBleDeviceId = Rxn<String>();
  final connectedUsbPrinterKey = Rxn<String>();

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
  final _network = NetworkPrinterHelper();

  // Ethernet / network (TCP port 9100)
  final isNetworkConnected = false.obs;
  final connectedNetworkLabel = Rxn<String>();
  final isNetworkConnecting = false.obs;

  final selectedPaperSize = ThermalPaperSize.mm58.obs;

  /// True while a user-initiated BLE connect is in progress (suppresses reconnect).
  final isBleConnecting = false.obs;
  final connectingBleDeviceId = Rxn<String>();

  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<BluetoothConnectionState>? _bleDeviceStateSubscription;
  StreamSubscription<List<Printer>>? _usbPresenceMonitorSub;
  Timer? _printerHealthTimer;
  DateTime? _lastOfflineNoticeAt;
  bool _handlingPrinterOffline = false;
  int _usbPresenceMissStreak = 0;
  int _blePresenceMissStreak = 0;

  static String usbPrinterKey(Printer printer) {
    final addr = (printer.address ?? '').trim();
    if (addr.isNotEmpty) return 'usb:$addr';
    return '${printer.vendorId ?? ''}|${printer.productId ?? ''}|'
        '${(printer.name ?? '').trim()}';
  }

  bool _sameUsbPrinter(Printer? a, Printer? b) {
    if (a == null || b == null) return false;
    return usbPrinterKey(a) == usbPrinterKey(b);
  }

  void syncBleConnected(
    BluetoothDevice device,
    BluetoothCharacteristic characteristic,
  ) {
    connectedDevice = device;
    writeCharacteristic = characteristic;
    connectedBleDeviceId.value = device.remoteId.toString();
    isConnected.value = true;
    final name = device.platformName.trim();
    connectionStatus.value =
        'Connected to ${name.isNotEmpty ? name : 'Printer'}';
    _startWatchingBleDevice(device);
  }

  void syncBleDisconnected({String? statusMessage}) {
    _stopWatchingBleDevice();
    _blePresenceMissStreak = 0;
    connectedDevice = null;
    writeCharacteristic = null;
    connectedBleDeviceId.value = null;
    if (!isUsbConnected.value) {
      isConnected.value = false;
      connectionStatus.value = statusMessage ?? 'Disconnected';
    }
  }

  Future<void> loadPaperSize() async {
    selectedPaperSize.value = await StorageHelper.getThermalPaperSize();
  }

  Future<void> setPaperSize(ThermalPaperSize size) async {
    await StorageHelper.saveThermalPaperSize(size);
    selectedPaperSize.value = size;
  }

  int _receiptWidth() => selectedPaperSize.value.receiptWidthChars;

  @override
  void onInit() {
    super.onInit();
    if (kIsWeb) return;
    unawaited(loadPaperSize());
    BluetoothHelper.listenToConnectionState(this);
    BluetoothHelper.listenToAdapterState(this);
    _startPrinterHealthMonitor();
    _initAutoConnect();
  }

  bool _shouldAutoConnectPrinter() {
    if (!Get.isRegistered<AppPref>()) return false;
    return Get.find<AppPref>().isLogin;
  }

  @override
  void onClose() {
    _scanResultsSubscription?.cancel();
    _bleDeviceStateSubscription?.cancel();
    _usbPresenceMonitorSub?.cancel();
    _printerHealthTimer?.cancel();
    if (isUsbConnected.value) {
      unawaited(disconnectUsbPrinter(notifyUser: false));
    }
    unawaited(disconnect());
    unawaited(disconnectNetworkPrinter());
    super.onClose();
  }

  Future<bool> connectNetworkPrinter(String host, {int port = 9100}) async {
    if (isNetworkConnecting.value) return false;
    isNetworkConnecting.value = true;
    try {
      final ok = await _network.connect(host, port: port);
      _syncNetworkConnectionObservables(connected: ok);
      if (ok) {
        await StorageHelper.saveLastNetworkConnection(host, port);
        connectionStatus.value = 'Ethernet: ${_network.connectionLabel}';
      } else {
        connectionStatus.value = 'Ethernet connection failed';
      }
      return ok;
    } finally {
      isNetworkConnecting.value = false;
    }
  }

  void _syncNetworkConnectionObservables({bool? connected}) {
    final ready = connected ?? _network.hasActiveEndpoint;
    isNetworkConnected.value = ready;
    connectedNetworkLabel.value = ready ? _network.connectionLabel : null;
  }

  /// Restores Ethernet status from live socket or saved IP (after print disconnects).
  Future<void> restoreNetworkConnectionStatus() async {
    if (_network.hasActiveEndpoint) {
      _syncNetworkConnectionObservables(connected: true);
      return;
    }
    final ip = await StorageHelper.getLastNetworkIp();
    final port = await StorageHelper.getLastNetworkPort();
    if (ip != null && ip.trim().isNotEmpty) {
      isNetworkConnected.value = true;
      connectedNetworkLabel.value = '$ip:$port';
      return;
    }
    for (final role in ['bill', 'kot']) {
      final info = await StorageHelper.getRoleSavedPrinterInfo(role);
      if (info['type'] == 'network') {
        final roleIp = info['ip'] as String?;
        final rolePort = info['port'] as int? ?? 9100;
        if (roleIp != null && roleIp.trim().isNotEmpty) {
          isNetworkConnected.value = true;
          connectedNetworkLabel.value = '$roleIp:$rolePort';
          return;
        }
      }
    }
    _syncNetworkConnectionObservables(connected: false);
  }

  Future<void> disconnectNetworkPrinter() async {
    await _network.disconnect();
    _syncNetworkConnectionObservables(connected: false);
  }

  Future<void> assignNetworkToRole(
    PrintRole role,
    String host,
    int port, {
    String? name,
  }) async {
    await StorageHelper.saveRoleNetworkPrinter(
      _roleKey(role),
      host,
      port,
      name: name,
    );
    connectionStatus.value =
        '${role == PrintRole.bill ? 'Bill' : 'KOT'} printer set: ${name ?? host}';
  }

  Future<Map<String, String?>> getLastNetworkSettings() async {
    final ip = await StorageHelper.getLastNetworkIp();
    final port = await StorageHelper.getLastNetworkPort();
    return {'ip': ip, 'port': port.toString()};
  }

  void _startPrinterHealthMonitor() {
    if (kIsWeb) return;
    _printerHealthTimer?.cancel();
    _printerHealthTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_verifyActivePrinterConnections()),
    );
    _ensureUsbPresenceMonitor();
  }

  void _ensureUsbPresenceMonitor() {
    if (kIsWeb || _usbPresenceMonitorSub != null) return;
    unawaited(
      FlutterThermalPrinter.instance
          .getPrinters(connectionTypes: [ConnectionType.USB])
          .catchError((_) {}),
    );
    _usbPresenceMonitorSub = FlutterThermalPrinter.instance.devicesStream
        .listen(
          _handleUsbDevicesListUpdate,
          onError: (e) => debugPrint('USB presence monitor error: $e'),
        );
  }

  void _handleUsbDevicesListUpdate(List<Printer> event) {
    final list = event.toList()
      ..removeWhere((p) => (p.name ?? '').trim().isEmpty);
    usbPrinters.assignAll(list);

    if (!isUsbConnected.value || connectedUsbPrinter == null) {
      _usbPresenceMissStreak = 0;
      return;
    }

    // Windows keeps installed queue names even when hardware is off — use spooler status.
    if (Platform.isWindows) {
      unawaited(_verifyUsbConnectionIfNeeded());
      return;
    }

    final stillPresent = list.any(
      (p) => _sameUsbPrinter(p, connectedUsbPrinter!),
    );
    if (stillPresent) {
      _usbPresenceMissStreak = 0;
      return;
    }

    debugPrint('🔌 USB device list: connected printer no longer present');
    unawaited(
      handleUsbPrinterWentOffline(
        notifyUser: true,
        statusMessage: 'USB printer disconnected',
      ),
    );
  }

  void _notifyPrinterWentOffline(String message) {
    final now = DateTime.now();
    if (_lastOfflineNoticeAt != null &&
        now.difference(_lastOfflineNoticeAt!) < const Duration(seconds: 10)) {
      return;
    }
    _lastOfflineNoticeAt = now;
    showError(title: 'Printer offline', description: message);
  }

  /// Clears BLE state when the device drops off (power off, out of range, etc.).
  void handleBlePrinterWentOffline({
    bool notifyUser = false,
    String? statusMessage,
  }) {
    if (_handlingPrinterOffline) return;
    _handlingPrinterOffline = true;
    try {
      final wasBle =
          connectedBleDeviceId.value != null || connectedDevice != null;
      syncBleDisconnected(statusMessage: statusMessage);
      if (notifyUser && wasBle) {
        _notifyPrinterWentOffline(
          statusMessage ?? 'Bluetooth printer is no longer available',
        );
      }
    } finally {
      _handlingPrinterOffline = false;
    }
  }

  void syncUsbDisconnected({String? statusMessage}) {
    connectedUsbPrinter = null;
    connectedUsbPrinterKey.value = null;
    isUsbConnected.value = false;
    _usbPresenceMissStreak = 0;
    if (connectedBleDeviceId.value == null) {
      isConnected.value = false;
      connectionStatus.value = statusMessage ?? 'USB printer disconnected';
    }
  }

  /// Clears USB state when the printer is unplugged, powered off, or unreachable.
  Future<void> handleUsbPrinterWentOffline({
    bool notifyUser = false,
    String? statusMessage,
  }) async {
    if (_handlingPrinterOffline || !isUsbConnected.value) return;
    _handlingPrinterOffline = true;
    try {
      final wasUsb = connectedUsbPrinter != null;
      debugPrint('🔌 USB printer offline — disconnecting');
      try {
        if (connectedUsbPrinter != null) {
          await FlutterThermalPrinter.instance.disconnect(connectedUsbPrinter!);
        }
      } catch (e) {
        debugPrint('USB plugin disconnect on offline: $e');
      }
      syncUsbDisconnected(statusMessage: statusMessage);
      if (notifyUser && wasUsb) {
        _notifyPrinterWentOffline(
          statusMessage ?? 'USB printer was unplugged or turned off',
        );
      }
    } finally {
      _handlingPrinterOffline = false;
    }
  }

  Future<bool> _isUsbPrinterReachable() async {
    if (connectedUsbPrinter == null) return false;
    final printer = connectedUsbPrinter!;

    if (Platform.isWindows) {
      final name = (printer.name ?? printer.address ?? '').trim();
      return isWindowsUsbPrinterReachable(name);
    }

    if (usbPrinters.any((p) => _sameUsbPrinter(p, connectedUsbPrinter!))) {
      return true;
    }

    await _refreshUsbDeviceListQuiet();
    return usbPrinters.any((p) => _sameUsbPrinter(p, connectedUsbPrinter!));
  }

  int get _offlineMissThreshold => Platform.isWindows ? 1 : 2;

  Future<void> _verifyUsbConnectionIfNeeded() async {
    if (!isUsbConnected.value || connectedUsbPrinter == null) {
      _usbPresenceMissStreak = 0;
      return;
    }

    final reachable = await _isUsbPrinterReachable();
    if (reachable) {
      _usbPresenceMissStreak = 0;
      return;
    }

    _usbPresenceMissStreak++;
    debugPrint('USB health check miss ($_usbPresenceMissStreak)');
    if (_usbPresenceMissStreak >= _offlineMissThreshold) {
      await handleUsbPrinterWentOffline(
        notifyUser: true,
        statusMessage: 'USB printer disconnected',
      );
    }
  }

  Future<bool> _isBlePrinterReachable() async {
    final device = connectedDevice;
    if (device == null) return false;

    try {
      if (!await device.isConnected) return false;

      final state = await device.connectionState
          .where(
            (s) =>
                s == BluetoothConnectionState.connected ||
                s == BluetoothConnectionState.disconnected,
          )
          .first
          .timeout(const Duration(seconds: 2));
      if (state != BluetoothConnectionState.connected) return false;

      await device.discoverServices().timeout(const Duration(seconds: 2));
      return true;
    } catch (e) {
      debugPrint('BLE reachability probe failed: $e');
      return false;
    }
  }

  Future<void> _verifyBleConnectionIfNeeded() async {
    if (connectedDevice == null || connectedBleDeviceId.value == null) {
      _blePresenceMissStreak = 0;
      return;
    }

    final reachable = await _isBlePrinterReachable();
    if (reachable) {
      _blePresenceMissStreak = 0;
      return;
    }

    _blePresenceMissStreak++;
    debugPrint('BLE health check miss ($_blePresenceMissStreak)');
    if (_blePresenceMissStreak >= _offlineMissThreshold) {
      handleBlePrinterWentOffline(
        notifyUser: true,
        statusMessage: 'Bluetooth printer disconnected',
      );
    }
  }

  Future<void> _verifyActivePrinterConnections() async {
    if (kIsWeb || _handlingPrinterOffline) return;

    if (isUsbConnected.value && connectedUsbPrinter != null) {
      await _verifyUsbConnectionIfNeeded();
      if (!isUsbConnected.value) return;
    }

    if (connectedDevice != null && connectedBleDeviceId.value != null) {
      await _verifyBleConnectionIfNeeded();
    }
  }

  Future<void> _refreshUsbDeviceListQuiet() async {
    if (kIsWeb) return;
    try {
      await FlutterThermalPrinter.instance.getPrinters(
        connectionTypes: [ConnectionType.USB],
      );
      final discovered = await FlutterThermalPrinter
          .instance
          .devicesStream
          .first
          .timeout(const Duration(seconds: 2), onTimeout: () => <Printer>[]);
      usbPrinters.assignAll(
        discovered.where((p) => (p.name ?? '').trim().isNotEmpty),
      );
    } catch (e) {
      debugPrint('Quiet USB refresh failed: $e');
    }
  }

  void _startWatchingBleDevice(BluetoothDevice device) {
    if (kIsWeb) return;
    _bleDeviceStateSubscription?.cancel();
    _bleDeviceStateSubscription = device.connectionState.listen((state) {
      if (state != BluetoothConnectionState.disconnected) return;
      if (connectedBleDeviceId.value != device.remoteId.toString()) return;
      if (isBleConnecting.value) return;
      debugPrint('🔌 BLE device stream: disconnected');
      handleBlePrinterWentOffline(
        notifyUser: true,
        statusMessage: 'Bluetooth printer disconnected',
      );
    });
  }

  void _stopWatchingBleDevice() {
    _bleDeviceStateSubscription?.cancel();
    _bleDeviceStateSubscription = null;
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
    if (kIsWeb) return;
    try {
      if (await FlutterBluePlus.isSupported == false) {
        connectionStatus.value = 'Bluetooth not supported on this device';
        isScanning.value = false;
        return;
      }
      await stopScan();
      isScanning.value = true;
      scanResults.clear();
      await _scanResultsSubscription?.cancel();
      _scanResultsSubscription = FlutterBluePlus.scanResults.listen(
        (results) => scanResults.value = results
            .where((r) => r.device.platformName.trim().isNotEmpty)
            .toList(),
      );
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      await Future.delayed(const Duration(seconds: 10));
      await stopScan();
    } catch (e) {
      debugPrint('Scan error: $e');
      connectionStatus.value = 'Scan failed: $e';
      isScanning.value = false;
    }
  }

  Future<void> stopScan() async {
    if (kIsWeb) return;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    isScanning.value = false;
    await _scanResultsSubscription?.cancel();
    _scanResultsSubscription = null;
  }

  // Public API - USB Scanning and Connection
  List<Printer> printers = [];

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
      _ensureUsbPresenceMonitor();
    } catch (e) {
      debugPrint('USB Scan Error: $e');
      showError(
        title: 'USB Scan Error',
        description: 'Failed to scan for USB printers: $e',
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
        connectedUsbPrinterKey.value = usbPrinterKey(printer);
        isUsbConnected.value = true;
        isConnected.value = true;
        connectionStatus.value =
            'USB Printer Connected: ${printer.name ?? "Unknown"}';

        // Save USB printer info for auto-connect
        await StorageHelper.saveUsbPrinter(printer.name ?? '');
        _usbPresenceMissStreak = 0;
        _ensureUsbPresenceMonitor();
        unawaited(_refreshUsbDeviceListQuiet());

        return true;
      } else {
        connectionStatus.value = 'Failed to connect USB printer';
        return false;
      }
    } catch (e) {
      debugPrint('USB Connect Error: $e');
      connectionStatus.value = 'USB connection error: $e';
      showError(
        title: 'Connection Error',
        description: 'Failed to connect to USB printer: $e',
      );
      return false;
    }
  }

  Future<void> disconnectUsbPrinter({bool notifyUser = true}) async {
    try {
      if (connectedUsbPrinter != null) {
        try {
          await FlutterThermalPrinter.instance.disconnect(connectedUsbPrinter!);
        } catch (e) {
          debugPrint('USB Disconnect Error: $e');
        }
      }
      syncUsbDisconnected(statusMessage: 'USB printer disconnected');

      if (notifyUser) {
        showSuccess(
          title: 'Disconnected',
          description: 'USB printer disconnected',
        );
      }
    } catch (e) {
      debugPrint('USB Disconnect Error: $e');
      syncUsbDisconnected();
    }
  }

  // Public API - Bluetooth Connection
  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (kIsWeb) return false;
    isBleConnecting.value = true;
    connectingBleDeviceId.value = device.remoteId.toString();
    try {
      await stopScan();
      return await BluetoothHelper.connectToDevice(device, this);
    } finally {
      isBleConnecting.value = false;
      connectingBleDeviceId.value = null;
    }
  }

  bool get _hasAnyPrinterConnection =>
      isConnected.value ||
      (isUsbConnected.value && connectedUsbPrinter != null) ||
      isNetworkConnected.value;

  Future<void> _showPrinterConnectionDialog() async {
    // App loader (especially the Windows overlay) sits above navigator dialogs
    // and would keep spinning on top of "Connect Printer".
    dismissAllAppLoader();
    await Get.dialog(
      PrinterConnectionDialog(printerService: this),
      barrierDismissible: true,
    );
  }

  Future<bool> ensureConnected() async {
    if (_hasAnyPrinterConnection) return true;

    // Avoid hanging forever if BLE adapter state never emits (common on Windows).
    var bluetoothEnabled = false;
    try {
      bluetoothEnabled = await BluetoothHelper().isBluetoothEnabled().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
    } catch (_) {
      bluetoothEnabled = false;
    }
    debugPrint('Bluetooth enabled: $bluetoothEnabled');

    if (!bluetoothEnabled) {
      await scanUsbPrinters();
      if (usbPrinters.isNotEmpty || !Platform.isWindows) {
        await _showPrinterConnectionDialog();
      } else {
        showError(
          title: 'No Printer Available',
          description:
              'Please connect a USB or Ethernet printer from Printer settings',
        );
        return false;
      }
    } else {
      await _showPrinterConnectionDialog();
    }

    return _hasAnyPrinterConnection;
  }

  /// Disconnects the BLE thermal path only. USB stays connected so bill (USB)
  /// and KOT (BLE) can be live at the same time.
  Future<void> disconnect() async {
    await BluetoothHelper.disconnect(this);
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

    if (Platform.isWindows) {
      return _tryAutoConnectWindows();
    }

    if (isConnected.value) return true;
    // Try Bluetooth auto-connect first
    final bluetoothConnected = await BluetoothHelper.tryAutoConnect(this);
    if (bluetoothConnected) return true;

    // Try USB auto-connect as fallback
    final savedUsbPrinter = await StorageHelper.getSavedUsbPrinter();
    if (savedUsbPrinter != null && savedUsbPrinter.isNotEmpty) {
      await scanUsbPrinters();
      final vendorId = await StorageHelper.getSavedUsbVendorId();
      final productId = await StorageHelper.getSavedUsbProductId();
      final printer = usbPrinters.firstWhereOrNull(
        (p) => _usbPrinterMatchesSaved(
          p,
          name: savedUsbPrinter,
          vendorId: vendorId,
          productId: productId,
        ),
      );
      if (printer != null) {
        return await connectUsbPrinter(printer);
      }
    }

    return false;
  }

  Future<bool> _isWindowsPrinterAlreadyConnected() async {
    if (isUsbConnected.value && connectedUsbPrinter != null) return true;
    if (_network.isConnected) return true;
    if (isNetworkConnected.value) return true;
    if (await _isConnectedForRole(PrintRole.bill)) return true;
    if (await _isConnectedForRole(PrintRole.kot)) return true;
    return false;
  }

  Future<bool> _tryAutoConnectWindows() async {
    if (await _isWindowsPrinterAlreadyConnected()) return true;

    try {
      isAutoConnecting.value = true;
      connectionStatus.value = 'Auto-connecting...';

      var connected = false;
      for (final role in PrintRole.values) {
        if (!await hasRolePrinter(role)) continue;
        final type = await StorageHelper.getRoleLastPrinterType(_roleKey(role));
        // Desktop Windows uses USB / Ethernet; skip BLE auto-connect here.
        if (type == 'bluetooth') continue;
        if (await ensureConnectedForRole(role)) {
          connected = true;
        }
      }
      if (connected) return true;

      final savedUsbPrinter = await StorageHelper.getSavedUsbPrinter();
      if (savedUsbPrinter != null && savedUsbPrinter.isNotEmpty) {
        await scanUsbPrinters();
        if (usbPrinters.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 500));
          await scanUsbPrinters();
        }
        final vendorId = await StorageHelper.getSavedUsbVendorId();
        final productId = await StorageHelper.getSavedUsbProductId();
        final printer = usbPrinters.firstWhereOrNull(
          (p) => _usbPrinterMatchesSaved(
            p,
            name: savedUsbPrinter,
            vendorId: vendorId,
            productId: productId,
          ),
        );
        if (printer != null) {
          return await connectUsbPrinter(printer);
        }
      }

      final ip = await StorageHelper.getLastNetworkIp();
      if (ip != null && ip.trim().isNotEmpty) {
        final port = await StorageHelper.getLastNetworkPort();
        return await connectNetworkPrinter(ip.trim(), port: port);
      }

      return false;
    } catch (e) {
      debugPrint('Windows auto-connect error: $e');
      return false;
    } finally {
      isAutoConnecting.value = false;
    }
  }

  String _roleKey(PrintRole role) => role == PrintRole.bill ? 'bill' : 'kot';

  /// Whether raw ESC/POS can be sent (USB or BLE with write characteristic).
  bool get hasActiveThermalPath {
    if (isUsbConnected.value && connectedUsbPrinter != null) return true;
    if (isConnected.value &&
        connectedDevice != null &&
        writeCharacteristic != null) {
      return true;
    }
    if (Get.isRegistered<PrinterService2>() &&
        PrinterService2.to.isConnected.value) {
      return true;
    }
    return false;
  }

  Future<bool> hasRolePrinter(PrintRole role) async {
    final type = await StorageHelper.getRoleLastPrinterType(_roleKey(role));
    if (type == null || type.isEmpty) return false;
    if (type == 'bluetooth') {
      final id = await StorageHelper.getRoleSavedDeviceId(_roleKey(role));
      return id != null && id.isNotEmpty;
    }
    if (type == 'usb') {
      final name = await StorageHelper.getRoleSavedUsbPrinter(_roleKey(role));
      return name != null && name.isNotEmpty;
    }
    if (type == 'network') {
      final ip = await StorageHelper.getRoleSavedNetworkIp(_roleKey(role));
      return ip != null && ip.isNotEmpty;
    }
    return false;
  }

  Future<void> assignBluetoothToRole(
    PrintRole role,
    BluetoothDevice device,
  ) async {
    await StorageHelper.saveRoleBluetoothDevice(_roleKey(role), device);
    connectionStatus.value =
        '${role == PrintRole.bill ? 'Bill' : 'KOT'} printer set: ${device.platformName}';
  }

  Future<void> assignUsbToRole(PrintRole role, Printer printer) async {
    await StorageHelper.saveRoleUsbPrinter(
      _roleKey(role),
      printer.name ?? '',
      vendorId: int.tryParse('${printer.vendorId ?? ''}'),
      productId: int.tryParse('${printer.productId ?? ''}'),
      address: printer.address,
    );
    connectionStatus.value =
        '${role == PrintRole.bill ? 'Bill' : 'KOT'} printer set: ${printer.name ?? 'USB Printer'}';
  }

  Future<void> clearRolePrinter(PrintRole role) async {
    await StorageHelper.clearRolePrinter(_roleKey(role));
  }

  bool _usbPrinterMatchesSaved(
    Printer printer, {
    String? name,
    int? vendorId,
    int? productId,
    String? address,
  }) {
    final savedAddr = (address ?? '').trim();
    final printerAddr = (printer.address ?? '').trim();
    if (savedAddr.isNotEmpty && printerAddr.isNotEmpty) {
      return savedAddr == printerAddr;
    }

    final savedVendor = vendorId;
    final savedProduct = productId;
    final pVendor = int.tryParse('${printer.vendorId ?? ''}');
    final pProduct = int.tryParse('${printer.productId ?? ''}');
    if (savedVendor != null &&
        savedProduct != null &&
        pVendor != null &&
        pProduct != null &&
        savedVendor == pVendor &&
        savedProduct == pProduct) {
      return true;
    }

    final savedName = (name ?? '').trim();
    final printerName = (printer.name ?? '').trim();
    if (savedName.isNotEmpty && printerName.isNotEmpty) {
      return savedName == printerName;
    }
    return false;
  }

  Future<Printer?> _findUsbPrinterForRole(String roleKey) async {
    final name = await StorageHelper.getRoleSavedUsbPrinter(roleKey);
    final vendorId = await StorageHelper.getRoleSavedUsbVendorId(roleKey);
    final productId = await StorageHelper.getRoleSavedUsbProductId(roleKey);
    final address = await StorageHelper.getRoleSavedUsbAddress(roleKey);

    for (final p in usbPrinters) {
      if (_usbPrinterMatchesSaved(
        p,
        name: name,
        vendorId: vendorId,
        productId: productId,
        address: address,
      )) {
        return p;
      }
    }
    return null;
  }

  Future<bool> _isConnectedForRole(PrintRole role) async {
    final roleKey = _roleKey(role);
    final type = await StorageHelper.getRoleLastPrinterType(roleKey);
    if (type == 'usb') {
      if (!isUsbConnected.value || connectedUsbPrinter == null) return false;
      final name = await StorageHelper.getRoleSavedUsbPrinter(roleKey);
      final vendorId = await StorageHelper.getRoleSavedUsbVendorId(roleKey);
      final productId = await StorageHelper.getRoleSavedUsbProductId(roleKey);
      final address = await StorageHelper.getRoleSavedUsbAddress(roleKey);
      return _usbPrinterMatchesSaved(
        connectedUsbPrinter!,
        name: name,
        vendorId: vendorId,
        productId: productId,
        address: address,
      );
    }
    if (type == 'bluetooth') {
      final savedId = await StorageHelper.getRoleSavedDeviceId(roleKey);
      if (savedId == null || savedId.isEmpty) return false;
      return isConnected.value &&
          connectedDevice != null &&
          connectedDevice!.remoteId.toString() == savedId &&
          (writeCharacteristic != null ||
              (Get.isRegistered<PrinterService2>() &&
                  PrinterService2.to.isConnected.value));
    }
    if (type == 'network') {
      final savedIp = await StorageHelper.getRoleSavedNetworkIp(roleKey);
      final savedPort =
          await StorageHelper.getRoleSavedNetworkPort(roleKey) ?? 9100;
      if (savedIp == null || savedIp.isEmpty) return false;
      if (_network.isConnected &&
          _network.host == savedIp &&
          _network.port == savedPort) {
        return true;
      }
      // Socket may be closed between prints; role + saved endpoint still counts.
      return isNetworkConnected.value &&
          connectedNetworkLabel.value == '$savedIp:$savedPort';
    }
    return false;
  }

  ({int w, int item, int qty, int price, int amount}) _invoiceColumns(int w) {
    return selectedPaperSize.value.invoiceColumns();
  }

  Future<bool> ensureConnectedForRole(PrintRole role) async {
    if (kIsWeb) return false;

    // Callers often show an app loader before print; drop it before any
    // reconnect wait or Connect Printer dialog (Windows overlay sits on top).
    dismissAllAppLoader();

    final roleKey = _roleKey(role);

    if (await _isConnectedForRole(role)) {
      return true;
    }

    final type = await StorageHelper.getRoleLastPrinterType(roleKey);

    if (type == 'usb') {
      await scanUsbPrinters();
      if (usbPrinters.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        await scanUsbPrinters();
      }
      final match = await _findUsbPrinterForRole(roleKey);
      if (match != null) {
        final alreadyUsb =
            isUsbConnected.value &&
            connectedUsbPrinter != null &&
            _sameUsbPrinter(connectedUsbPrinter, match);
        if (!alreadyUsb) {
          if (isUsbConnected.value && connectedUsbPrinter != null) {
            await disconnectUsbPrinter(notifyUser: false);
          }
          final ok = await connectUsbPrinter(match);
          if (!ok) return await ensureConnected();
        }
        return isUsbConnected.value && connectedUsbPrinter != null;
      }
      // Saved USB printer not available — let the user pick another.
      return await ensureConnected();
    }

    if (type == 'network') {
      final ip = await StorageHelper.getRoleSavedNetworkIp(roleKey);
      final port = await StorageHelper.getRoleSavedNetworkPort(roleKey) ?? 9100;
      if (ip != null && ip.isNotEmpty) {
        if (isNetworkConnected.value &&
            _network.host == ip &&
            _network.port == port) {
          return true;
        }
        final ok = await connectNetworkPrinter(ip, port: port);
        if (ok) return true;
      }
      return await ensureConnected();
    }

    if (type == 'bluetooth') {
      final savedId = await StorageHelper.getRoleSavedDeviceId(roleKey);
      if (savedId != null && savedId.isNotEmpty) {
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
          final ok = await connectToDevice(targetDevice!);
          if (ok) return true;
        }
        // Saved BLE printer not found — let the user pick another.
        return await ensureConnected();
      }
    }

    // No printer assigned for this role yet — let the user pick one.
    final ok = await ensureConnected();

    if (ok) {
      if (isUsbConnected.value && connectedUsbPrinter != null) {
        await assignUsbToRole(role, connectedUsbPrinter!);
      } else if (connectedDevice != null) {
        await assignBluetoothToRole(role, connectedDevice!);
      }
    }

    return ok;
  }

  Future<List<int>> _buildUsbTestEscPosBytes(PrintRole role) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      selectedPaperSize.value.escPosPaperSize,
      profile,
    );
    final roleLabel = role == PrintRole.bill ? 'Bill' : 'KOT';
    var bytes = <int>[];
    bytes += generator.text(
      'BillKaro',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.emptyLines(1);
    bytes += generator.text(
      '$roleLabel printer test',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      DateTime.now().toString(),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.emptyLines(2);
    bytes += generator.text(
      'USB test OK',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.emptyLines(2);
    bytes += generator.cut();
    return bytes;
  }

  Future<void> _printUsbEscPos(Printer printer, List<int> bytes) async {
    try {
      await FlutterThermalPrinter.instance.printData(
        printer,
        Uint8List.fromList(bytes),
        longData: true,
      );
    } catch (e) {
      debugPrint('USB printData error: $e');
      if (isUsbConnected.value) {
        unawaited(
          handleUsbPrinterWentOffline(
            notifyUser: true,
            statusMessage: 'USB printer connection lost',
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> testPrintForRole(PrintRole role) async {
    if (!await hasRolePrinter(role)) {
      throw Exception(
        'No ${role == PrintRole.bill ? 'bill' : 'KOT'} printer assigned. '
        'Tap Bill or KOT on a device in the list.',
      );
    }

    final ok = await ensureConnectedForRole(role);
    if (!ok) {
      throw Exception(
        'Could not connect to ${role == PrintRole.bill ? 'bill' : 'KOT'} printer. '
        'Check USB cable, then scan for USB printers.',
      );
    }

    final roleKey = _roleKey(role);
    final assignedType = await StorageHelper.getRoleLastPrinterType(roleKey);
    if (assignedType == 'usb' &&
        isUsbConnected.value &&
        connectedUsbPrinter != null) {
      final printer = connectedUsbPrinter!;
      try {
        final bytes = await _buildUsbTestEscPosBytes(role);
        await _printUsbEscPos(printer, bytes);
        return;
      } catch (e) {
        debugPrint('USB printData failed, trying printInfo: $e');
        try {
          FlutterThermalPrinter.instance.printInfo(
            info:
                'BillKaro\n${role == PrintRole.bill ? 'Bill' : 'KOT'} test\n'
                '${DateTime.now()}\n',
          );
          return;
        } catch (e2) {
          throw Exception('USB print failed: $e2');
        }
      }
    }

    if (assignedType == 'network') {
      final builder = PrintBuilder(receiptWidth: _receiptWidth())
        ..center()
        ..boldDoubleHeight('BillKaro\n')
        ..text('${role == PrintRole.bill ? 'Bill' : 'KOT'} printer test\n')
        ..text('${DateTime.now()}\n')
        ..feed(3)
        ..cut();
      await _printBytes(builder.bytes, forRole: role);
      return;
    }

    final builder = PrintBuilder(receiptWidth: _receiptWidth())
      ..center()
      ..boldDoubleHeight('BillKaro\n')
      ..text('${role == PrintRole.bill ? 'Bill' : 'KOT'} printer test\n')
      ..text('${DateTime.now()}\n')
      ..feed(3)
      ..cut();

    await _printBytes(builder.bytes, forRole: role);
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
    final ok = await ensureConnectedForRole(PrintRole.kot);
    if (!ok) throw Exception('No KOT printer connected');

    // Windows: PDF dialog only when no thermal path after role connect.
    if (!kIsWeb && Platform.isWindows && !hasActiveThermalPath) {
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

    final receiptW = _receiptWidth();
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

    // Items — same row layout as ThermalKOTReceipt preview
    builder.bold('${TextHelper.formatRow('Description', 'Qty.', receiptW)}\n');
    builder.line();

    for (var item in items) {
      for (final line in TextHelper.kotNameQtyLines(
        item.itemName,
        item.quantity,
        receiptW,
      )) {
        builder.text('$line\n');
      }
      for (final line in TextHelper.kotSublineLines(
        category: item.category,
        remark: item.itemRemark,
        receiptWidth: receiptW,
      )) {
        builder.text('$line\n');
      }
    }

    builder
      ..line()
      ..bold(
        TextHelper.formatRow('Total Items', '$totalQuantity', receiptW) + '\n',
      );

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

    await _printBytes(builder.bytes, forRole: PrintRole.kot);
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
    final ok = await ensureConnectedForRole(PrintRole.bill);
    if (!ok) throw Exception('No bill printer connected');

    if (!kIsWeb && Platform.isWindows && !hasActiveThermalPath) {
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

    final receiptW = _receiptWidth();
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
        '${TextHelper.formatRow('Payment In: $paymentMode', 'Time: $time', w)}\n',
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
      // Use bitmap QR for broad printer compatibility.
      // Native ESC/POS QR commands can print stray characters (e.g. "2") on some printers.
      List<int> qrCode = await QRGenerator.generateBitmap(
        upiId!.trim(),
        totalAmount,
        businessName,
        transactionNote,
      );

      if (qrCode.isNotEmpty) {
        builder.bytes.addAll(qrCode);
        builder.text('\n');
      }
      builder
        ..text('UPI ID: $upiId\n')
        ..text('Amount: Rs${totalAmount.toStringAsFixed(2)}\n');
    }

    builder.feed(3).cut();
    await _printBytes(builder.bytes, forRole: PrintRole.bill);
    await maybeOpenCashDrawerForPayment(paymentMode);
  }

  bool _isCashPayment(String paymentMode) =>
      paymentMode.trim().toLowerCase() == 'cash';

  /// Sends ESC/POS drawer-kick to the bill printer (RJ11 drawer on DK port).
  Future<void> openCashDrawer() async {
    final appPref = Get.find<AppPref>();
    if (!appPref.cashDrawerEnabled) {
      throw Exception('Cash drawer is disabled in Settings');
    }

    final ok = await ensureConnectedForRole(PrintRole.bill);
    if (!ok) {
      throw Exception('No bill printer connected');
    }

    if (!kIsWeb && Platform.isWindows && !hasActiveThermalPath) {
      throw Exception(
        'Cash drawer needs a USB, Ethernet, or Bluetooth bill printer',
      );
    }

    final pin = cashDrawerPinFromStorage(appPref.cashDrawerPin);
    final bytes = await CashDrawerHelper.buildKickBytes(pin);
    await _printBytes(bytes, forRole: PrintRole.bill);
  }

  Future<void> maybeOpenCashDrawerForPayment(String paymentMode) async {
    final appPref = Get.find<AppPref>();
    if (!appPref.cashDrawerEnabled || !appPref.openCashDrawerOnCashPayment) {
      return;
    }
    if (!_isCashPayment(paymentMode)) return;

    try {
      await openCashDrawer();
    } catch (e) {
      debugPrint('Cash drawer open failed: $e');
    }
  }

  /// Prints a table QR menu sticker/receipt on the bill printer.
  Future<void> printTableQrMenu({
    required String businessName,
    required String tableDisplayName,
    required String menuUrl,
  }) async {
    if (menuUrl.trim().isEmpty) {
      throw Exception('QR menu URL is empty');
    }

    if (!kIsWeb && Platform.isWindows && !hasActiveThermalPath) {
      await _printTableQrWindowsPdf(
        businessName: businessName,
        tableDisplayName: tableDisplayName,
        menuUrl: menuUrl,
      );
      return;
    }

    final ok = await ensureConnectedForRole(PrintRole.bill);
    if (!ok) throw Exception('No bill printer connected');

    final receiptW = _receiptWidth();
    final builder = PrintBuilder(receiptWidth: receiptW);

    builder
      ..center()
      ..feed(1);

    if (businessName.trim().isNotEmpty) {
      builder.bold('${businessName.trim()}\n');
    }

    builder
      ..boldDoubleHeight('${tableDisplayName.trim()}\n')
      ..boldNormal('')
      ..line()
      ..text('\n')
      ..bold('Scan to Order & Pay\n')
      ..text('\n');

    final qrBytes = await QRGenerator.generateUrlBitmap(menuUrl.trim());
    if (qrBytes.isNotEmpty) {
      builder.bytes.addAll(qrBytes);
      builder.text('\n');
    } else {
      builder.text('(QR generation failed)\n');
    }

    builder
      ..text('\n')
      ..text('Open camera & scan QR\n')
      ..line()
      ..text('Powered by Billkaro\n')
      ..feed(3)
      ..cut();

    await _printBytes(builder.bytes, forRole: PrintRole.bill);
  }

  /// Prints QR menu codes for multiple tables (one cut per table).
  Future<void> printAllTableQrMenus({
    required String businessName,
    required List<({String tableDisplayName, String menuUrl})> tables,
  }) async {
    final valid = tables
        .where((t) => t.menuUrl.trim().isNotEmpty)
        .toList(growable: false);
    if (valid.isEmpty) {
      throw Exception('No QR menu URLs to print');
    }

    for (final table in valid) {
      await printTableQrMenu(
        businessName: businessName,
        tableDisplayName: table.tableDisplayName,
        menuUrl: table.menuUrl,
      );
    }
  }

  Future<void> _printTableQrWindowsPdf({
    required String businessName,
    required String tableDisplayName,
    required String menuUrl,
  }) async {
    final qrPainter = QrPainter(
      data: menuUrl,
      version: QrVersions.auto,
      gapless: true,
    );
    final image = await qrPainter.toImage(240);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(height: 16),
            pw.Text(
              businessName,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              tableDisplayName,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Image(
                pw.MemoryImage(pngBytes),
                width: 180,
                height: 180,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Scan to order & pay',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Powered by Billkaro',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
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
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text('Description', style: t(b: true))),
              pw.Text('Qty.', style: t(b: true)),
            ],
          ),
          pw.Divider(),
          ...items.map((it) {
            final category = it.category.trim();
            final remark = it.itemRemark?.trim() ?? '';
            final sublineStyle = t().copyWith(
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey700,
            );
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(child: pw.Text(it.itemName, style: t())),
                      pw.Text('x${it.quantity}', style: t(b: true)),
                    ],
                  ),
                  if (category.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text('($category)', style: sublineStyle),
                  ],
                  if (remark.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text('* $remark', style: sublineStyle),
                  ],
                ],
              ),
            );
          }),
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

  /// Sends ESC/POS to the transport saved for [forRole] (USB vs Bluetooth),
  /// so bill and KOT can use different printers when both are connected.
  Future<void> _printBytes(
    List<int> bytes, {
    required PrintRole forRole,
  }) async {
    try {
      final roleKey = _roleKey(forRole);
      final type = await StorageHelper.getRoleLastPrinterType(roleKey);

      if (type == 'usb') {
        final printer = connectedUsbPrinter;
        if (!isUsbConnected.value || printer == null) {
          throw Exception(
            '${forRole == PrintRole.bill ? 'Bill' : 'KOT'}: USB printer not connected',
          );
        }
        final name = await StorageHelper.getRoleSavedUsbPrinter(roleKey);
        final vendorId = await StorageHelper.getRoleSavedUsbVendorId(roleKey);
        final productId = await StorageHelper.getRoleSavedUsbProductId(roleKey);
        final address = await StorageHelper.getRoleSavedUsbAddress(roleKey);
        if (!_usbPrinterMatchesSaved(
          printer,
          name: name,
          vendorId: vendorId,
          productId: productId,
          address: address,
        )) {
          throw Exception(
            '${forRole == PrintRole.bill ? 'Bill' : 'KOT'}: '
            'connected USB printer does not match this assignment',
          );
        }
        await _printUsbEscPos(printer, bytes);
        return;
      }

      if (type == 'network') {
        await _printBytesOverNetwork(bytes, role: forRole);
        return;
      }

      await _writeBluetoothBytes(bytes);
    } catch (e) {
      debugPrint('Print error: $e');
      rethrow;
    }
  }

  Future<void> _printBytesOverNetwork(
    List<int> bytes, {
    required PrintRole role,
  }) async {
    if (!await ensureConnectedForRole(role)) {
      throw Exception('Ethernet printer not connected');
    }
    final ok = await _network.printBytes(bytes);
    if (!ok) {
      _syncNetworkConnectionObservables(connected: false);
      throw Exception('Ethernet print failed. Check IP, port, and network.');
    }
    // printBytes closes the socket after each job; endpoint stays configured.
    _syncNetworkConnectionObservables(connected: true);
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
}
