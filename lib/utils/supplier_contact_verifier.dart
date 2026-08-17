import 'dart:async';

import 'package:billkaro/config/config.dart';

class SupplierContactVerifier {
  SupplierContactVerifier({
    required this.outletId,
    this.editingSupplierId,
    this.originalEmail,
    this.originalPhone,
  });

  final String outletId;
  final String? editingSupplierId;
  final String? originalEmail;
  final String? originalPhone;

  Timer? _emailCheckDebounce;
  Timer? _phoneCheckDebounce;

  final isEmailChecking = false.obs;
  final isEmailAvailable = Rxn<bool>();
  final emailVerificationError = RxnString();
  String? _lastCheckedEmail;

  final isPhoneChecking = false.obs;
  final isPhoneAvailable = Rxn<bool>();
  final phoneVerificationError = RxnString();
  String? _lastCheckedPhone;

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  void dispose() {
    _emailCheckDebounce?.cancel();
    _phoneCheckDebounce?.cancel();
  }

  void onEmailChanged(String value) {
    final trimmed = value.trim().toLowerCase();
    emailVerificationError.value = null;

    if (_emailFormatError(trimmed) != null) {
      isEmailAvailable.value = null;
      _lastCheckedEmail = null;
      isEmailChecking.value = false;
      return;
    }

    if (_isSameAsOriginalEmail(trimmed)) {
      isEmailAvailable.value = true;
      _lastCheckedEmail = trimmed;
      isEmailChecking.value = false;
      return;
    }

    if (trimmed == _lastCheckedEmail) return;

    _emailCheckDebounce?.cancel();
    isEmailAvailable.value = null;
    isEmailChecking.value = true;

    _emailCheckDebounce = Timer(const Duration(milliseconds: 600), () {
      checkEmailAvailability(trimmed);
    });
  }

  void onPhoneChanged(String value) {
    final digits = normalizePhoneDigits(value);
    phoneVerificationError.value = null;

    if (_phoneFormatError(digits) != null) {
      isPhoneAvailable.value = null;
      _lastCheckedPhone = null;
      isPhoneChecking.value = false;
      return;
    }

    if (_isSameAsOriginalPhone(digits)) {
      isPhoneAvailable.value = true;
      _lastCheckedPhone = digits;
      isPhoneChecking.value = false;
      return;
    }

    if (digits == _lastCheckedPhone) return;

    _phoneCheckDebounce?.cancel();
    isPhoneAvailable.value = null;
    isPhoneChecking.value = true;

    _phoneCheckDebounce = Timer(const Duration(milliseconds: 600), () {
      checkPhoneAvailability(digits);
    });
  }

  Future<bool> checkEmailAvailability(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (_emailFormatError(normalizedEmail) != null) {
      isEmailAvailable.value = null;
      emailVerificationError.value = null;
      isEmailChecking.value = false;
      return false;
    }

    if (_isSameAsOriginalEmail(normalizedEmail)) {
      isEmailAvailable.value = true;
      _lastCheckedEmail = normalizedEmail;
      emailVerificationError.value = null;
      isEmailChecking.value = false;
      return true;
    }

    if (outletId.trim().isEmpty) {
      isEmailAvailable.value = null;
      _lastCheckedEmail = null;
      emailVerificationError.value =
          'Could not verify email right now. Please try again.';
      isEmailChecking.value = false;
      return false;
    }

    isEmailChecking.value = true;
    emailVerificationError.value = null;

    try {
      final body = <String, dynamic>{'email': normalizedEmail};
      final supplierId = editingSupplierId?.trim();
      if (supplierId != null && supplierId.isNotEmpty) {
        body['supplierId'] = supplierId;
      }

      final response = await callApi(
        Get.find<ApiClient>().checkSupplierEmail(outletId, body),
        showLoader: false,
        apiErrorHandler: (_) async => true,
      );

      if (response == null || response is! Map) {
        isEmailAvailable.value = null;
        _lastCheckedEmail = null;
        emailVerificationError.value =
            'Could not verify email right now. Please try again.';
        return false;
      }

      final data = Map<String, dynamic>.from(response);
      _lastCheckedEmail = normalizedEmail;

      if (data['available'] == true) {
        isEmailAvailable.value = true;
        emailVerificationError.value = null;
        return true;
      }

      if (data['available'] == false) {
        isEmailAvailable.value = false;
        emailVerificationError.value = null;
        return false;
      }

      isEmailAvailable.value = null;
      emailVerificationError.value =
          'Could not verify email right now. Please try again.';
      return false;
    } catch (_) {
      isEmailAvailable.value = null;
      _lastCheckedEmail = null;
      emailVerificationError.value =
          'Could not verify email right now. Please try again.';
      return false;
    } finally {
      isEmailChecking.value = false;
    }
  }

