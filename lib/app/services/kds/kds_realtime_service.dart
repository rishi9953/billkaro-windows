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

  void connect(String outletId) {
    if (outletId.isEmpty) return;
    if (_outletId == outletId && isConnected.value) return;

    disconnect(keepOutlet: true);
    _outletId = outletId;
    _disposed = false;
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
      final uri = ApiConfig.kdsWebSocketUri(outletId);
      debugPrint('🔌 [KDS WS] connecting $uri');
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (e) {
          lastError.value = e.toString();
          debugPrint('❌ [KDS WS] error: $e');
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
      isConnected.value = false;
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
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
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      if (!_disposed && _outletId != null) _openSocket();
    });
  }
}
