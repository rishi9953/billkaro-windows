import 'dart:async';
import 'dart:convert';

import 'package:billkaro/app/modules/Shell/Sidebar/app_shell_sidebar_controller.dart';
import 'package:billkaro/app/modules/Wallet/wallet_controller.dart';
import 'package:billkaro/app/services/Network/api_config.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Live wallet balance over WebSocket (`ws(s)://host/api/wallet?outletId=...`).
class WalletRealtimeService {
  WalletRealtimeService._();
  static final WalletRealtimeService instance = WalletRealtimeService._();

  final RxBool isConnected = false.obs;
  final RxString lastError = ''.obs;

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
      debugPrint('⚠️ [Wallet WS] close error: $e');
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
      debugPrint('⚠️ [Wallet WS] close error: $e');
    }

    try {
      final uri = ApiConfig.walletWebSocketUri(
        outletId,
        forceRemote: _preferRemote,
      );
      debugPrint('🔌 [Wallet WS] connecting $uri');
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (e) {
          lastError.value = e.toString();
          debugPrint('❌ [Wallet WS] error: $e');
          if (_tryFallbackToRemote(e, uri)) return;
          _logLocalConnectionHintIfNeeded(e, uri);
          isConnected.value = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('⚠️ [Wallet WS] closed');
          isConnected.value = false;
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      lastError.value = e.toString();
      debugPrint('❌ [Wallet WS] connect failed: $e');
      final uri = ApiConfig.walletWebSocketUri(
        outletId,
        forceRemote: _preferRemote,
      );
      if (_tryFallbackToRemote(e, uri)) return;
      _logLocalConnectionHintIfNeeded(e, uri);
      isConnected.value = false;
      _scheduleReconnect();
    }
  }

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
      '💡 [Wallet WS] Local backend unavailable — falling back to remote API WebSocket',
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
      '💡 [Wallet WS] No server on $uri. Start billkaro-backend locally '
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
      if (event != 'walletUpdated') return;
      final data = map['data'];
      if (data is! Map) return;
      _applyBalanceUpdate(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint('⚠️ [Wallet WS] parse error: $e');
    }
  }

  void _applyBalanceUpdate(Map<String, dynamic> data) {
    final outletId = data['outletId']?.toString();
    final balance = (data['balance'] as num?)?.toDouble();
    if (balance == null) return;

    final selectedId =
        Get.isRegistered<AppPref>()
            ? Get.find<AppPref>().selectedOutlet?.id
            : null;
    if (outletId != null &&
        selectedId != null &&
        outletId.isNotEmpty &&
        outletId != selectedId) {
      return;
    }

    final targetOutletId = outletId?.isNotEmpty == true ? outletId : selectedId;
    if (Get.isRegistered<AppPref>() && targetOutletId != null) {
      Get.find<AppPref>().setWalletBalanceForOutlet(targetOutletId, balance);
    }

    final threshold = (data['lowBalanceThreshold'] as num?)?.toDouble();

    if (Get.isRegistered<WalletController>()) {
      Get.find<WalletController>().applyRealtimeBalance(
        balance,
        lowBalanceThreshold: threshold,
      );
    }

    if (Get.isRegistered<AppShellSidebarController>()) {
      final shell = Get.find<AppShellSidebarController>();
      shell.applyRealtimeWalletBalance(
        balance,
        lowBalanceThreshold: threshold,
      );
    }

    debugPrint('💰 [Wallet WS] balance=$balance outlet=$targetOutletId');
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
