import 'dart:async';
import 'dart:io';

import 'package:billkaro/app/services/remote_barcode/remote_barcode_protocol.dart';
import 'package:flutter/foundation.dart';

/// Hosts a short-lived LAN WebSocket so a phone can send barcodes to Windows.
class RemoteBarcodeHostService {
  HttpServer? _server;
  WebSocket? _client;
  StreamSubscription? _serverSub;
  StreamSubscription? _clientSub;
  final _barcodeController = StreamController<String>.broadcast();
  final _statusController = StreamController<RemoteBarcodeHostStatus>.broadcast();

  String? token;
  String? lanIp;
  int port = RemoteBarcodeProtocol.defaultPort;
  var phoneConnected = false;

  Stream<String> get barcodes => _barcodeController.stream;
  Stream<RemoteBarcodeHostStatus> get status => _statusController.stream;

  String? get pairingPayload {
    if (lanIp == null || token == null) return null;
    return RemoteBarcodeProtocol.buildPairingPayload(
      host: lanIp!,
      port: port,
      token: token!,
    );
  }

  Future<void> start({String mode = 'menu'}) async {
    await stop();

    lanIp = await _resolveLanIpv4();
    if (lanIp == null) {
      throw StateError(
        'No Wi‑Fi / LAN IP found. Connect this PC to the same Wi‑Fi as your phone.',
      );
    }

    token = RemoteBarcodeProtocol.newToken();
    phoneConnected = false;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } catch (_) {
      // Port busy — try an ephemeral port.
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      port = _server!.port;
    }

    _emitStatus();
    _serverSub = _server!.listen(_handleRequest, onError: (e, st) {
      debugPrint('RemoteBarcodeHostService server error: $e\n$st');
    });
  }

  Future<void> stop() async {
    await _clientSub?.cancel();
    _clientSub = null;
    try {
      await _client?.close();
    } catch (_) {}
    _client = null;

    await _serverSub?.cancel();
    _serverSub = null;
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;

    phoneConnected = false;
    token = null;
    _emitStatus();
  }

  Future<void> dispose() async {
    await stop();
    await _barcodeController.close();
    await _statusController.close();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.uri.path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('ok');
      await request.response.close();
      return;
    }

    if (request.uri.path != '/scan' ||
        !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final reqToken = request.uri.queryParameters['token'];
    if (reqToken == null || reqToken != token) {
      request.response.statusCode = HttpStatus.unauthorized;
      await request.response.close();
      return;
    }

    // Only one phone at a time.
    try {
      await _client?.close();
    } catch (_) {}
    await _clientSub?.cancel();

    final socket = await WebSocketTransformer.upgrade(request);
    _client = socket;
    phoneConnected = true;
    _emitStatus();

    try {
      socket.add(RemoteBarcodeProtocol.encodeHello(role: 'windows'));
    } catch (_) {}

    _clientSub = socket.listen(
      (message) {
        final code = RemoteBarcodeProtocol.decodeBarcodeEvent(message);
        if (code != null && !_barcodeController.isClosed) {
          _barcodeController.add(code);
        }
      },
      onDone: () {
        phoneConnected = false;
        _client = null;
        _emitStatus();
      },
      onError: (e, st) {
        debugPrint('RemoteBarcodeHostService client error: $e\n$st');
        phoneConnected = false;
        _client = null;
        _emitStatus();
      },
      cancelOnError: true,
    );
  }

  void _emitStatus() {
    if (_statusController.isClosed) return;
    _statusController.add(
      RemoteBarcodeHostStatus(
        running: _server != null,
        phoneConnected: phoneConnected,
        lanIp: lanIp,
        port: port,
        pairingPayload: pairingPayload,
      ),
    );
  }

  static Future<String?> _resolveLanIpv4() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );

    // Prefer common Wi‑Fi / Ethernet names.
    final preferred = <NetworkInterface>[];
    final others = <NetworkInterface>[];
    for (final iface in interfaces) {
      final name = iface.name.toLowerCase();
      final isVirtual = name.contains('vethernet') ||
          name.contains('virtual') ||
          name.contains('vmware') ||
          name.contains('hyper-v') ||
          name.contains('docker') ||
          name.contains('wsl') ||
          name.contains('loopback');
      if (isVirtual) continue;
      final isPreferred = name.contains('wi-fi') ||
          name.contains('wifi') ||
          name.contains('wlan') ||
          name.contains('ethernet') ||
          name.contains('en0') ||
          name.contains('eth');
      if (isPreferred) {
        preferred.add(iface);
      } else {
        others.add(iface);
      }
    }

    for (final iface in [...preferred, ...others]) {
      for (final addr in iface.addresses) {
        if (addr.isLoopback) continue;
        final ip = addr.address;
        // Skip link-local / APIPA.
        if (ip.startsWith('169.254.')) continue;
        return ip;
      }
    }
    return null;
  }
}

class RemoteBarcodeHostStatus {
  const RemoteBarcodeHostStatus({
    required this.running,
    required this.phoneConnected,
    required this.lanIp,
    required this.port,
    required this.pairingPayload,
  });

  final bool running;
  final bool phoneConnected;
  final String? lanIp;
  final int port;
  final String? pairingPayload;
}
