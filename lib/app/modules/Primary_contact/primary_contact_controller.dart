import 'dart:async';
import 'dart:convert';

import 'package:billkaro/app/services/Network/api_config.dart';
import 'package:billkaro/app/services/Network/api_handler.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/trusted_http_client.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrimaryContactController extends BaseController {
  final formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();

  final selectedTitle = 'CEO'.obs;

  final List<String> titleList = ['CEO', 'Manager', 'Other'];

  Timer? _mobileCheckDebounce;
  final isMobileChecking = false.obs;
  final isMobileAvailable = Rxn<bool>();
  final mobileVerificationError = RxnString();
  String? _lastCheckedMobile;

  @override
  void onClose() {
    _mobileCheckDebounce?.cancel();
    firstNameController.dispose();
    lastNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    super.onClose();
  }

  void onMobileChanged(String value) {
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    mobileVerificationError.value = null;
    if (_mobileFormatError(digits) != null) {
      isMobileAvailable.value = null;
      _lastCheckedMobile = null;
      isMobileChecking.value = false;
      return;
    }

    if (digits == _lastCheckedMobile) return;

    _mobileCheckDebounce?.cancel();
    isMobileAvailable.value = null;
    isMobileChecking.value = true;

    _mobileCheckDebounce = Timer(const Duration(milliseconds: 600), () {
      checkMobileAvailability(digits);
    });
  }

  Future<Map<String, dynamic>?> _requestMobileAvailability(String mobile) async {
    final response = await callApi(
      apiClient.checkAuthMobile({'mobile': mobile}),
      showLoader: false,
      apiErrorHandler: (_) async => true,
    );

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}auth/check-mobile');
      final httpResponse = await trustedHttpClient().post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      );

      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        final decoded = jsonDecode(httpResponse.body);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      debugPrint('Mobile availability HTTP fallback failed: $e');
    }

    return null;
  }

  Future<bool> checkMobileAvailability(String mobile) async {
    final digits = mobile.replaceAll(RegExp(r'[^\d]'), '');
    if (_mobileFormatError(digits) != null) {
      isMobileAvailable.value = null;
      mobileVerificationError.value = null;
      isMobileChecking.value = false;
      return false;
    }

    isMobileChecking.value = true;
    mobileVerificationError.value = null;
    try {
      final response = await _requestMobileAvailability(digits);

      final currentDigits =
          mobileController.text.replaceAll(RegExp(r'[^\d]'), '');
      if (currentDigits != digits) {
        return false;
      }

      if (response == null) {
        isMobileAvailable.value = null;
        _lastCheckedMobile = null;
        mobileVerificationError.value =
            'Could not verify mobile number right now. You can still continue.';
        return false;
      }

      _lastCheckedMobile = digits;

      if (response['available'] == true) {
        isMobileAvailable.value = true;
        mobileVerificationError.value = null;
        formKey.currentState?.validate();
        return true;
      }

      if (response['available'] == false) {
        isMobileAvailable.value = false;
        mobileVerificationError.value = null;
        formKey.currentState?.validate();
        return false;
      }

      isMobileAvailable.value = null;
      mobileVerificationError.value =
          'Could not verify mobile number right now. You can still continue.';
      return false;
    } catch (_) {
      final currentDigits =
          mobileController.text.replaceAll(RegExp(r'[^\d]'), '');
      if (currentDigits == digits) {
        isMobileAvailable.value = null;
        _lastCheckedMobile = null;
        mobileVerificationError.value =
            'Could not verify mobile number right now. You can still continue.';
      }
      return false;
    } finally {
      final currentDigits =
          mobileController.text.replaceAll(RegExp(r'[^\d]'), '');
      if (currentDigits == digits) {
        isMobileChecking.value = false;
      }
    }
  }

  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return '$fieldName should contain only letters';
    }
    return null;
  }

  String? _mobileFormatError(String digits) {
    if (digits.isEmpty) {
      return 'Mobile number is required';
    }
    if (digits.length < 10) {
      return 'Please enter a valid mobile number';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  }

  String? validateMobile(String? value) {
    final digits = value?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
    final formatError = _mobileFormatError(digits);
    if (formatError != null) {
      return formatError;
    }
    if (isMobileAvailable.value == false) {
      return 'This mobile number is already registered. Please use a different number.';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> submitContact() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final digits = mobileController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (isMobileChecking.value) {
      showError(description: 'Please wait while we verify your mobile number.');
      return;
    }

    if (_lastCheckedMobile != digits || isMobileAvailable.value == false) {
      await checkMobileAvailability(digits);
    }

    if (isMobileAvailable.value == false) {
      showError(
        description:
            'This mobile number is already registered. Please use a different number.',
      );
      return;
    }

    final contactData = {
      'firstName': firstNameController.text.trim(),
      'lastName': lastNameController.text.trim(),
      'name':
          '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
      'title': selectedTitle.value,
      'mobile': digits,
      'email': emailController.text.trim().toLowerCase(),
    };

    Get.back(result: contactData);
    showSuccess(description: 'Primary contact saved successfully');
  }
}
