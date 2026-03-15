// Controller

import 'package:billkaro/app/services/Modals/Subscriptions/subscription_response.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/app/services/razorpay/razorpay_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionController extends BaseController {
  var selectedPlan = ''.obs;
  final List<SubscriptionPlan> subscriptionPlans = <SubscriptionPlan>[].obs;
  final RazorpayService razorpayService = RazorpayService();
  String orderId = '';
  String transactionId = '';
  String signature = '';
  String planId = '';
  double expectedAmount = 0.0;
  bool isProcessingPayment = false;
  int expectedAmountInPaise = 0;

  // Keep payment math in paise to avoid rounding mismatches.
  int _toPaise(double rupees) => (rupees * 100).round();

  @override
  void onInit() {
    super.onInit();
    _initializeRazorpay();
  }

  @override
  void onReady() {
    super.onReady();
    getSubscriptions();
  }

  @override
  void onClose() {
    razorpayService.dispose();
    super.onClose();
  }

  /// Initialize Razorpay with callbacks
  void _initializeRazorpay() {
    razorpayService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  /// Handle successful payment
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('Payment Success: ${response.paymentId}');
    debugPrint('Order ID: ${response.orderId}');
    debugPrint('Payment ID: ${response.paymentId}');
    debugPrint('Signature: ${response.signature}');

    final loc = AppLocalizations.of(Get.context!)!;

    // Prevent duplicate processing
    if (isProcessingPayment) {
      debugPrint('Payment already being processed');
      return;
    }

    try {
      isProcessingPayment = true;

      // Update transaction details from payment response
      if (response.orderId != null && response.orderId!.isNotEmpty) {
        orderId = response.orderId!;
      }
      if (response.paymentId != null && response.paymentId!.isNotEmpty) {
        transactionId = response.paymentId!;
      }
      if (response.signature != null && response.signature!.isNotEmpty) {
        signature = response.signature!;
      }

      // Complete the subscription purchase
      final paymentResponse = await makePayment();

      if (paymentResponse != null && paymentResponse['status'] == 'success') {
        // Show payment success dialog with Lottie animation
        await _showPaymentSuccessDialog(
          title: loc.payment_successful,
          description: loc.payment_successful_description,
        );

        // Refresh subscription plans
        await getSubscriptions();

        // Navigate back to previous screen after dialog is dismissed
        try {
          Get.back();
        } catch (e) {
          debugPrint('Error navigating back: $e');
        }
      } else {
        // Safely extract message from paymentResponse
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

  /// Safely extract message string from response.message which can be String or Map
  String _extractErrorMessage(dynamic message) {
    if (message == null) {
      return 'Payment could not be completed. Please try again.';
    }

    if (message is String) {
      return message;
    }

    if (message is Map) {
      // Try to extract error message from map
      if (message.containsKey('description')) {
        return message['description'].toString();
      }
      if (message.containsKey('error')) {
        return message['error'].toString();
      }
      if (message.containsKey('message')) {
        return message['message'].toString();
      }
      // If no specific field found, return the map as string
      return message.toString();
    }

    return message.toString();
  }

  /// Handle payment failure
  Future<void> _handlePaymentFailure(PaymentFailureResponse response) async {
    final errorMessage = _extractErrorMessage(response.message);

    debugPrint(
      'Payment Failed: code=${response.code}, message=$errorMessage, '
      'orderId=$orderId, planId=$planId, expectedAmount=$expectedAmount, paise=$expectedAmountInPaise',
    );

    try {
      // Add a small delay to ensure Razorpay dialog is closed
      await Future.delayed(const Duration(milliseconds: 500));

      // Use Get.context! directly with error handling
      final context = Get.context;
      if (context == null) {
        debugPrint('ERROR: Context is null, cannot show failure dialog');
        // Fallback: try to show error using showError
        showError(title: 'Payment Failed', description: errorMessage);
        return;
      }

      debugPrint('Showing payment failure dialog...');
      final loc = AppLocalizations.of(context)!;

      await _showPaymentFailureDialog(
        title: loc.payment_failed,
        description: errorMessage.isNotEmpty
            ? errorMessage
            : loc.payment_failed_description,
      );

      debugPrint('Payment failure dialog shown successfully');
    } catch (e, stackTrace) {
      debugPrint('ERROR showing payment failure dialog: $e');
      debugPrint('Stack trace: $stackTrace');
      // Fallback: show error using showError
      showError(title: 'Payment Failed', description: errorMessage);
    }
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet Selected: ${response.walletName}');
    final loc = AppLocalizations.of(Get.context!)!;
    showSuccess(description: loc.wallet_selected(response.walletName!));
  }

  void selectPlan(String plan) {
    selectedPlan.value = plan;
  }

  Future<dynamic> createOrder(String planId, double amountInRupees) async {
    try {
      final request = {
        // Backend is responsible for converting/validating the amount if needed.
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
      final loc = AppLocalizations.of(Get.context!)!;
      showError(
        title: loc.payment_failed,
        description: 'Failed to create payment order. Please try again.',
      );
      return null;
    }
  }

  Future<dynamic> makePayment() async {
    try {
      // Validate required fields
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
        "userId": appPref.user!.id!,
        "expectedAmount": expectedAmount,
        "subscriptionId": planId,
        "outletId": appPref.selectedOutlet!.id!,
        "transactionId": transactionId,
        "orderId": orderId,
        "signature": signature,
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

  /// Open Razorpay checkout for subscription purchase
  Future<void> buyNow(String planIds, double amounts) async {
    debugPrint('Initiating buyNow for Plan ID: $planIds, Amount: $amounts');
    try {
      // Validate user and outlet
      if (appPref.user == null) {
        final loc = AppLocalizations.of(Get.context!)!;
        showError(
          title: loc.payment_failed,
          description: 'User not logged in. Please login and try again.',
        );
        return;
      }

      if (appPref.selectedOutlet == null) {
        final loc = AppLocalizations.of(Get.context!)!;
        showError(
          title: loc.payment_failed,
          description:
              'No outlet selected. Please select an outlet and try again.',
        );
        return;
      }

      // Guard: don't allow subscribing when outlet already has an active subscription.
      if (outletHasAnyActiveSubscription(appPref.selectedOutlet)) {
        showError(
          title: 'Already Subscribed',
          description: 'This outlet already has an active subscription.',
        );
        return;
      }

      // Set plan details

      planId = planIds;
      // Amount should be consistent between rupees (API) and paise (Razorpay).
      // Avoid whole-rupee rounding; keep exact paise.
      expectedAmountInPaise = _toPaise(amounts);
      expectedAmount = expectedAmountInPaise / 100.0;

      // Create order
      final orderResponse = await createOrder(planId, expectedAmount);

      if (orderResponse != null && orderResponse['status'] == 'success') {
        // Store order details for later use in payment completion
        orderId = orderResponse['data']?['id'] ?? '';
        // transactionId = orderResponse['data']?['transactionId'] ?? '';
        // signature = orderResponse['data']?['signature'] ?? '';

        // Validate order details
        if (orderId.isEmpty) {
          final loc = AppLocalizations.of(Get.context!)!;
          showError(
            title: loc.payment_failed,
            description: 'Invalid order response. Please try again.',
          );
          return;
        }

        // Open Razorpay checkout
        razorpayService.openCheckout(
          orderId: orderId,
          amountInPaise: expectedAmountInPaise,
          name:
              appPref.user!.brandName ?? appPref.user!.firstName ?? 'Customer',
          email: appPref.user?.email ?? '',
          contact: appPref.user?.mobile ?? '',
          description: 'Subscription Purchase',
          notes: {'subscriptionId': planId},
          prefill: {'name': appPref.user!.firstName ?? 'Customer'},
        );
      } else {
        final loc = AppLocalizations.of(Get.context!)!;
        showError(
          title: loc.payment_failed,
          description:
              orderResponse?['message'] ??
              'Failed to create payment order. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('Error in buyNow: $e');
      final loc = AppLocalizations.of(Get.context!)!;
      showError(
        title: loc.payment_failed,
        description: 'An error occurred. Please try again.',
      );
    }
  }

  /// Payment success dialog with Success Lottie animation
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
              // Success Lottie Animation
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
                    // Close only the dialog; screen navigation is handled
                    // after this dialog completes in _handlePaymentSuccess.
                    Get.back();
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

  /// Payment failure dialog with Fail Lottie animation
  Future<void> _showPaymentFailureDialog({
    required String title,
    required String description,
  }) async {
    try {
      final context = Get.context;
      if (context == null) {
        debugPrint('ERROR: Context is null in _showPaymentFailureDialog');
        return;
      }

      debugPrint('Opening failure dialog with title: $title');
      await Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fail Lottie Animation
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
                    onPressed: () {
                      Get.back(); // close dialog
                    },
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
      debugPrint('Failure dialog opened successfully');
    } catch (e, stackTrace) {
      debugPrint('ERROR in _showPaymentFailureDialog: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  void showSupportBottomSheet() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    AppLocalizations.of(Get.context!)!.get_support,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () async {
                final Uri phoneUri = Uri(scheme: 'tel', path: '9350413656');
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone_outlined, color: Colors.black, size: 24),
                    const SizedBox(width: 16),
                    Text(
                      AppLocalizations.of(Get.context!)!.call,
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            InkWell(
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'support@billkro.com',
                );
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, color: Colors.black, size: 24),
                    const SizedBox(width: 16),
                    Text(
                      AppLocalizations.of(Get.context!)!.email_support,
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(Get.context!)!.cancel,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> getSubscriptions() async {
    try {
      final response = await callApi(apiClient.getSubscription());
      if (response != null) {
        subscriptionPlans.clear();
        subscriptionPlans.addAll(response.data);
        update();
      }
    } catch (e) {
      print('Error fetching subscriptions: $e');
    }
  }
}
