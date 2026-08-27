import 'package:billkaro/app/modules/Theme/theme_controller.dart';
import 'package:billkaro/app/services/razorpay/razorpay_web_checkout.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

bool get isRazorpayNativeSdkSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

bool get isRazorpayWebCheckoutSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

class RazorpayService {
  static final RazorpayService _instance = RazorpayService._internal();
  factory RazorpayService() => _instance;
  RazorpayService._internal();

  static const String defaultMerchantUpiId = '9582222724@pthdfc';
  static const String testUpiId = 'success@razorpay';

  static String get merchantUpiId {
    final fromEnv = dotenv.env['RAZORPAY_MERCHANT_UPI_ID']?.trim() ?? '';
    return fromEnv.isNotEmpty ? fromEnv : defaultMerchantUpiId;
  }

  static String get walletUpiId => isTestMode ? testUpiId : merchantUpiId;

  static bool get isTestMode =>
      (dotenv.env['RAZORPAY_ENVIRONMENT'] ?? 'test') != 'production';

  Razorpay? _razorpay;
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  static String get keyId {
    final environment = dotenv.env['RAZORPAY_ENVIRONMENT'] ?? 'test';
    final isProduction = environment == 'production';
    final key = isProduction
        ? dotenv.env['RAZORPAY_KEY_PRODUCTION']
        : dotenv.env['RAZORPAY_KEY_TEST'];
    if (key == null || key.trim().isEmpty) {
      throw Exception(
        isProduction
            ? 'RAZORPAY_KEY_PRODUCTION not found in .env file'
            : 'RAZORPAY_KEY_TEST not found in .env file',
      );
    }
    final trimmed = key.trim();
    final expectedPrefix = isProduction ? 'rzp_live_' : 'rzp_test_';
    if (!trimmed.startsWith(expectedPrefix) ||
        trimmed.contains('xxxxx') ||
        trimmed.length < 20) {
      throw Exception(
        'Invalid Razorpay key for $environment. '
        'Expected a real $expectedPrefix key in .env '
        '(and RAZORPAY_ENVIRONMENT=$environment).',
      );
    }
    return trimmed;
  }

  /// Razorpay expects `+{country}{number}`. Without a country code it defaults
  /// to `+1`, which hides Indian UPI on live checkout.
  static String normalizeContact(String? contact) {
    final digits = (contact ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.length >= 12 && digits.startsWith('91')) {
      return '+${digits.substring(digits.length - 12)}';
    }
    if (digits.length >= 10) {
      return '+91${digits.substring(digits.length - 10)}';
    }
    return digits.startsWith('+') ? digits : '+$digits';
  }

  String _checkoutThemeColor() {
    if (Get.isRegistered<ThemeController>()) {
      return ThemeController.hexRgbString(
        Get.find<ThemeController>().themeColor.value,
      );
    }
    return '#12B3A3';
  }

  void initialize({
    Function(PaymentSuccessResponse)? onSuccess,
    Function(PaymentFailureResponse)? onFailure,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    this.onSuccess = onSuccess;
    this.onFailure = onFailure;
    this.onExternalWallet = onExternalWallet;

    if (!isRazorpayNativeSdkSupported) {
      debugPrint('Razorpay native SDK skipped; desktop uses WebView checkout.');
      return;
    }

    _razorpay?.clear();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    onExternalWallet?.call(response);
  }

  void openCheckout({
    required int amountInPaise,
    required String name,
    required String description,
    String? email,
    String? contact,
    String? orderId,
    Map<String, dynamic>? prefill,
    Map<String, dynamic>? notes,
  }) {
    try {
      if (amountInPaise <= 0) {
        throw Exception('Invalid amountInPaise: $amountInPaise');
      }

      final hasOrderId = orderId != null && orderId.isNotEmpty;
      final normalizedContact = normalizeContact(contact);
      final trimmedEmail = (email ?? '').trim();
      final options = <String, dynamic>{
        'key': keyId,
        'currency': 'INR',
        'name': 'BillKaro ChillKaro',
        'description': description,
        // SDK expects amount as int (paise), not a string.
        'amount': amountInPaise,
        'prefill': {
          if (normalizedContact.isNotEmpty) 'contact': normalizedContact,
          if (trimmedEmail.isNotEmpty) 'email': trimmedEmail,
          ...?prefill,
        },
        'notes': notes ?? {},
        'theme': {
          'color': _checkoutThemeColor(),
          'backdrop_color': 'transparent',
        },
        'modal': {'backdropclose': false, 'escape': true, 'animation': true},
        if (hasOrderId) 'order_id': orderId,
      };

      debugPrint(
        'Opening Razorpay checkout: amount=$amountInPaise, '
        'orderId=${orderId ?? ''}, testMode=$isTestMode, '
        'contact=${normalizedContact.isNotEmpty}',
      );

      if (isRazorpayNativeSdkSupported) {
        if (_razorpay == null) {
          showError(
            title: 'Payment not available',
            description:
                'Payment could not be initialized. Please restart the app and try again.',
          );
          return;
        }
        _razorpay!.open(options);
        return;
      }

      if (isRazorpayWebCheckoutSupported) {
        if (onSuccess == null || onFailure == null) {
          showError(
            title: 'Payment Error',
            description: 'Payment callbacks are not configured.',
          );
          return;
        }
        if (Get.context == null) {
          showError(
            title: 'Payment Error',
            description: 'No valid screen context to open checkout.',
          );
          return;
        }
        RazorpayWebCheckout.open(
          checkoutOptions: options,
          onSuccess: onSuccess!,
          onFailure: onFailure!,
        );
        return;
      }

      showError(
        title: 'Payment not available',
        description:
            'In-app Razorpay checkout is not supported on this platform.',
      );
    } catch (e) {
      debugPrint('Error opening Razorpay checkout: $e');
      showError(
        title: 'Payment Error',
        description: 'Failed to open payment gateway. Please try again.',
      );
    }
  }

  void openWalletCheckout({
    required int amountInPaise,
    required String name,
    required String description,
    String? email,
    String? contact,
    String? orderId,
    Map<String, dynamic>? notes,
    Map<String, dynamic>? prefill,
  }) {
    if (isTestMode) {
      debugPrint('Test UPI: select UPI and enter $testUpiId');
    }
    openCheckout(
      amountInPaise: amountInPaise,
      name: name,
      description: description,
      email: email,
      contact: contact,
      orderId: orderId,
      prefill: prefill,
      notes: {...?notes, 'wallet_upi_hint': walletUpiId},
    );
  }

  void dispose() {
    _razorpay?.clear();
  }
}
