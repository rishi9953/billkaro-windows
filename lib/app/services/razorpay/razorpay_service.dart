import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:billkaro/app/services/razorpay/razorpay_web_checkout.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum RazorpayEnvironment { test, production }

/// `razorpay_flutter` only registers native code on Android and iOS.
/// On Windows/macOS/Linux/web, constructing [Razorpay] throws [MissingPluginException].
bool get isRazorpayNativeSdkSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// Desktop apps use Razorpay Standard Checkout inside a WebView (see [RazorpayWebCheckout]).
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

  /// UPI, card, wallet, and netbanking only — hides EMI and Pay Later.
  static const Map<String, dynamic> instantPaymentMethods = {
    'netbanking': true,
    'card': true,
    'upi': true,
    'wallet': true,
    'emi': false,
    'paylater': false,
  };

  static String get merchantUpiId =>
      dotenv.env['RAZORPAY_MERCHANT_UPI_ID']?.trim() ?? '';

  static Map<String, dynamic> _instantPaymentCheckoutConfig(String upiId) {
    final config = <String, dynamic>{
      'display': {
        'hide': [
          {'method': 'emi'},
          {'method': 'paylater'},
        ],
        'preferences': {
          'show_default_blocks': true,
        },
      },
    };
    if (upiId.isNotEmpty) {
      config['display']['blocks'] = {
        'upi': {
          'name': 'Pay via UPI',
          'instruments': [
            {'method': 'upi'},
          ],
        },
      };
      config['display']['sequence'] = ['block.upi', 'card', 'netbanking', 'wallet'];
    }
    return config;
  }

  static Map<String, dynamic>? _instantPaymentUpiOptions(String upiId) {
    if (upiId.isEmpty) return null;
    return {
      'vpa': upiId,
      'flow': 'qr',
    };
  }

  /// Desktop WebView cannot launch UPI apps; hide EMI/pay later and keep defaults.
  static Map<String, dynamic> _desktopWebCheckoutConfig() {
    return {
      'display': {
        'hide': [
          {'method': 'emi'},
          {'method': 'paylater'},
        ],
        'preferences': {
          'show_default_blocks': true,
        },
      },
    };
  }

  Razorpay? _razorpay;
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  static String get keyId {
    final environment = dotenv.env['RAZORPAY_ENVIRONMENT'] ?? 'test';
    if (environment == 'production') {
      return dotenv.env['RAZORPAY_KEY_PRODUCTION'] ??
          (throw Exception('RAZORPAY_KEY_PRODUCTION not found in .env file'));
    } else {
      return dotenv.env['RAZORPAY_KEY_TEST'] ??
          (throw Exception('RAZORPAY_KEY_TEST not found in .env file'));
    }
  }

  /// Initialize Razorpay
  void initialize({
    Function(PaymentSuccessResponse)? onSuccess,
    Function(PaymentFailureResponse)? onFailure,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    this.onSuccess = onSuccess;
    this.onFailure = onFailure;
    this.onExternalWallet = onExternalWallet;

    if (!isRazorpayNativeSdkSupported) {
      debugPrint(
        'Razorpay native SDK skipped on this platform; '
        'desktop uses Standard Checkout (WebView / WebView2).',
      );
      return;
    }

    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Handle payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    if (onSuccess != null) {
      onSuccess!(response);
    }
  }

  /// Handle payment error/failure
  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    if (onFailure != null) {
      onFailure!(response);
    }
  }

  /// Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    if (onExternalWallet != null) {
      onExternalWallet!(response);
    }
  }

  /// Open Razorpay checkout
  ///
  /// [amountInPaise] - Amount in paise (e.g., 10000 for ₹100)
  /// [name] - Customer name
  /// [description] - Payment description
  /// [email] - Customer email (optional)
  /// [contact] - Customer contact number (optional)
  /// [orderId] - Order ID from your backend (optional, for server-side verification)
  void openCheckout({
    required int amountInPaise,
    required String name,
    required String description,
    String? email,
    String? contact,
    String? orderId,
    Map<String, dynamic>? prefill,
    Map<String, dynamic>? notes,
    bool instantPaymentsOnly = false,
  }) {
    try {
      if (amountInPaise <= 0) {
        throw Exception('Invalid amountInPaise: $amountInPaise');
      }

      final merchantUpi = merchantUpiId;
      final checkoutNotes = <String, dynamic>{
        ...?notes,
        if (merchantUpi.isNotEmpty) 'merchant_upi_id': merchantUpi,
      };
      final hasOrderId = orderId != null && orderId.isNotEmpty;

      final options = <String, dynamic>{
        'key': keyId,
        'amount': amountInPaise.toString(),
        'currency': 'INR',
        'name': 'BillKaro ChillKaro',
        'description': description,
        'prefill': {
          'contact': contact ?? '',
          'email': email ?? '',
          ...?prefill,
        },
        'notes': checkoutNotes,
        'theme': {'color': '#D4AF37'},
        if (hasOrderId) 'order_id': orderId,
        if (instantPaymentsOnly) ...{
          'method': instantPaymentMethods,
          'config': _instantPaymentCheckoutConfig(merchantUpi),
          if (_instantPaymentUpiOptions(merchantUpi) != null)
            'upi': _instantPaymentUpiOptions(merchantUpi),
        } else if (isRazorpayWebCheckoutSupported) ...{
          'method': instantPaymentMethods,
          'config': _desktopWebCheckoutConfig(),
        },
      };

      debugPrint(
        'Opening Razorpay checkout: amountInPaise=$amountInPaise, '
        'orderId=${orderId ?? ''}, currency=INR',
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

  /// Dispose Razorpay instance
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