  Future<bool> checkPhoneAvailability(String phone) async {
    final digits = normalizePhoneDigits(phone);
    if (_phoneFormatError(digits) != null) {
      isPhoneAvailable.value = null;
      phoneVerificationError.value = null;
      isPhoneChecking.value = false;
      return false;
    }

    if (_isSameAsOriginalPhone(digits)) {
      isPhoneAvailable.value = true;
      _lastCheckedPhone = digits;
      phoneVerificationError.value = null;
      isPhoneChecking.value = false;
      return true;
    }

    if (outletId.trim().isEmpty) {
      isPhoneAvailable.value = null;
      _lastCheckedPhone = null;
      phoneVerificationError.value =
          'Could not verify mobile number right now. Please try again.';
      isPhoneChecking.value = false;
      return false;
    }

    isPhoneChecking.value = true;
    phoneVerificationError.value = null;

    try {
      final body = <String, dynamic>{'phone': digits};
      final supplierId = editingSupplierId?.trim();
      if (supplierId != null && supplierId.isNotEmpty) {
        body['supplierId'] = supplierId;
      }

      final response = await callApi(
        Get.find<ApiClient>().checkSupplierPhone(outletId, body),
        showLoader: false,
        apiErrorHandler: (_) async => true,
      );

      if (response == null || response is! Map) {
        isPhoneAvailable.value = null;
        _lastCheckedPhone = null;
        phoneVerificationError.value =
            'Could not verify mobile number right now. Please try again.';
        return false;
      }

      final data = Map<String, dynamic>.from(response);
      _lastCheckedPhone = digits;

      if (data['available'] == true) {
        isPhoneAvailable.value = true;
        phoneVerificationError.value = null;
        return true;
      }

      if (data['available'] == false) {
        isPhoneAvailable.value = false;
        phoneVerificationError.value = null;
        return false;
      }

      isPhoneAvailable.value = null;
      phoneVerificationError.value =
          'Could not verify mobile number right now. Please try again.';
      return false;
    } catch (_) {
      isPhoneAvailable.value = null;
      _lastCheckedPhone = null;
      phoneVerificationError.value =
          'Could not verify mobile number right now. Please try again.';
      return false;
    } finally {
      isPhoneChecking.value = false;
    }
  }

  String? validateEmail(String? value) {
    final trimmed = value?.trim().toLowerCase() ?? '';
    final formatError = _emailFormatError(trimmed);
    if (formatError != null) return formatError;
    if (isEmailAvailable.value == false) {
      return 'This email is already registered. Please use a different email.';
    }
    if (emailVerificationError.value != null) {
      return emailVerificationError.value;
    }
    return null;
  }

  String? validatePhone(String? value, {required String emptyMessage}) {
    final digits = normalizePhoneDigits(value);
    if (digits.isEmpty) return emptyMessage;
    final formatError = _phoneFormatError(digits);
    if (formatError != null) return formatError;
    if (isPhoneAvailable.value == false) {
      return 'This mobile number is already registered. Please use a different number.';
    }
    if (phoneVerificationError.value != null) {
      return phoneVerificationError.value;
    }
    return null;
  }

  Future<bool> ensureEmailAvailable(String currentEmail) async {
    final email = currentEmail.trim().toLowerCase();
    if (isEmailChecking.value) {
      showError(description: 'Please wait while we verify your email.');
      return false;
    }

    if (_isSameAsOriginalEmail(email)) return true;

    if (_lastCheckedEmail != email || isEmailAvailable.value != true) {
      await checkEmailAvailability(email);
    }

    if (isEmailAvailable.value == false) {
      showError(
        description:
            'This email is already registered. Please use a different email.',
      );
      return false;
    }

    if (isEmailAvailable.value != true) {
      showError(
        description:
            emailVerificationError.value ??
            'Unable to verify email availability. Please check your connection and try again.',
      );
      return false;
    }

    return true;
  }

