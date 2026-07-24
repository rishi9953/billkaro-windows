import 'dart:convert';
import 'dart:math';

/// Shared pairing + message protocol for phone → Windows barcode relay.
abstract final class RemoteBarcodeProtocol {
  static const int defaultPort = 47821;
  static const String qrScheme = 'billkaro';
  static const String qrHost = 'remote-scan';

  static String newToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Payload encoded in the Windows pairing QR.
  static String buildPairingPayload({
    required String host,
    required int port,
    required String token,
    String mode = 'menu',
  }) {
    final ws = 'ws://$host:$port/scan?token=$token';
    return Uri(
      scheme: qrScheme,
      host: qrHost,
      queryParameters: {
        'ws': ws,
        'token': token,
        'mode': mode,
        'v': '1',
      },
    ).toString();
  }

  static Map<String, String>? parsePairingPayload(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Prefer URI form: billkaro://remote-scan?ws=...&token=...
    try {
      final uri = Uri.parse(trimmed);
      if (uri.scheme == qrScheme && uri.host == qrHost) {
        final ws = uri.queryParameters['ws'];
        final token = uri.queryParameters['token'];
        if (ws != null &&
            ws.isNotEmpty &&
            token != null &&
            token.isNotEmpty) {
          return {
            'ws': ws,
            'token': token,
            'mode': uri.queryParameters['mode'] ?? 'menu',
          };
        }
      }
    } catch (_) {}

    // Fallback JSON: {"ws":"...","token":"..."}
    try {
      final json = jsonDecode(trimmed);
      if (json is Map) {
        final ws = json['ws']?.toString();
        final token = json['token']?.toString();
        if (ws != null &&
            ws.isNotEmpty &&
            token != null &&
            token.isNotEmpty) {
          return {
            'ws': ws,
            'token': token,
            'mode': json['mode']?.toString() ?? 'menu',
          };
        }
      }
    } catch (_) {}

    return null;
  }

  static String encodeBarcodeEvent(String code) {
    return jsonEncode({
      'event': 'barcode',
      'data': {'code': code},
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static String? decodeBarcodeEvent(dynamic message) {
    try {
      final json = message is String ? jsonDecode(message) : message;
      if (json is! Map) return null;
      if (json['event']?.toString() != 'barcode') return null;
      final data = json['data'];
      if (data is Map) {
        final code = data['code']?.toString().trim();
        if (code != null && code.isNotEmpty) return code;
      }
      final direct = json['code']?.toString().trim();
      if (direct != null && direct.isNotEmpty) return direct;
    } catch (_) {}
    return null;
  }

  static String encodeHello({required String role}) {
    return jsonEncode({
      'event': 'hello',
      'data': {'role': role},
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
