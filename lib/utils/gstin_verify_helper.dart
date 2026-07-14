import 'package:billkaro/app/services/check_gstIn.dart';
import 'package:get/get.dart';

class GstinVerificationDetails {
  final String? legalName;
  final String? principalAddress;

  const GstinVerificationDetails({this.legalName, this.principalAddress});
}

class GstinVerifyHelper {
  final isVerifyingGstin = false.obs;
  final isGstinVerified = false.obs;
  final gstinVerificationMessage = ''.obs;
  final verifiedGstin = ''.obs;
  final savedGstin = ''.obs;

  /// Marks GSTIN already stored on the server as verified (no re-verify on load).
  void markSavedFromServer(String? gstin) {
    final normalized = (gstin ?? '').trim().toUpperCase();
    savedGstin.value = normalized;
    if (normalized.isEmpty) {
      isGstinVerified.value = false;
      verifiedGstin.value = '';
      gstinVerificationMessage.value = '';
      return;
    }
    isGstinVerified.value = true;
    verifiedGstin.value = normalized;
    gstinVerificationMessage.value = '';
  }

  /// Call after a successful save so the current value is treated as verified.
  void markSavedAfterSubmit(String current) {
    final normalized = current.trim().toUpperCase();
    savedGstin.value = normalized;
    if (normalized.isEmpty) {
      isGstinVerified.value = false;
      verifiedGstin.value = '';
      return;
    }
    isGstinVerified.value = true;
    verifiedGstin.value = normalized;
  }

  void resetIfChanged(String current) {
    final normalized = current.trim().toUpperCase();
    if (normalized == verifiedGstin.value) return;
    if (normalized == savedGstin.value) {
      isGstinVerified.value = normalized.isNotEmpty;
      verifiedGstin.value = normalized.isNotEmpty ? normalized : '';
      gstinVerificationMessage.value = '';
      return;
    }
    if (gstinVerificationMessage.value.isNotEmpty || isGstinVerified.value) {
      isGstinVerified.value = false;
      verifiedGstin.value = '';
      gstinVerificationMessage.value = '';
    }
  }

  bool requiresVerification(String current) {
    final gstin = current.trim().toUpperCase();
    if (gstin.isEmpty) return false;
    if (gstin == savedGstin.value) return false;
    return !isGstinVerified.value || verifiedGstin.value != gstin;
  }

  Future<GstinVerificationDetails?> verify(
    String rawGstin, {
    void Function({String? title, required String description})? onError,
    void Function({String? title, required String description})? onSuccess,
  }) async {
    final gstin = rawGstin.trim().toUpperCase();
    if (gstin.isEmpty) {
      isGstinVerified.value = false;
      verifiedGstin.value = '';
      gstinVerificationMessage.value = 'Please enter GSTIN number first';
      onError?.call(description: gstinVerificationMessage.value);
      return null;
    }

    if (gstin.length != 15) {
      isGstinVerified.value = false;
      verifiedGstin.value = '';
      gstinVerificationMessage.value = 'GSTIN must be 15 characters';
      onError?.call(description: gstinVerificationMessage.value);
      return null;
    }

    try {
      isVerifyingGstin.value = true;
      gstinVerificationMessage.value = '';

      final response = await CheckGstinApi().checkGstNumber(gstin: gstin);
      final dynamic body = response?.data;

      if (response == null || response.statusCode != 200 || body == null) {
        isGstinVerified.value = false;
        verifiedGstin.value = '';
        gstinVerificationMessage.value = 'Unable to verify GSTIN right now';
        onError?.call(description: gstinVerificationMessage.value);
        return null;
      }

      var verified = false;
      var message = 'GSTIN verified successfully';
      GstinVerificationDetails? details;

      if (body is Map) {
        final dynamic validValue =
            body['flag'] ?? body['valid'] ?? body['isValid'] ?? body['status'];
        final normalized = validValue?.toString().toLowerCase() ?? '';
        verified =
            validValue == true ||
            normalized == 'true' ||
            normalized == 'valid' ||
            normalized == 'success' ||
            normalized == '1';

        message =
            (body['message'] ??
                    body['msg'] ??
                    body['errorMsg'] ??
                    body['error'] ??
                    body['status'] ??
                    message)
                .toString()
                .trim();

        final dynamic gstinData = body['data'];
        if (verified && gstinData is Map) {
          final legalName = (gstinData['lgnm'] ?? '').toString().trim();
          final principalAddressData = gstinData['pradr'];
          final principalAddress = principalAddressData is Map
              ? (principalAddressData['adr'] ?? '').toString().trim()
              : '';
          details = GstinVerificationDetails(
            legalName: legalName.isEmpty ? null : legalName,
            principalAddress:
                principalAddress.isEmpty ? null : principalAddress,
          );
        }
      }

      isGstinVerified.value = verified;
      verifiedGstin.value = verified ? gstin : '';
      gstinVerificationMessage.value = message;

      if (verified) {
        onSuccess?.call(description: message);
      } else {
        onError?.call(description: message);
      }

      return verified ? details : null;
    } catch (_) {
      isGstinVerified.value = false;
      verifiedGstin.value = '';
      gstinVerificationMessage.value = 'Unable to verify GSTIN right now';
      onError?.call(description: gstinVerificationMessage.value);
      return null;
    } finally {
      isVerifyingGstin.value = false;
    }
  }
}
