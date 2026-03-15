import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum RazorpayEnvironment { test, production }

class RazorpayService {
  static final RazorpayService _instance = RazorpayService._internal();
  factory RazorpayService() => _instance;
  RazorpayService._internal();

  late Razorpay _razorpay;
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  // Razorpay Keys loaded from .env file
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
    _razorpay = Razorpay();
    this.onSuccess = onSuccess;
    this.onFailure = onFailure;
    this.onExternalWallet = onExternalWallet;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
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
  }) {
    try {
      if (amountInPaise <= 0) {
        throw Exception('Invalid amountInPaise: $amountInPaise');
      }

      final options = {
        'key': 'rzp_test_S6acVlkXQvGWT0',
        'amount': amountInPaise.toString(), // Amount in paise (int)
        'name': 'BillKaro ChillKaro',
        'currency': 'INR',
        'description': description,
        'prefill': {
          'contact': contact ?? '',
          'email': email ?? '',
          ...?prefill,
        },
        'notes': notes ?? {},
        'theme': {
          'color': '#D4AF37', // Your app's primary color
        },
        'order_id': orderId,
      };

      debugPrint(
        'Opening Razorpay checkout: amountInPaise=$amountInPaise, '
        'orderId=${orderId ?? ''}, currency=INR',
      );
      _razorpay.open(options);
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
    _razorpay.clear();
  }
}
