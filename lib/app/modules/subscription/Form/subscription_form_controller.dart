import 'package:billkaro/app/routes/app_routes.dart';
import 'package:billkaro/app/services/Modals/PrinterOrderRequest/printer_order_request.dart';
import 'package:billkaro/app/services/Modals/Subscriptions/subscription_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:billkaro/app/services/razorpay/razorpay_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class SubscriptionFormController extends BaseController {
  final formKey = GlobalKey<FormState>();
  final RazorpayService razorpayService = RazorpayService();

  String orderId = '';
  String transactionId = '';
  String signature = '';
  String planId = '';
  double expectedAmount = 0.0;
  int expectedAmountInPaise = 0;
  bool isProcessingPayment = false;
  Map<String, String> _latestFormData = const {};

  // Passed from subscription screen when plan.withPrinter is true
  SubscriptionPlan? get subscriptionPlan {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args == null) return null;
    return args['subscription'] as SubscriptionPlan?;
  }

  // Outlet details
  final outletNameController = TextEditingController();
  final outletAddressController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  // Delivery details
  final deliveryAddressController = TextEditingController();
  final pincodeController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _fillFromSelectedOutlet();
    razorpayService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  /// Pre-fill form from selected outlet and user in appPref.
  void _fillFromSelectedOutlet() {
    final outlet = appPref.selectedOutlet;
    final user = appPref.user;
    if (outlet != null) {
      if (outlet.businessName != null &&
          outlet.businessName!.trim().isNotEmpty) {
        outletNameController.text = outlet.businessName!.trim();
      }
      if (outlet.outletAddress != null &&
          outlet.outletAddress!.trim().isNotEmpty) {
        outletAddressController.text = outlet.outletAddress!.trim();
        deliveryAddressController.text = outlet.outletAddress!.trim();
      }
      if (outlet.phoneNumber != null && outlet.phoneNumber!.trim().isNotEmpty) {
        phoneController.text = _normalizePhoneForDisplay(outlet.phoneNumber!);
      }
    }
    if (user != null) {
      if (user.email != null && user.email!.trim().isNotEmpty) {
        emailController.text = user.email!.trim();
      }
      if (phoneController.text.isEmpty &&
          user.mobile != null &&
          user.mobile!.trim().isNotEmpty) {
        phoneController.text = _normalizePhoneForDisplay(user.mobile!);
      }
      final pincode = user.zipcode?.trim() ?? '';
      if (pincode.isNotEmpty && pincodeController.text.isEmpty) {
        pincodeController.text =
            pincode.replaceAll(RegExp(r'\D'), '').length <= 6
            ? pincode.replaceAll(RegExp(r'\D'), '')
            : pincode.replaceAll(RegExp(r'\D'), '').substring(0, 6);
      }
      if (deliveryAddressController.text.isEmpty &&
          (user.address != null || user.city != null)) {
        final parts = [
          user.address?.trim(),
          user.city?.trim(),
          user.state?.trim(),
        ].where((e) => e != null && e.isNotEmpty);
        if (parts.isNotEmpty) {
          deliveryAddressController.text = parts.join(', ');
        }
      }
    }
  }

  /// Strip non-digits and take last 10 digits for Indian mobile display.
  String _normalizePhoneForDisplay(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }

  @override
  void onClose() {
    razorpayService.dispose();
    outletNameController.dispose();
    outletAddressController.dispose();
    emailController.dispose();
    phoneController.dispose();
    deliveryAddressController.dispose();
    pincodeController.dispose();
    super.onClose();
  }

  // --- Validators ---

  String? validateOutletName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Outlet name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Outlet name must be at least 2 characters';
    }
    if (trimmed.length > 100) {
      return 'Outlet name must not exceed 100 characters';
    }
    return null;
  }

  String? validateOutletAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Outlet address is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 5) {
      return 'Please enter a complete address (at least 5 characters)';
    }
    if (trimmed.length > 300) {
      return 'Address must not exceed 300 characters';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final trimmed = value.trim().toLowerCase();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    if (trimmed.contains('..')) {
      return 'Email cannot contain consecutive dots';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return 'Enter a valid 10-digit mobile number';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Phone number must start with 6, 7, 8 or 9';
    }
    return null;
  }

  String? validateDeliveryAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Delivery address is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 5) {
      return 'Please enter a complete delivery address (at least 5 characters)';
    }
    if (trimmed.length > 300) {
      return 'Address must not exceed 300 characters';
    }
    return null;
  }

  String? validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }
    final trimmed = value.trim();
    if (trimmed.length != 6) {
      return 'Pincode must be 6 digits';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      return 'Pincode must contain only numbers';
    }
    final pin = int.tryParse(trimmed);
    if (pin == null || pin < 100000 || pin > 999999) {
      return 'Enter a valid Indian pincode';
    }
    return null;
  }

  /// Normalizes phone to 10 digits (strips +91, spaces, etc.)
  String get normalizedPhone {
    final digits = phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }

  /// Submit: validates form and returns collected data; caller can then API or navigate.
  Future<void> submitSubscription() async {
    if (formKey.currentState == null) {
      showError(description: 'Form not initialized. Please try again.');
      return;
    }
    if (!formKey.currentState!.validate()) return;

    final data = getFormData();
    await onSubmit(data);
  }

  /// Navigate to review with form data and plan (when opened with subscription plan).
  Future<void> onSubmit(Map<String, String> data) async {
    final plan = subscriptionPlan;
    if (plan != null) {
      await processPaymentFromDetails(data);
    } else {
      showSuccess(description: 'Details saved. You can proceed to payment.');
    }
  }

  int _toPaise(double rupees) => (rupees * 100).round();

  double _calculateTaxAmount(SubscriptionPlan plan) {
    final rate = plan.tax > 1 ? plan.tax / 100 : plan.tax;
    return (plan.discountedPrice * rate).roundToDouble();
  }

  double _calculateTotalAmount(SubscriptionPlan plan) {
    return (plan.discountedPrice + _calculateTaxAmount(plan)).roundToDouble();
  }

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
      debugPrint('Error creating order from details screen: $e');
      showError(
        title: 'Payment Failed',
        description: 'Failed to create payment order. Please try again.',
      );
      return null;
    }
  }

  Future<dynamic> makePayment() async {
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

    return callApi(apiClient.subscribeToPlan(request), showLoader: true);
  }

  Future<void> processPaymentFromDetails(Map<String, String> data) async {
    final plan = subscriptionPlan;
    if (plan == null) {
      showError(title: 'Error', description: 'No subscription plan selected.');
      return;
    }
    if (appPref.user == null) {
      showError(
        title: 'Payment Failed',
        description: 'User not logged in. Please login and try again.',
      );
      return;
    }
    if (appPref.selectedOutlet == null) {
      showError(
        title: 'Payment Failed',
        description:
            'No outlet selected. Please select an outlet and try again.',
      );
      return;
    }

    _latestFormData = data;
    planId = plan.id;
    expectedAmount = _calculateTotalAmount(plan);
    expectedAmountInPaise = _toPaise(expectedAmount);

    final orderResponse = await createOrder(planId, expectedAmount);
    if (orderResponse != null && orderResponse['status'] == 'success') {
      orderId = orderResponse['data']?['id'] ?? '';
      if (orderId.isEmpty) {
        showError(
          title: 'Payment Failed',
          description: 'Invalid order response. Please try again.',
        );
        return;
      }

      razorpayService.openCheckout(
        orderId: orderId,
        amountInPaise: expectedAmountInPaise,
        name: appPref.user!.brandName ?? appPref.user!.firstName ?? 'Customer',
        email: data['email'] ?? appPref.user?.email ?? '',
        contact: data['phone'] ?? appPref.user?.mobile ?? '',
        description: 'Subscription Purchase - ${plan.title}',
        notes: {'subscriptionId': planId},
        prefill: {
          'name': appPref.user!.firstName ?? 'Customer',
          'email': data['email'] ?? appPref.user?.email ?? '',
          'contact': data['phone'] ?? appPref.user?.mobile ?? '',
        },
      );
      return;
    }

    showError(
      title: 'Payment Failed',
      description:
          orderResponse?['message'] ??
          'Failed to create payment order. Please try again.',
    );
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (isProcessingPayment) return;
    isProcessingPayment = true;
    try {
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
        await _createPrinterOrderAfterSuccess();
        showSuccess(description: 'Payment successful. Subscription activated.');
        Get.offAllNamed(AppRoute.homeMain);
      } else {
        showError(
          title: 'Payment Failed',
          description:
              paymentResponse?['message'] ??
              'Payment successful but activation failed. Please contact support.',
        );
      }
    } catch (e) {
      showError(
        title: 'Payment Failed',
        description:
            'Payment successful but activation failed. Please contact support.',
      );
    } finally {
      isProcessingPayment = false;
    }
  }

  Future<void> _createPrinterOrderAfterSuccess() async {
    final plan = subscriptionPlan;
    final user = appPref.user;
    final outlet = appPref.selectedOutlet;
    if (plan?.withPrinter != true || user == null || outlet == null) return;

    final printerOrder = PrinterOrderRequest(
      userId: user.id ?? '',
      outletId: outlet.id ?? '',
      subscriptionId: planId,
      outletName: _latestFormData['outletName'] ?? outlet.businessName ?? '',
      outletAddress:
          _latestFormData['outletAddress'] ?? outlet.outletAddress ?? '',
      email: _latestFormData['email'] ?? user.email ?? '',
      phoneNumber:
          _latestFormData['phone'] ?? outlet.phoneNumber ?? user.mobile ?? '',
      deliveryAddress:
          _latestFormData['deliveryAddress'] ??
          _latestFormData['outletAddress'] ??
          outlet.outletAddress ??
          '',
      pincode: _latestFormData['pincode'] ?? user.zipcode ?? '',
      status: 'placed',
    );

    await callApi(
      apiClient.printerOrderRequest(printerOrder),
      showLoader: false,
    );
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    final msg = response.message?.toString();
    showError(
      title: 'Payment Failed',
      description: (msg != null && msg.isNotEmpty)
          ? msg
          : 'Payment could not be completed. Please try again.',
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    showSuccess(description: 'Wallet selected: ${response.walletName ?? ''}');
  }

  Map<String, String> getFormData() {
    return {
      'outletName': outletNameController.text.trim(),
      'outletAddress': outletAddressController.text.trim(),
      'email': emailController.text.trim().toLowerCase(),
      'phone': normalizedPhone,
      'deliveryAddress': deliveryAddressController.text.trim(),
      'pincode': pincodeController.text.trim(),
    };
  }

  /// Input formatter for Indian phone: digits only, max 10.
  List<TextInputFormatter> get phoneInputFormatters => [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ];

  /// Input formatter for pincode: digits only, max 6.
  List<TextInputFormatter> get pincodeInputFormatters => [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(6),
  ];
}
