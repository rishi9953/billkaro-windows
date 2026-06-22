import 'package:billkaro/app/services/Network/api_config.dart';

class ApiConstants {
  static const String local = 'https://nmsmfkdd-3000.inc1.devtunnels.ms/api/';
  static const String prod = 'https://api.billkrochillkro.com/api/';
  static const String instance = 'https://65.2.81.212/api/';
  static const String dev = 'https://dev.api.billkrochillkro.com/api/';

  /// Default REST base when `.env` does not set `API_BASE_URL`.
  static const String defaultBase = prod;
}

/// Use [ApiConfig.baseUrl] after `ApiConfig.loadFromEnv()` in main.
String get baseURL => ApiConfig.baseUrl;

/// Stored logo/media paths from the API may be full URLs or relative paths.
String resolvedMediaUrl(String? stored) {
  if (stored == null) return '';
  final s = stored.trim();
  if (s.isEmpty) return '';
  final lower = s.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) return s;
  try {
    final baseUri = Uri.parse(baseURL);
    final origin = baseUri.hasPort
        ? '${baseUri.scheme}://${baseUri.host}:${baseUri.port}'
        : '${baseUri.scheme}://${baseUri.host}';
    if (s.startsWith('/')) {
      return '$origin$s';
    }
    final basePath = baseUri.path;
    final joined = basePath.endsWith('/') ? '$basePath$s' : '$basePath/$s';
    return baseUri.replace(path: joined).toString();
  } catch (_) {
    return s;
  }
}

const String register = 'auth/register';
const String login = 'auth/login';
const String profile = 'auth/profile';
const String items = 'items';
const String bulkItems = 'items/bulk';
const String categories = 'categories';
const String outlets = 'outlets';
const String mediaUrl = 'media/upload';
const String regularCustomer = 'regularCustomer';
const String user = 'users';
const String orders = 'orders';
const String subscriptions = 'subscription-plans';
const String outletTables = 'outlet-tables';
const String tableReservations = 'table-reservations';
const String createPaymentOrder = 'payments/create-order';
const String subscribe = 'payments/subscribe';
const String businessTypes = 'services';
const String forgotPass = 'auth/forgot-password';
const String verifyEmail = 'auth/verify-email';
const String checkEmail = 'auth/check-email';
const String resendActivation = 'auth/resend-activation';
const String printerOrder = 'printer-orders';
const String staff = 'staff';
const String staffLogin = 'auth/staff/login';
const String staffProfile = 'outlets/staff/profile';
const String activities = 'activities';
const String kds = 'kds';
const String inventory = 'inventory';
