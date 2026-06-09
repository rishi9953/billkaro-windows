import 'dart:io';

import 'package:billkaro/app/services/Network/urls.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime API base URL (loaded from `.env` after [loadApiConfig]).
class ApiConfig {
  ApiConfig._();

  static String _defaultTunnelBase = ApiConstants.defaultBase;

  static String _baseUrl = _defaultTunnelBase;
  static String _qrMenuBaseUrl = '';

  static String get baseUrl => _baseUrl;

  /// Customer table QR menu base (from `.env` `QR_MENU_BASE_URL`).
  /// Empty = derive from [baseUrl] + `/qr-menu/menu`.
  static String get qrMenuBaseUrl => _qrMenuBaseUrl;

  /// Call once after `dotenv.load` in `main.dart`.
  static void loadFromEnv() {
    final fromEnv = dotenv.env['API_BASE_URL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      _baseUrl = fromEnv.endsWith('/') ? fromEnv : '$fromEnv/';
    } else {
      _baseUrl = _defaultTunnelBase;
    }

    _qrMenuBaseUrl = dotenv.env['QR_MENU_BASE_URL']?.trim() ?? '';

    debugPrint('🌐 [API] REST base: $_baseUrl');
    debugPrint(
      '📱 [API] QR menu base: ${_qrMenuBaseUrl.isNotEmpty ? _qrMenuBaseUrl : '(from API URL)'}',
    );
    debugPrint('🔌 [API] KDS WebSocket: ${kdsWebSocketUri('outlet')} (sample)');
  }

  /// WebSocket for KDS — on Windows dev, prefer local backend (tunnel REST + local WS).
  static Uri kdsWebSocketUri(String outletId) {
    if (!kIsWeb && Platform.isWindows && _useLocalKdsWebSocket) {
      final port =
          int.tryParse(dotenv.env['KDS_WS_LOCAL_PORT']?.trim() ?? '3000') ??
          3000;
      final uri = Uri(
        scheme: 'ws',
        host: '127.0.0.1',
        port: port,
        path: '/api/kds',
        queryParameters: {'outletId': outletId},
      );
      return uri;
    }

    final api = Uri.parse(_baseUrl);
    final wsScheme = api.scheme == 'https' ? 'wss' : 'ws';
    var path = api.path;
    if (!path.endsWith('/')) path = '$path/';
    if (!path.contains('/api')) {
      path = '${path}api/';
    }
    final kdsPath = '${path}kds';

    return Uri(
      scheme: wsScheme,
      host: api.host,
      port: api.hasPort ? api.port : null,
      path: kdsPath,
      queryParameters: {'outletId': outletId},
    );
  }

  static bool get _useLocalKdsWebSocket {
    final flag = dotenv.env['KDS_WS_USE_LOCAL']?.trim().toLowerCase();
    if (flag == 'false' || flag == '0') return false;
    if (flag == 'true' || flag == '1') return true;
    // Default: use same host as REST API. Opt in to local WS via .env.
    return false;
  }
}
