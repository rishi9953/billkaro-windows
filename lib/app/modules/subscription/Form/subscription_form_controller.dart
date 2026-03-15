import 'package:billkaro/app/routes/app_routes.dart';
import 'package:billkaro/app/services/Modals/Subscriptions/subscription_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SubscriptionFormController extends BaseController {
  final formKey = GlobalKey<FormState>();

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
  }

  /// Pre-fill form from selected outlet and user in appPref.
  void _fillFromSelectedOutlet() {
    final outlet = appPref.selectedOutlet;
    final user = appPref.user;
    if (outlet != null) {
      if (outlet.businessName != null && outlet.businessName!.trim().isNotEmpty) {
        outletNameController.text = outlet.businessName!.trim();
      }
      if (outlet.outletAddress != null && outlet.outletAddress!.trim().isNotEmpty) {
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
      if (phoneController.text.isEmpty && user.mobile != null && user.mobile!.trim().isNotEmpty) {
        phoneController.text = _normalizePhoneForDisplay(user.mobile!);
      }
      final pincode = user.zipcode?.trim() ?? '';
      if (pincode.isNotEmpty && pincodeController.text.isEmpty) {
        pincodeController.text = pincode.replaceAll(RegExp(r'\D'), '').length <= 6
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
  void submitSubscription() {
    if (formKey.currentState == null) {
      showError(description: 'Form not initialized. Please try again.');
      return;
    }
    if (!formKey.currentState!.validate()) return;

    final data = getFormData();
    onSubmit(data);
  }

  /// Navigate to review with form data and plan (when opened with subscription plan).
  void onSubmit(Map<String, String> data) {
    final plan = subscriptionPlan;
    if (plan != null) {
      Get.toNamed(
        AppRoute.subscriptionReview,
        arguments: {
          'subscription': plan,
          'formData': data,
        },
      );
    } else {
      showSuccess(description: 'Details saved. You can proceed to payment.');
    }
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
