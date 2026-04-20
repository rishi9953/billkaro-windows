class ApiConstants {
  static const String local = 'https://nmsmfkdd-3000.inc1.devtunnels.ms/api/';
  // static const String prod = 'https://65.2.81.212/api/';
  static const String prod = 'https://api.billkrochillkro.com/api/';
}

const String baseURL = ApiConstants.prod;

/// Stored logo/media paths from the API may be full URLs or relative paths.
/// Returns a URL suitable for [Image.network].
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
const String categories = 'categories';
const String outlets = 'outlets';
const String mediaUrl = 'media/upload';
const String regularCustomer = 'regularCustomer';
const String user = 'users';
const String orders = 'orders';
const String subscriptions = 'subscription-plans';
const String outletTables = 'outlet-tables';
const String createPaymentOrder = 'payments/create-order';
const String subscribe = 'payments/subscribe';
const String businessTypes = 'services';
const String forgotPass = 'auth/forgot-password';
const String printerOrder = 'printer-orders';
const String staff = 'staff';
