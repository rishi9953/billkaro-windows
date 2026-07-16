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

    if (_useLocalKdsWebSocket &&
        !_baseUrl.contains('127.0.0.1') &&
        !_baseUrl.contains('localhost')) {
      final port = dotenv.env['KDS_WS_LOCAL_PORT']?.trim() ?? '3000';
      debugPrint(
        '⚠️ [API] KDS_WS_USE_LOCAL=true but REST API is remote ($_baseUrl). '
        'Ensure billkaro-backend is running on 127.0.0.1:$port, '
        'or set KDS_WS_USE_LOCAL=false in .env',
      );
    }
    debugPrint(
      '🔌 [API] Session WebSocket: ${sessionWebSocketUri('token')} (sample)',
    );
  }

  /// WebSocket for KDS — on Windows dev, prefer local backend (tunnel REST + local WS).
  static Uri kdsWebSocketUri(String outletId, {bool forceRemote = false}) {
    if (!forceRemote &&
        !kIsWeb &&
        Platform.isWindows &&
        _useLocalKdsWebSocket) {
      final port =
          int.tryParse(dotenv.env['KDS_WS_LOCAL_PORT']?.trim() ?? '3000') ??
          3000;
      return Uri(
        scheme: 'ws',
        host: '127.0.0.1',
        port: port,
        path: '/api/kds',
        queryParameters: {'outletId': outletId},
      );
    }

    return _remoteKdsWebSocketUri(outletId);
  }

  /// True when REST [baseUrl] points at a remote host (production / tunnel).
  static bool get hasRemoteKdsWebSocket {
    final api = Uri.tryParse(_baseUrl);
    if (api == null || api.host.isEmpty) return false;
    final host = api.host.toLowerCase();
    return host != '127.0.0.1' && host != 'localhost';
  }

  static Uri _remoteKdsWebSocketUri(String outletId) {
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

  /// WebSocket for session events (account deactivation, etc.).
  static Uri sessionWebSocketUri(String token, {bool forceRemote = false}) {
    if (!forceRemote &&
        !kIsWeb &&
        Platform.isWindows &&
        _useLocalKdsWebSocket) {
      final port =
          int.tryParse(dotenv.env['KDS_WS_LOCAL_PORT']?.trim() ?? '3000') ??
          3000;
      return Uri(
        scheme: 'ws',
        host: '127.0.0.1',
        port: port,
        path: '/api/session',
        queryParameters: {'token': token},
      );
    }

    final api = Uri.parse(_baseUrl);
    final wsScheme = api.scheme == 'https' ? 'wss' : 'ws';
    var path = api.path;
    if (!path.endsWith('/')) path = '$path/';
    if (!path.contains('/api')) {
      path = '${path}api/';
    }
    final sessionPath = '${path}session';

    return Uri(
      scheme: wsScheme,
      host: api.host,
      port: api.hasPort ? api.port : null,
      path: sessionPath,
      queryParameters: {'token': token},
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
