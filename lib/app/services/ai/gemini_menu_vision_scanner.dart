import 'dart:convert';
import 'dart:io';

import 'package:billkaro/app/services/ai/menu_ai_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Optional Gemini vision scan for richer menu extraction on desktop.
class GeminiMenuVisionScanner {
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const _models = ['gemini-2.0-flash', 'gemini-2.0-flash-lite'];

  String? get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY']?.trim();
    if (key == null || key.isEmpty || key.startsWith('eyJ')) return null;
    return key;
  }

  bool get isConfigured => _apiKey != null;

  Future<MenuScanResult?> scanMenu(File imageFile) async {
    final key = _apiKey;
    if (key == null) return null;

    final bytes = await imageFile.readAsBytes();
    final mime = _mimeType(imageFile.path);
    final prompt =
        'Analyze this restaurant menu or food item photo. '
        'Extract the primary menu item shown. '
        'Reply ONLY with valid JSON (no markdown fences): '
        '{"itemName":"name","price":120.0,"category":"category or null","description":"short text"} '
        'Use null for price or category when not visible. Price should be INR numeric only.';

    for (final model in _models) {
      try {
        final uri = Uri.parse('$_baseUrl/models/$model:generateContent');
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': key,
              },
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt},
                      {
                        'inline_data': {
                          'mime_type': mime,
                          'data': base64Encode(bytes),
                        },
                      },
                    ],
                  },
                ],
                'generationConfig': {'temperature': 0.1},
              }),
            )
            .timeout(const Duration(seconds: 45));

        if (response.statusCode == 429) {
          debugPrint('⚠️ [GEMINI SCAN] Quota exceeded for $model');
          continue;
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          debugPrint(
            '⚠️ [GEMINI SCAN] $model failed (${response.statusCode}): ${response.body}',
          );
          continue;
        }

        final parsed = _parseGeminiResponse(response.body);
        if (parsed != null && parsed.itemName.isNotEmpty) {
          return parsed;
        }
      } catch (e) {
        debugPrint('⚠️ [GEMINI SCAN] $model error: $e');
      }
    }

    return null;
  }

  MenuScanResult? _parseGeminiResponse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;

    final content = candidates.first['content'];
    if (content is! Map<String, dynamic>) return null;

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return null;

    final text = parts
        .whereType<Map<String, dynamic>>()
        .map((part) => part['text']?.toString() ?? '')
        .join('\n')
        .trim();
    if (text.isEmpty) return null;

    final jsonText = _extractJsonObject(text);
    if (jsonText == null) return null;

    final data = jsonDecode(jsonText);
    if (data is! Map<String, dynamic>) return null;

    final itemName = data['itemName']?.toString().trim() ?? '';
    final priceRaw = data['price'];
    final category = data['category']?.toString().trim();
    final description = data['description']?.toString().trim() ?? '';

    double? price;
    if (priceRaw is num) {
      price = priceRaw.toDouble();
    } else if (priceRaw != null) {
      price = double.tryParse(priceRaw.toString().replaceAll(RegExp(r'[^\d.]'), ''));
    }

    var confidence = 0.0;
    if (itemName.isNotEmpty) confidence += 0.5;
    if (price != null) confidence += 0.3;
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'null') {
      confidence += 0.15;
    }
    if (description.isNotEmpty) confidence += 0.05;

    return MenuScanResult(
      itemName: itemName,
      price: price,
      category: (category == null || category.isEmpty || category.toLowerCase() == 'null')
          ? null
          : category,
      description: description,
      confidence: confidence,
    );
  }

  String? _extractJsonObject(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return text.substring(start, end + 1);
  }

  String _mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
