import 'package:flutter_thermal_printer/network/network_printer.dart';
import 'package:flutter_thermal_printer/network/network_print_result.dart';

/// TCP/IP (Ethernet/Wi‑Fi) ESC/POS printer on port 9100 by default.
class NetworkPrinterHelper {
  FlutterThermalPrinterNetwork? _client;
  String? _host;
  int _port = 9100;

  String? get host => _host;
  int get port => _port;
  bool get isConnected => _client?.isConnected ?? false;

  /// True when an IP/port is configured (socket may be closed after print).
  bool get hasActiveEndpoint =>
      _host != null && _host!.trim().isNotEmpty;

  String? get connectionLabel => hasActiveEndpoint ? '$_host:$_port' : null;

  Future<bool> connect(String host, {int port = 9100}) async {
    final trimmed = host.trim();
    if (trimmed.isEmpty) return false;

    await disconnect();
    _host = trimmed;
    _port = port;
    _client = FlutterThermalPrinterNetwork(trimmed, port: port);
    final result = await _client!.connect();
    if (result != NetworkPrintResult.success) {
      await disconnect();
      return false;
    }
    return true;
  }

  Future<void> disconnect() async {
    if (_client != null) {
      await _client!.disconnect();
    }
    _client = null;
    _host = null;
  }

  Future<bool> printBytes(
    List<int> bytes, {
    bool disconnectAfter = true,
  }) async {
    if (_client == null || !_client!.isConnected) {
      if (_host == null) return false;
      final ok = await connect(_host!, port: _port);
      if (!ok) return false;
    }
    final result = await _client!.printTicket(
      bytes,
      isDisconnect: disconnectAfter,
    );
    if (disconnectAfter) {
      _client = null;
    }
    return result == NetworkPrintResult.success;
  }
}
