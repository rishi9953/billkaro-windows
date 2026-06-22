import 'dart:async';
import 'dart:convert';

import 'package:billkaro/app/services/Modals/kds/kds_bump_events_response.dart';
import 'package:billkaro/app/services/Modals/kds/kds_order_placed_event.dart';
import 'package:billkaro/app/services/Modals/kds/kds_response.dart';
import 'package:billkaro/app/services/Network/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Live KDS updates over WebSocket (`ws(s)://host/api/kds?outletId=...`).
class KdsRealtimeService {
  KdsRealtimeService._();
  static final KdsRealtimeService instance = KdsRealtimeService._();

  final _queueController = StreamController<KdsQueueData>.broadcast();
  final _bumpController = StreamController<KdsBumpEvent>.broadcast();
  final _orderPlacedController =
      StreamController<KdsOrderPlacedEvent>.broadcast();

  final RxBool isConnected = false.obs;
  final RxString lastError = ''.obs;

  Stream<KdsQueueData> get queueStream => _queueController.stream;
  Stream<KdsBumpEvent> get bumpStream => _bumpController.stream;
  Stream<KdsOrderPlacedEvent> get orderPlacedStream =>
      _orderPlacedController.stream;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  String? _outletId;
  Timer? _reconnectTimer;
  bool _disposed = false;
  int _reconnectAttempts = 0;
  bool _localRefusedHintLogged = false;
  bool _preferRemote = false;

  static const _baseReconnectDelay = Duration(seconds: 4);
  static const _maxReconnectDelay = Duration(seconds: 60);

  void connect(String outletId) {
    if (outletId.isEmpty) return;
    if (_outletId == outletId && isConnected.value) return;

    disconnect(keepOutlet: true);
    _outletId = outletId;
    _disposed = false;
    _reconnectAttempts = 0;
    _localRefusedHintLogged = false;
    _preferRemote = false;
    _openSocket();
  }

  void disconnect({bool keepOutlet = false}) {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _disposed = true;
    if (!keepOutlet) _outletId = null;
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (e) {
      debugPrint('⚠️ [KDS WS] close error: $e');
    }
    _channel = null;
    isConnected.value = false;
  }

  void _openSocket() {
    final outletId = _outletId;
    if (outletId == null) return;

    _disposed = false;
    _subscription?.cancel();
    try {
      _channel?.sink.close();
    } catch (e) {
      debugPrint('⚠️ [KDS WS] close error: $e');
    }

    try {
      final uri = ApiConfig.kdsWebSocketUri(
        outletId,
        forceRemote: _preferRemote,
      );
      debugPrint('🔌 [KDS WS] connecting $uri');
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (e) {
          lastError.value = e.toString();
          debugPrint('❌ [KDS WS] error: $e');
          if (_tryFallbackToRemote(e, uri)) return;
          _logLocalConnectionHintIfNeeded(e, uri);
          isConnected.value = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('⚠️ [KDS WS] closed');
          isConnected.value = false;
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      lastError.value = e.toString();
      debugPrint('❌ [KDS WS] connect failed: $e');
      final uri = ApiConfig.kdsWebSocketUri(
        outletId,
        forceRemote: _preferRemote,
      );
      if (_tryFallbackToRemote(e, uri)) return;
      _logLocalConnectionHintIfNeeded(e, uri);
      isConnected.value = false;
      _scheduleReconnect();
    }
  }

  /// When local Nest is down but REST uses a remote host, switch to remote WSS.
  bool _tryFallbackToRemote(Object error, Uri uri) {
    if (_preferRemote || uri.host != '127.0.0.1') return false;
    if (!ApiConfig.hasRemoteKdsWebSocket) return false;

    final message = error.toString().toLowerCase();
    if (!message.contains('refused') && !message.contains('1225')) {
      return false;
    }

    _preferRemote = true;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    debugPrint(
      '💡 [KDS WS] Local backend unavailable — falling back to remote API WebSocket',
    );
    isConnected.value = false;
    _openSocket();
    return true;
  }

  void _logLocalConnectionHintIfNeeded(Object error, Uri uri) {
    if (_localRefusedHintLogged || uri.host != '127.0.0.1') return;
    final message = error.toString().toLowerCase();
    if (!message.contains('refused') && !message.contains('1225')) return;

    _localRefusedHintLogged = true;
    debugPrint(
      '💡 [KDS WS] No server on $uri. Start billkaro-backend locally '
      'or set KDS_WS_USE_LOCAL=false in .env to use the REST API host.',
    );
  }

  void _onMessage(dynamic raw) {
    _reconnectAttempts = 0;
    isConnected.value = true;
    lastError.value = '';
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = map['event']?.toString() ?? '';
      final data = map['data'];
      if (event == 'queue' && data is Map<String, dynamic>) {
        _queueController.add(KdsQueueData.fromJson(data));
      } else if (event == 'bumped' && data is Map<String, dynamic>) {
        _bumpController.add(KdsBumpEvent.fromJson(data));
      } else if (event == 'orderPlaced' && data is Map<String, dynamic>) {
        _orderPlacedController.add(KdsOrderPlacedEvent.fromJson(data));
      }
    } catch (e) {
      debugPrint('⚠️ [KDS WS] parse error: $e');
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _outletId == null) return;
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final multiplier = 1 << (_reconnectAttempts - 1).clamp(0, 4);
    final delaySeconds = (_baseReconnectDelay.inSeconds * multiplier).clamp(
      _baseReconnectDelay.inSeconds,
      _maxReconnectDelay.inSeconds,
    );
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_disposed && _outletId != null) _openSocket();
    });
  }
}
