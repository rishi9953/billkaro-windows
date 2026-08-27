import 'dart:async';
import 'dart:convert';

import 'package:billkaro/app/services/Network/api_config.dart';
import 'package:billkaro/app/services/auth/auth_session_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Live session events over WebSocket (`ws(s)://host/api/session?token=...`).
class SessionRealtimeService {
  SessionRealtimeService._();
  static final SessionRealtimeService instance = SessionRealtimeService._();

  final RxBool isConnected = false.obs;
  final RxString lastError = ''.obs;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  String? _token;
  bool _disposed = false;
  bool _handlingLogout = false;

  void connect(String token) {
    if (token.isEmpty) return;
    if (_token == token && isConnected.value) return;

    disconnect(keepToken: true);
    _token = token;
    _disposed = false;
    _openSocket();
  }

  void disconnect({bool keepToken = false}) {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _disposed = true;
    if (!keepToken) _token = null;
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    isConnected.value = false;
  }

  void _openSocket() {
    final token = _token;
    if (token == null) return;

    _disposed = false;
    _subscription?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}

    try {
      final uri = ApiConfig.sessionWebSocketUri(token);
      debugPrint('🔌 [Session WS] connecting $uri');
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (e) {
          lastError.value = e.toString();
          debugPrint('❌ [Session WS] error: $e');
          isConnected.value = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('⚠️ [Session WS] closed');
          isConnected.value = false;
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      lastError.value = e.toString();
      debugPrint('❌ [Session WS] connect failed: $e');
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
      if (event == 'accountDeactivated') {
        _handleAccountDeactivated(map['data']);
      }
    } catch (e) {
      debugPrint('⚠️ [Session WS] parse error: $e');
    }
  }

  Future<void> _handleAccountDeactivated(dynamic data) async {
    if (_handlingLogout) return;
    _handlingLogout = true;

    final reason = data is Map ? data['reason']?.toString() : null;
    final isStaffKick =
        reason == 'staff_revoked' || reason == 'staff_deactivated';
    final email = Get.isRegistered<AppPref>()
        ? Get.find<AppPref>().user?.email?.trim()
        : null;

    disconnect();

    final message = reason == 'staff_deactivated'
        ? AuthSessionService.staffDeactivatedMessage
        : reason == 'staff_revoked'
            ? 'Your staff access has been revoked. Please contact your outlet owner.'
            : 'Your account has been deactivated. Resend the activation link to your email to reactivate your account.';

    try {
      await AuthSessionService.performForcedLogout(
        message: message,
        email: email,
        canResendActivation: !isStaffKick,
        title: isStaffKick ? 'Staff Deactivated' : 'Account Deactivated',
      );
    } finally {
      _handlingLogout = false;
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _token == null || _handlingLogout) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_disposed && _token != null && !_handlingLogout) _openSocket();
    });
  }
}
