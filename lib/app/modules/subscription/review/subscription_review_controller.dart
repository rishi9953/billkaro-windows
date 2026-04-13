import 'package:billkaro/app/services/Modals/Subscriptions/subscription_response.dart';
import 'package:billkaro/app/services/Modals/PrinterOrderRequest/printer_order_request.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/app/services/razorpay/razorpay_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/app_snackbar.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class SubscriptionReviewController extends BaseController {
  /// -------------------------------
  /// Razorpay
  /// -------------------------------
  final RazorpayService razorpayService = RazorpayService();
  String orderId = '';
  String transactionId = '';
  String signature = '';
  String planId = '';
  double expectedAmount = 0.0;
  int expectedAmountInPaise = 0;
  bool isProcessingPayment = false;

  /// -------------------------------
  /// Observables
  /// -------------------------------
  final couponCode = ''.obs;
  final gstin = ''.obs;

  /// Selected subscription plan
  final Rxn<SubscriptionPlan> _plan = Rxn<SubscriptionPlan>();

  SubscriptionPlan? get plan => _plan.value;

  /// -------------------------------
  /// Product Details (Safe Getters)
  /// -------------------------------
  String get productName => plan?.title ?? 'Subscription';

  double get originalPrice => plan?.price ?? 0;

  double get offerPrice => plan?.discountedPrice ?? 0;

  String get validTill {
    if (plan == null) return '—';
    final d = plan!.duration;
    if (d >= 12) {
      final years = d ~/ 12;
      return '$years year${years > 1 ? 's' : ''}';
    }
    return '$d month${d > 1 ? 's' : ''}';
  }

  String get deliveryInfo => (plan?.subtitle.isNotEmpty == true)
      ? plan!.subtitle
      : 'Free Delivery & 1-Year Warranty';

  String get printerWarranty =>
      (plan?.bulletPoints.isNotEmpty == true) ? plan!.bulletPoints.first : '';

  /// -------------------------------
  /// Pricing Logic
  /// -------------------------------
  double get discountPercentage {
    if (originalPrice <= 0) return 0;
    return ((originalPrice - offerPrice) / originalPrice * 100).roundToDouble();
  }

  /// Handles both tax formats:
  /// 0.18 OR 18
  double get taxes {
    if (plan == null) return 0;

    final taxRate = plan!.tax > 1 ? plan!.tax / 100 : plan!.tax;

    return (offerPrice * taxRate).roundToDouble();
  }

  double get totalAmount => (offerPrice + taxes).roundToDouble();

  /// -------------------------------
  /// User Actions
  /// -------------------------------
  void updateCoupon(String value) {
    couponCode.value = value;
  }

  void updateGstin(String value) {
    gstin.value = value;
  }

  void applyCoupon() {
    final code = couponCode.value.trim();

    if (code.isEmpty) {
      AppSnackbar.show(
        title: 'Error',
        message: 'Please enter a coupon code',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    AppSnackbar.show(
      title: 'Coupon Applied',
      message: 'Coupon "$code" applied successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// -------------------------------
  /// Lifecycle
  /// -------------------------------
  @override
  void onInit() {
    super.onInit();
    _initializeRazorpay();

    final args = Get.arguments;
    if (args is Map && args['subscription'] is SubscriptionPlan) {
      _plan.value = args['subscription'];
    }
  }

  @override
  void onClose() {
    razorpayService.dispose();
    super.onClose();
  }

  /// -------------------------------
  /// Razorpay Initialization
  /// -------------------------------
  void _initializeRazorpay() {
    razorpayService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  /// -------------------------------
  /// Payment Callbacks
  /// -------------------------------
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('Payment Success: ${response.paymentId}');
    debugPrint('Order ID: ${response.orderId}');
    debugPrint('Payment ID: ${response.paymentId}');
    debugPrint('Signature: ${response.signature}');

    final context = Get.context;
    if (context == null) return;
    final loc = AppLocalizations.of(context)!;

    if (isProcessingPayment) {
      debugPrint('Payment already being processed');
      return;
    }

    try {
      isProcessingPayment = true;

      if (response.orderId != null && response.orderId!.isNotEmpty) {
        orderId = response.orderId!;
      }
      if (response.paymentId != null && response.paymentId!.isNotEmpty) {
        transactionId = response.paymentId!;
      }
      if (response.signature != null && response.signature!.isNotEmpty) {
        signature = response.signature!;
      }

      final paymentResponse = await makePayment();

      if (paymentResponse != null && paymentResponse['status'] == 'success') {
        // Create printer order on successful subscription payment (for plans with printer)
        if (plan?.withPrinter == true) {
          try {
            final user = appPref.user;
            final outlet = appPref.selectedOutlet;

            if (user != null && outlet != null) {
              final deliveryAddressBuffer = StringBuffer();

              if (user.address != null && user.address!.isNotEmpty) {
                deliveryAddressBuffer.write(user.address);
              }
              if (user.city != null && user.city!.isNotEmpty) {
                if (deliveryAddressBuffer.isNotEmpty)
                  deliveryAddressBuffer.write(', ');
                deliveryAddressBuffer.write(user.city);
              }
              if (user.state != null && user.state!.isNotEmpty) {
                if (deliveryAddressBuffer.isNotEmpty)
                  deliveryAddressBuffer.write(', ');
                deliveryAddressBuffer.write(user.state);
              }
              if (user.country != null && user.country!.isNotEmpty) {
                if (deliveryAddressBuffer.isNotEmpty)
                  deliveryAddressBuffer.write(', ');
                deliveryAddressBuffer.write(user.country);
              }

              final printerOrder = PrinterOrderRequest(
                userId: user.id ?? '',
                outletId: outlet.id ?? '',
                subscriptionId: planId,
                outletName: outlet.businessName ?? '',
                outletAddress: outlet.outletAddress ?? '',
                email: user.email ?? '',
                phoneNumber: outlet.phoneNumber ?? user.mobile ?? '',
                deliveryAddress: deliveryAddressBuffer.isNotEmpty
                    ? deliveryAddressBuffer.toString()
                    : (outlet.outletAddress ?? ''),
                pincode: user.zipcode ?? '',
                status: 'placed',
              );

              await callApi(
                apiClient.printerOrderRequest(printerOrder),
                showLoader: false,
              );
            }
          } catch (e) {
            debugPrint('Error creating printer order request: $e');
          }
        }

        await _showPaymentSuccessDialog(
          title: loc.payment_successful,
          description: loc.payment_successful_description,
        );
        try {
          Get.back();
        } catch (e) {
          debugPrint('Error navigating back: $e');
        }
      } else {
        String errorMsg =
            'Payment successful but subscription activation failed. Please contact support.';
        if (paymentResponse != null) {
          if (paymentResponse is Map) {
            errorMsg = paymentResponse['message']?.toString() ?? errorMsg;
          } else if (paymentResponse is String) {
            errorMsg = paymentResponse;
          }
        }
        showError(title: loc.payment_failed, description: errorMsg);
      }
    } catch (e) {
      debugPrint('Error completing subscription: $e');
      showError(
        title: loc.payment_failed,
        description:
            'Payment successful but subscription activation failed. Please contact support.',
      );
    } finally {
      isProcessingPayment = false;
    }
  }

  Future<void> _handlePaymentFailure(PaymentFailureResponse response) async {
    final errorMessage = _extractErrorMessage(response.message);

    debugPrint(
      'Payment Failed: code=${response.code}, message=$errorMessage, '
      'orderId=$orderId, planId=$planId, expectedAmount=$expectedAmount, paise=$expectedAmountInPaise',
    );

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final context = Get.context;
      if (context == null) {
        showError(title: 'Payment Failed', description: errorMessage);
        return;
      }

      final loc = AppLocalizations.of(context)!;

      await _showPaymentFailureDialog(
        title: loc.payment_failed,
        description: errorMessage.isNotEmpty
            ? errorMessage
            : loc.payment_failed_description,
      );
    } catch (e, stackTrace) {
      debugPrint('ERROR showing payment failure dialog: $e');
      debugPrint('Stack trace: $stackTrace');
      showError(title: 'Payment Failed', description: errorMessage);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet Selected: ${response.walletName}');
    final context = Get.context;
    if (context == null) return;
    final loc = AppLocalizations.of(context)!;
    showSuccess(description: loc.wallet_selected(response.walletName!));
  }

  String _extractErrorMessage(dynamic message) {
    if (message == null) {
      return 'Payment could not be completed. Please try again.';
    }
    if (message is String) return message;
    if (message is Map) {
      if (message.containsKey('description')) {
        return message['description'].toString();
      }
      if (message.containsKey('error')) return message['error'].toString();
      if (message.containsKey('message')) return message['message'].toString();
      return message.toString();
    }
    return message.toString();
  }

  /// -------------------------------
  /// API: Create Razorpay order & complete subscription
  /// -------------------------------
  Future<dynamic> createOrder(String planId, double amountInRupees) async {
    try {
      final request = {
        'amount': amountInRupees,
        'subscriptionId': planId,
        'userId': appPref.user?.id,
      };
      final response = await callApi(
        apiClient.createRazorPaymentOrder(request),
        showLoader: true,
      );
      return response;
    } catch (e) {
      debugPrint('Error creating order: $e');
      final context = Get.context;
      if (context != null) {
        final loc = AppLocalizations.of(context)!;
        showError(
          title: loc.payment_failed,
          description: 'Failed to create payment order. Please try again.',
        );
      }
      return null;
    }
  }

  Future<dynamic> makePayment() async {
    try {
      if (appPref.user?.id == null) {
        throw Exception('User ID is required');
      }
      if (appPref.selectedOutlet?.id == null) {
        throw Exception('Outlet ID is required');
      }
      if (orderId.isEmpty || transactionId.isEmpty || signature.isEmpty) {
        throw Exception('Payment details are incomplete');
      }

      final request = {
        'userId': appPref.user!.id!,
        'expectedAmount': expectedAmount,
        'subscriptionId': planId,
        'outletId': appPref.selectedOutlet!.id!,
        'transactionId': transactionId,
        'orderId': orderId,
        'signature': signature,
      };

      debugPrint('Making payment request: $request');

      final response = await callApi(
        apiClient.subscribeToPlan(request),
        showLoader: true,
      );

      debugPrint('Payment response: $response');
      return response;
    } catch (e) {
      debugPrint('Error making payment: $e');
      rethrow;
    }
  }

  /// -------------------------------
  /// Payment Flow (called from Pay button)
  /// -------------------------------
  Future<void> processPayment() async {
    if (gstin.value.isNotEmpty && gstin.value.length != 15) {
      AppSnackbar.show(
        title: 'Invalid GSTIN',
        message: 'GSTIN must be exactly 15 characters',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (plan == null) {
      showError(title: 'Error', description: 'No subscription plan selected.');
      return;
    }

    if (appPref.user == null) {
      final context = Get.context;
      if (context != null) {
        final loc = AppLocalizations.of(context)!;
        showError(
          title: loc.payment_failed,
          description: 'User not logged in. Please login and try again.',
        );
      }
      return;
    }

    if (appPref.selectedOutlet == null) {
      final context = Get.context;
      if (context != null) {
        final loc = AppLocalizations.of(context)!;
        showError(
          title: loc.payment_failed,
          description:
              'No outlet selected. Please select an outlet and try again.',
        );
      }
      return;
    }

    // Guard: don't allow subscribing when outlet already has an active subscription.
    if (outletHasAnyActiveSubscription(appPref.selectedOutlet)) {
      showError(
        title: 'Already Subscribed',
        description:
            'This outlet already has an active subscription.',
      );
      return;
    }

    planId = plan!.id;
    expectedAmount = totalAmount;
    expectedAmountInPaise = (expectedAmount * 100).round();

    final orderResponse = await createOrder(planId, expectedAmount);

    if (orderResponse != null && orderResponse['status'] == 'success') {
      orderId = orderResponse['data']?['id'] ?? '';

      if (orderId.isEmpty) {
        final context = Get.context;
        if (context != null) {
          final loc = AppLocalizations.of(context)!;
          showError(
            title: loc.payment_failed,
            description: 'Invalid order response. Please try again.',
          );
        }
        return;
      }

      razorpayService.openCheckout(
        orderId: orderId,
        amountInPaise: expectedAmountInPaise,
        name: appPref.user!.brandName ?? appPref.user!.firstName ?? 'Customer',
        email: appPref.user?.email ?? '',
        contact: appPref.user?.mobile ?? '',
        description: 'Subscription Purchase - ${productName}',
        notes: {
          'subscriptionId': planId,
          if (gstin.value.isNotEmpty) 'gstin': gstin.value,
        },
        prefill: {'name': appPref.user!.firstName ?? 'Customer'},
      );
    } else {
      final context = Get.context;
      if (context != null) {
        final loc = AppLocalizations.of(context)!;
        showError(
          title: loc.payment_failed,
          description:
              orderResponse?['message'] ??
              'Failed to create payment order. Please try again.',
        );
      }
    }
  }

  /// -------------------------------
  /// Payment result dialogs
  /// -------------------------------
  Future<void> _showPaymentSuccessDialog({
    required String title,
    required String description,
  }) async {
    final context = Get.context;
    if (context == null) return;

    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 140,
                child: Lottie.asset(
                  'assets/lottie/Success.json',
                  repeat: false,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.offAllNamed(AppRoute.homeMain);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.submit),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _showPaymentFailureDialog({
    required String title,
    required String description,
  }) async {
    final context = Get.context;
    if (context == null) return;

    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 140,
                child: Lottie.asset('assets/lottie/Fail.json', repeat: false),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
