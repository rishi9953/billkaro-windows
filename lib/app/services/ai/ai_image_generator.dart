import 'dart:io';
import 'package:dio/dio.dart';
import 'package:billkaro/config/config.dart';

/// AI Image Generator Service
/// Generates images based on item names using AI
class AIImageGenerator {
  static final AIImageGenerator _instance = AIImageGenerator._internal();
  factory AIImageGenerator() => _instance;
  AIImageGenerator._internal();

  final Dio _dio = Dio();

  /// Generate an image based on item name
  ///
  /// This method can be connected to various AI image generation APIs:
  /// - OpenAI DALL-E
  /// - Stable Diffusion
  /// - Custom backend API
  ///
  /// For now, it uses a placeholder approach that can be easily connected
  /// to your preferred AI image generation service.
  Future<String?> generateImageFromItemName(String itemName) async {
    try {
      debugPrint('🎨 [AI Image Generator] Generating image for: $itemName');
      final prompt = _createImagePrompt(itemName);
      return await _generateWithCustomAPI(prompt, itemName);
    } catch (e) {
      debugPrint('❌ [AI Image Generator] Error: $e');
      return null;
    }
  }

  /// Create a descriptive prompt for image generation
  String _createImagePrompt(String itemName) {
    // Create a professional food/item image prompt
    return 'Professional high-quality food photography of $itemName, '
        'restaurant menu style, appetizing, well-lit, clean background, '
        'commercial food photography, 4k quality';
  }

  /// Generate image using custom backend API
  Future<String?> _generateWithCustomAPI(String prompt, String itemName) async {
    try {
      final response = await _dio.post(
        '${baseURL}ai/generate-image', // Replace with your endpoint
        data: {
          'prompt': prompt,
          'itemName': itemName,
          'style': 'food_photography',
          'size': '1024x1024',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Adjust based on your API response structure
        final imageUrl =
            response.data['imageUrl'] ??
            response.data['url'] ??
            response.data['data']?['url'];
        if (imageUrl != null && imageUrl is String) {
          debugPrint('✅ [AI Image Generator] Image generated: $imageUrl');
          return imageUrl;
        }
      }

      debugPrint('⚠️ [AI Image Generator] Invalid response format');
      return null;
    } on DioException catch (e) {
      debugPrint('❌ [AI Image Generator] API Error: ${e.message}');
      // For development, return a placeholder
      // In production, handle this error appropriately
      return null;
    } catch (e) {
      debugPrint('❌ [AI Image Generator] Error: $e');
      return null;
    }
  }

  /// Download image from URL and save to local file
  Future<File?> downloadImageToFile(String imageUrl) async {
    try {
      debugPrint('📥 [AI Image Generator] Downloading image from: $imageUrl');

      final response = await _dio.get(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Create temporary file
        final tempDir = Directory.systemTemp;
        final file = File(
          '${tempDir.path}/ai_generated_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await file.writeAsBytes(response.data);

        debugPrint('✅ [AI Image Generator] Image saved to: ${file.path}');
        return file;
      }

      return null;
    } catch (e) {
      debugPrint('❌ [AI Image Generator] Download error: $e');
      return null;
    }
  }
}
