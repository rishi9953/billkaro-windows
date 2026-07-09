import 'package:billkaro/utils/trusted_http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CheckGstinApi {
  final Dio _dio;

  CheckGstinApi() : _dio = Dio() {
    configureTrustedDio(_dio);
  }

  String get _apiKey =>
      dotenv.env['GST_API_KEY']?.trim() ?? '';

  /// Check the validity of a GSTIN number.
  Future<Response?> checkGstNumber({required String gstin}) async {
    final key = _apiKey;
    if (key.isEmpty) {
      debugPrint('GST_API_KEY is not set in .env');
      return null;
    }
    try {
      final url = 'https://sheet.gstincheck.co.in/check/$key/$gstin';
      final response = await _dio.get(url);
      debugPrint('GSTIN check response: ${response.data}');
      return response;
    } catch (e) {
      debugPrint('GSTIN check error: $e');
      return null;
    }
  }
}
