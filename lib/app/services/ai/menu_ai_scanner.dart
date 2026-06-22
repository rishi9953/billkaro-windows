import 'dart:io';

import 'package:billkaro/app/services/ai/cloud_menu_ocr_service.dart';
import 'package:billkaro/app/services/ai/gemini_menu_vision_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// AI-powered menu item scanner.
/// Android/iOS: ML Kit. Desktop: cloud OCR (no native plugins).
class MenuAIScanner {
  static final MenuAIScanner _instance = MenuAIScanner._internal();
  factory MenuAIScanner() => _instance;
  MenuAIScanner._internal();

  TextRecognizer? _textRecognizer;
  ImageLabeler? _imageLabeler;
  final CloudMenuOcrService _cloudOcr = CloudMenuOcrService();
  final GeminiMenuVisionScanner _geminiVision = GeminiMenuVisionScanner();

  bool get _useMlKit {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  bool get _useCloudDesktopScan {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Scan menu item from photo.
  Future<MenuScanResult> scanMenuFromPhoto(File imageFile) async {
    try {
      debugPrint('🤖 [AI SCANNER] Starting menu scan...');

      if (_useMlKit) {
        return await _scanWithMlKit(imageFile);
      }
      if (_useCloudDesktopScan) {
        return await _scanWithCloudDesktop(imageFile);
      }

      debugPrint('⚠️ [AI SCANNER] OCR not supported on this platform');
      return _emptyResult();
    } catch (e, stack) {
      debugPrint('❌ [AI SCANNER] Error scanning menu: $e');
      debugPrint('❌ [AI SCANNER] Stack: $stack');
      return _emptyResult();
    }
  }

  Future<MenuScanResult> _scanWithMlKit(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final results = await Future.wait([
      _extractTextMlKit(inputImage),
      _extractLabelsMlKit(inputImage),
    ]);
    final extractedText = results[0] as String;
    final labels = results[1] as List<String>;

    debugPrint('📝 [AI SCANNER] Extracted text: $extractedText');
    if (labels.isNotEmpty) {
      debugPrint('🏷️ [AI SCANNER] Detected labels: ${labels.join(", ")}');
    }

    final result = _parseMenuInfo(extractedText, labels);
    debugPrint('✅ [AI SCANNER] Scan completed: ${result.itemName}');
    return result;
  }

  Future<MenuScanResult> _scanWithCloudDesktop(File imageFile) async {
    if (_geminiVision.isConfigured) {
      try {
        final geminiResult = await _geminiVision.scanMenu(imageFile);
        if (geminiResult != null && geminiResult.isValid) {
          debugPrint('✅ [AI SCANNER] Gemini vision scan: ${geminiResult.itemName}');
          return geminiResult;
        }
      } catch (e) {
        debugPrint('⚠️ [AI SCANNER] Gemini vision failed: $e');
      }
    }

    final extractedText = await _extractTextCloud(imageFile);
    debugPrint('📝 [AI SCANNER] Cloud OCR text: $extractedText');

    final result = _parseMenuInfo(extractedText, const []);
    debugPrint('✅ [AI SCANNER] Scan completed: ${result.itemName}');
    return result;
  }

  Future<String> _extractTextMlKit(InputImage inputImage) async {
    try {
      _textRecognizer ??= TextRecognizer();
      final recognizedText = await _textRecognizer!.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint('⚠️ [AI SCANNER] ML Kit OCR error: $e');
      return '';
    }
  }

  Future<List<String>> _extractLabelsMlKit(InputImage inputImage) async {
    try {
      _imageLabeler ??= ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.5),
      );
      final detected = await _imageLabeler!.processImage(inputImage);
      return detected.map((label) => label.label).toList();
    } catch (e) {
      debugPrint('⚠️ [AI SCANNER] ML Kit labeling error: $e');
      return [];
    }
  }

  Future<String> _extractTextCloud(File imageFile) async {
    try {
      return await _cloudOcr.extractText(imageFile);
    } catch (e) {
      debugPrint('⚠️ [AI SCANNER] Cloud OCR error: $e');
      return '';
    }
  }