  Future<bool> ensurePhoneAvailable(String currentPhone) async {
    final digits = normalizePhoneDigits(currentPhone);
    if (isPhoneChecking.value) {
      showError(
        description: 'Please wait while we verify your mobile number.',
      );
      return false;
    }

    if (_phoneFormatError(digits) != null) {
      showError(
        description: 'Please enter a valid 10-digit phone number.',
      );
      return false;
    }

    if (_isSameAsOriginalPhone(digits)) {
      isPhoneAvailable.value = true;
      _lastCheckedPhone = digits;
      phoneVerificationError.value = null;
      return true;
    }

    if (_lastCheckedPhone != digits || isPhoneAvailable.value != true) {
      await checkPhoneAvailability(digits);
    }

    if (isPhoneAvailable.value == false) {
      showError(
        description:
            'This mobile number is already registered. Please use a different number.',
      );
      return false;
    }

    if (isPhoneAvailable.value == true) return true;

    // Availability API failed (network / server). Allow save when the number
    // itself is a valid 10-digit phone — create/update will re-check server-side.
    phoneVerificationError.value = null;
    return true;
  }

  Widget? buildEmailSuffixIcon() {
    if (isEmailChecking.value) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    if (isEmailAvailable.value == true) {
      return const Icon(Icons.check_circle_rounded, color: Colors.green);
    }
    if (emailVerificationError.value != null) {
      return const Icon(Icons.wifi_off_rounded, color: Colors.red);
    }
    if (isEmailAvailable.value == false) {
      return const Icon(Icons.error_outline_rounded, color: Colors.red);
    }
    return null;
  }

  String? buildEmailHelperText() {
    if (isEmailChecking.value) return 'Checking email availability...';
    if (isEmailAvailable.value == true) return 'Email is available';
    if (emailVerificationError.value != null) {
      return emailVerificationError.value;
    }
    if (isEmailAvailable.value == false) {
      return 'This email is already registered. Please use a different email.';
    }
    return null;
  }

  Color? buildEmailHelperColor() {
    if (isEmailAvailable.value == false ||
        emailVerificationError.value != null) {
      return Colors.red;
    }
    if (isEmailAvailable.value == true) return Colors.green;
    return Colors.grey.shade600;
  }

  Widget? buildPhoneSuffixIcon() {
    if (isPhoneChecking.value) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    if (isPhoneAvailable.value == true) {
      return const Icon(Icons.check_circle_rounded, color: Colors.green);
    }
    if (phoneVerificationError.value != null) {
      return const Icon(Icons.wifi_off_rounded, color: Colors.red);
    }
    if (isPhoneAvailable.value == false) {
      return const Icon(Icons.error_outline_rounded, color: Colors.red);
    }
    return null;
  }

  String? buildPhoneHelperText() {
    if (isPhoneChecking.value) {
      return 'Checking mobile number availability...';
    }
    if (isPhoneAvailable.value == true) return 'Mobile number is available';
    if (phoneVerificationError.value != null) {
      return phoneVerificationError.value;
    }
    if (isPhoneAvailable.value == false) {
      return 'This mobile number is already registered. Please use a different number.';
    }
    return null;
  }

  Color? buildPhoneHelperColor() {
    if (isPhoneAvailable.value == false ||
        phoneVerificationError.value != null) {
      return Colors.red;
    }
    if (isPhoneAvailable.value == true) return Colors.green;
    return Colors.grey.shade600;
  }

  bool _isSameAsOriginalEmail(String email) {
    final original = originalEmail?.trim().toLowerCase();
    return original != null && original.isNotEmpty && original == email;
  }

  bool _isSameAsOriginalPhone(String digits) {
    final original = normalizePhoneDigits(originalPhone);
    final current = normalizePhoneDigits(digits);
    return original.isNotEmpty && original == current;
  }

  String? _emailFormatError(String trimmed) {
    if (trimmed.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    if (trimmed.contains('..')) {
      return 'Email cannot contain consecutive dots';
    }
    return null;
  }

  String? _phoneFormatError(String digits) {
    final normalized = normalizePhoneDigits(digits);
    if (normalized.isEmpty) return 'Phone number is required';
    if (normalized.length != 10 || !RegExp(r'^\d{10}$').hasMatch(normalized)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  /// Strips non-digits and keeps the last 10 digits (handles +91 / 91 prefix).
  static String normalizePhoneDigits(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > 10) return digits.substring(digits.length - 10);
    return digits;
  }
}
