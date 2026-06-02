import 'dart:io';

import 'package:billkaro/app/services/ai/billkaro_ai_image_engine.dart';
import 'package:billkaro/config/config.dart';

/// Menu-item images via [BillkaroAiImageEngine] (free cloud, offline fallback).
class AIImageGenerator {
  static final AIImageGenerator _instance = AIImageGenerator._internal();
  factory AIImageGenerator() => _instance;
  AIImageGenerator._internal();

  final BillkaroAiImageEngine _engine = BillkaroAiImageEngine();

  /// Builds a food-photo prompt from the menu item name and generates a PNG.
  Future<GeneratedImageResult> generateMenuItemImage({
    required String itemName,
    void Function(String message)? onStatus,
  }) async {
    final name = BillkaroAiImageEngine.sanitizePrompt(itemName);
    if (!BillkaroAiImageEngine.isValidPrompt(name)) {
      throw ArgumentError('Item name must be at least 3 characters');
    }

    debugPrint('🎨 [AI] Generating menu image for: $name');
    final prompt =
        'Professional appetizing food photo of $name on a plate, '
        'restaurant menu, warm lighting, high quality';

    final result = await _engine.generateImage(
      prompt: prompt,
      styleKey: 'realistic',
      width: 512,
      height: 512,
      onStatus: onStatus,
    );
    debugPrint('✅ [AI] Done via ${result.provider}');
    return result;
  }

  /// Validates that [filePath] from [GeneratedImageResult] exists and is readable.
  Future<File?> fileFromResult(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists() && await file.length() > 50) return file;
      return null;
    } catch (e) {
      debugPrint('❌ [AI] File error: $e');
      return null;
    }
  }
}
