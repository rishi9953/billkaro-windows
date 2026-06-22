import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Cloud OCR for desktop menu scanning (no native plugins required).
class CloudMenuOcrService {
  static const _endpoint = 'https://api.ocr.space/parse/image';

  String get _apiKey {
    final custom = dotenv.env['OCR_SPACE_API_KEY']?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return 'helloworld';
  }

  Future<String> extractText(File imageFile) async {
    final bytes = await _prepareImageBytes(imageFile);

    final request = http.MultipartRequest('POST', Uri.parse(_endpoint));
    request.fields['apikey'] = _apiKey;
    request.fields['language'] = 'eng';
    request.fields['isOverlayRequired'] = 'false';
    request.fields['OCREngine'] = '2';
    request.fields['scale'] = 'true';
    request.fields['detectOrientation'] = 'true';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'menu_scan.jpg',
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 45));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('OCR service failed (${streamed.statusCode})');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected OCR response');
    }

    if (decoded['IsErroredOnProcessing'] == true) {
      final message = decoded['ErrorMessage']?.toString() ?? 'OCR processing failed';
      throw Exception(message);
    }

    final results = decoded['ParsedResults'];
    if (results is! List || results.isEmpty) return '';

    final first = results.first;
    if (first is! Map<String, dynamic>) return '';

    return first['ParsedText']?.toString().trim() ?? '';
  }

  Future<Uint8List> _prepareImageBytes(File imageFile) async {
    var bytes = await imageFile.readAsBytes();
    if (bytes.length <= 1024 * 1024) return bytes;

    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;

      var resized = decoded;
      const maxSide = 1800;
      if (decoded.width > maxSide || decoded.height > maxSide) {
        if (decoded.width >= decoded.height) {
          resized = img.copyResize(decoded, width: maxSide);
        } else {
          resized = img.copyResize(decoded, height: maxSide);
        }
      }

      var quality = 85;
      var encoded = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      while (encoded.length > 1024 * 1024 && quality > 40) {
        quality -= 10;
        encoded = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      }
      return encoded;
    } catch (e) {
      debugPrint('⚠️ [CLOUD OCR] Image resize failed, using original: $e');
      return bytes;
    }
  }
}
