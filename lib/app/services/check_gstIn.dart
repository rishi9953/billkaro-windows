import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CheckGstinApi {
  final Dio _dio = Dio();

  /// Check the validity of a GSTIN number.
  Future<Response?> checkGstNumber({required String gstin}) async {
    try {
      final url =
          'https://sheet.gstincheck.co.in/check/0d17c5623c462e7d9c883b40a6d1b3f9/$gstin';
      final response = await _dio.get(url);
      debugPrint('GSTIN check response: ${response.data}');
      return response;
    } catch (e) {
      debugPrint('GSTIN check error: $e');
      return null;
    }
  }
}
