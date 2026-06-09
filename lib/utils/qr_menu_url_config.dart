import 'package:billkaro/app/services/Modals/tables/tables_response.dart';

import 'package:billkaro/app/services/Network/api_config.dart';

import 'package:billkaro/config/app_pref.dart';

/// Builds customer table QR menu URLs from `.env` + table token.

class QrMenuUrlConfig {
  QrMenuUrlConfig._();

  static const String menuPathSuffix = '/qr-menu/menu';

  /// Default menu base derived from `API_BASE_URL` in `.env`.

  static String defaultBaseFromApi() {
    var api = ApiConfig.baseUrl.trim();

    while (api.endsWith('/')) {
      api = api.substring(0, api.length - 1);
    }

    if (api.isEmpty) return menuPathSuffix;

    return '$api$menuPathSuffix';
  }

  /// Normalizes user input (tunnel origin, /api, or full menu path).

  static String normalizeBaseUrl(String raw) {
    var s = raw.trim();

    if (s.isEmpty) return defaultBaseFromApi();

    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }

    final lower = s.toLowerCase();

    if (lower.endsWith(menuPathSuffix)) return s;

    if (lower.endsWith('/api')) return '$s$menuPathSuffix';

    try {
      final uri = Uri.parse(s);

      if (!uri.hasScheme) {
        return normalizeBaseUrl('https://$s');
      }

      final host = uri.host;

      if (host.isEmpty) return defaultBaseFromApi();

      final port = uri.hasPort ? ':${uri.port}' : '';

      final origin = '${uri.scheme}://$host$port';

      final path = uri.path;

      if (path.isEmpty || path == '/') {
        return '$origin/api$menuPathSuffix';
      }

      if (path.endsWith('/api')) {
        return '$origin$path$menuPathSuffix';
      }
    } catch (_) {
      // fall through
    }

    return '$s/api$menuPathSuffix';
  }

  /// Priority: `.env` `QR_MENU_BASE_URL` → Settings pref → `API_BASE_URL`/qr-menu/menu

  static String effectiveBaseUrl(AppPref pref) {
    final fromEnv = ApiConfig.qrMenuBaseUrl.trim();

    if (fromEnv.isNotEmpty) {
      return normalizeBaseUrl(fromEnv);
    }

    final custom = pref.qrMenuBaseUrl.trim();

    if (custom.isNotEmpty) return normalizeBaseUrl(custom);

    return defaultBaseFromApi();
  }

  static String buildTableMenuUrl(String qrToken, {required AppPref pref}) {
    final token = qrToken.trim();

    if (token.isEmpty) return '';

    return '${effectiveBaseUrl(pref)}?t=${Uri.encodeComponent(token)}';
  }

  static String buildForTable(TableModel table, AppPref pref) {
    final token = table.qrToken?.trim();

    if (token != null && token.isNotEmpty) {
      return buildTableMenuUrl(token, pref: pref);
    }

    return table.qrMenuUrl?.trim() ?? '';
  }
}
