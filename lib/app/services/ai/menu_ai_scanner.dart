import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:flutter/foundation.dart';

/// AI-powered menu item scanner
/// Extracts menu item information from photos using ML Kit
class MenuAIScanner {
  static final MenuAIScanner _instance = MenuAIScanner._internal();
  factory MenuAIScanner() => _instance;
  MenuAIScanner._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImageLabeler _imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.5),
  );

  /// Scan menu item from photo
  /// Returns extracted information: name, price, category, description
  Future<MenuScanResult> scanMenuFromPhoto(File imageFile) async {
    try {
      debugPrint('🤖 [AI SCANNER] Starting menu scan...');
      
      final inputImage = InputImage.fromFile(imageFile);
      
      // Run OCR and image labeling in parallel
      final results = await Future.wait([
        _extractText(inputImage),
        _extractLabels(inputImage),
      ]);

      final extractedText = results[0] as String;
      final labels = results[1] as List<String>;

      debugPrint('📝 [AI SCANNER] Extracted text: $extractedText');
      debugPrint('🏷️ [AI SCANNER] Detected labels: ${labels.join(", ")}');

      // Parse extracted information
      final result = _parseMenuInfo(extractedText, labels);

      debugPrint('✅ [AI SCANNER] Scan completed: ${result.itemName}');
      return result;
    } catch (e, stack) {
      debugPrint('❌ [AI SCANNER] Error scanning menu: $e');
      debugPrint('❌ [AI SCANNER] Stack: $stack');
      return MenuScanResult(
        itemName: '',
        price: null,
        category: null,
        description: '',
        confidence: 0.0,
      );
    }
  }

  /// Extract text from image using OCR
  Future<String> _extractText(InputImage inputImage) async {
    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint('⚠️ [AI SCANNER] OCR error: $e');
      return '';
    }
  }

  /// Extract labels/categories from image
  Future<List<String>> _extractLabels(InputImage inputImage) async {
    try {
      final labels = await _imageLabeler.processImage(inputImage);
      return labels.map((label) => label.label).toList();
    } catch (e) {
      debugPrint('⚠️ [AI SCANNER] Labeling error: $e');
      return [];
    }
  }

  /// Parse menu information from extracted text and labels
  MenuScanResult _parseMenuInfo(String text, List<String> labels) {
    String itemName = '';
    double? price;
    String? category;
    String description = '';
    double confidence = 0.0;

    // Extract item name (usually the first line or largest text)
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      // First line is often the item name
      itemName = lines[0].trim();
      
      // Remove common price patterns from name
      itemName = itemName.replaceAll(RegExp(r'[₹$€£¥]\s*\d+'), '').trim();
      itemName = itemName.replaceAll(RegExp(r'\d+\s*[₹$€£¥]'), '').trim();
    }

    // Extract price (look for currency symbols and numbers)
    final pricePattern = RegExp(r'[₹$€£¥]\s*(\d+(?:\.\d{2})?)|\d+(?:\.\d{2})?\s*[₹$€£¥]');
    final priceMatch = pricePattern.firstMatch(text);
    if (priceMatch != null) {
      final priceStr = priceMatch.group(1) ?? priceMatch.group(0)?.replaceAll(RegExp(r'[₹$€£¥\s]'), '') ?? '';
      price = double.tryParse(priceStr);
    }

    // If no price found, look for standalone numbers that might be prices
    if (price == null) {
      final numberPattern = RegExp(r'\b(\d{2,4}(?:\.\d{2})?)\b');
      final matches = numberPattern.allMatches(text);
      for (final match in matches) {
        final num = double.tryParse(match.group(1) ?? '');
        if (num != null && num >= 10 && num <= 10000) {
          // Likely a price (between ₹10 and ₹10000)
          price = num;
          break;
        }
      }
    }

    // Infer category from labels
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

    // Extract description (remaining text after name and price)
    if (lines.length > 1) {
      description = lines.skip(1).join(' ').trim();
      // Remove price from description
      description = description.replaceAll(pricePattern, '').trim();
    }

    // Calculate confidence based on extracted data
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

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
    _imageLabeler.close();
  }
}

/// Result of AI menu scanning
class MenuScanResult {
  final String itemName;
  final double? price;
  final String? category;
  final String description;
  final double confidence; // 0.0 to 1.0

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