  MenuScanResult _emptyResult() {
    return MenuScanResult(
      itemName: '',
      price: null,
      category: null,
      description: '',
      confidence: 0.0,
    );
  }

  MenuScanResult _parseMenuInfo(String text, List<String> labels) {
    String itemName = '';
    double? price;
    String? category;
    String description = '';
    double confidence = 0.0;

    final lines = text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isNotEmpty) {
      itemName = lines[0].trim();
      itemName = itemName.replaceAll(RegExp(r'[₹$€£¥]\s*\d+'), '').trim();
      itemName = itemName.replaceAll(RegExp(r'\d+\s*[₹$€£¥]'), '').trim();
    }

    final pricePattern = RegExp(
      r'[₹$€£¥]\s*(\d+(?:\.\d{2})?)|\d+(?:\.\d{2})?\s*[₹$€£¥]',
    );
    final priceMatch = pricePattern.firstMatch(text);
    if (priceMatch != null) {
      final priceStr =
          priceMatch.group(1) ??
          priceMatch.group(0)?.replaceAll(RegExp(r'[₹$€£¥\s]'), '') ??
          '';
      price = double.tryParse(priceStr);
    }

    if (price == null) {
      final numberPattern = RegExp(r'\b(\d{2,4}(?:\.\d{2})?)\b');
      final matches = numberPattern.allMatches(text);
      for (final match in matches) {
        final num = double.tryParse(match.group(1) ?? '');
        if (num != null && num >= 10 && num <= 10000) {
          price = num;
          break;
        }
      }
    }

    final foodCategories = {
      'pizza': 'Pizza',
      'burger': 'Burger',
      'pasta': 'Pasta',
      'salad': 'Salad',
      'soup': 'Soup',
      'sandwich': 'Sandwich',
      'coffee': 'Beverages',
      'tea': 'Beverages',
      'drink': 'Beverages',
      'dessert': 'Dessert',
      'cake': 'Dessert',
      'ice cream': 'Dessert',
      'chicken': 'Non-Veg',
      'meat': 'Non-Veg',
      'fish': 'Non-Veg',
      'vegetable': 'Vegetarian',
      'vegetarian': 'Vegetarian',
      'biryani': 'Main Course',
      'paneer': 'Main Course',
      'dosa': 'South Indian',
      'idli': 'South Indian',
    };

    for (final label in labels) {
      final lowerLabel = label.toLowerCase();
      for (final entry in foodCategories.entries) {
        if (lowerLabel.contains(entry.key)) {
          category = entry.value;
          break;
        }
      }
      if (category != null) break;
    }

    if (category == null) {
      final lowerText = text.toLowerCase();
      for (final entry in foodCategories.entries) {
        if (lowerText.contains(entry.key)) {
          category = entry.value;
          break;
        }
      }
    }

    if (lines.length > 1) {
      description = lines.skip(1).join(' ').trim();
      description = description.replaceAll(pricePattern, '').trim();
    }

    confidence = 0.0;
    if (itemName.isNotEmpty) confidence += 0.4;
    if (price != null) confidence += 0.3;
    if (category != null) confidence += 0.2;
    if (description.isNotEmpty) confidence += 0.1;

    return MenuScanResult(
      itemName: itemName,
      price: price,
      category: category,
      description: description,
      confidence: confidence,
    );
  }

  void dispose() {
    _textRecognizer?.close();
    _imageLabeler?.close();
    _textRecognizer = null;
    _imageLabeler = null;
  }
}

class MenuScanResult {
  final String itemName;
  final double? price;
  final String? category;
  final String description;
  final double confidence;

  MenuScanResult({
    required this.itemName,
    this.price,
    this.category,
    required this.description,
    required this.confidence,
  });

  bool get isValid => itemName.isNotEmpty && confidence > 0.3;

  @override
  String toString() {
    return 'MenuScanResult(name: $itemName, price: $price, category: $category, confidence: $confidence)';
  }
}
