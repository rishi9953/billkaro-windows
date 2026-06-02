import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:billkaro/app/services/ai/billkaro_ai_image_painter.dart';
import 'package:billkaro/app/services/ai/free_cloud_ai_image_service.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Image generation: free cloud AI first, on-device art as fallback.
class BillkaroAiImageEngine {
  static const stylePresets = <String, String>{
    'None': 'balanced',
    'Realistic': 'realistic',
    'Cartoon': 'cartoon',
    'Anime': 'anime',
    'Digital Art': 'digital',
    'Watercolor': 'watercolor',
    '3D Render': 'render3d',
  };

  static const sizePresets = <String, ({int width, int height})>{
    'Square (512)': (width: 512, height: 512),
    'Landscape': (width: 768, height: 512),
    'Portrait': (width: 512, height: 768),
    'HD Square': (width: 768, height: 768),
  };

  final FreeCloudAiImageService _cloud = FreeCloudAiImageService();

  static String sanitizePrompt(String input) {
    return input.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool isValidPrompt(String input) {
    return sanitizePrompt(input).length >= 3;
  }

  Future<GeneratedImageResult> generateImage({
    required String prompt,
    String styleKey = 'balanced',
    int width = 512,
    int height = 512,
    void Function(String message)? onStatus,
  }) async {
    final clean = sanitizePrompt(prompt);
    if (!isValidPrompt(clean)) {
      throw ArgumentError('Prompt must be at least 3 characters');
    }

    // 1) Free third-party cloud (no user API key)
    try {
      final cloud = await _cloud.generate(
        prompt: clean,
        styleKey: styleKey,
        width: width,
        height: height,
        onStatus: onStatus,
      );
      return GeneratedImageResult(
        filePath: cloud.filePath,
        width: cloud.width,
        height: cloud.height,
        provider: cloud.provider,
        isCloud: true,
      );
    } catch (e) {
      onStatus?.call('Cloud busy — using offline backup artist…');
    }

    // 2) On-device fallback (always works, no network)
    return _generateLocal(
      prompt: clean,
      styleKey: styleKey,
      width: width,
      height: height,
      onStatus: onStatus,
    );
  }

  Future<GeneratedImageResult> _generateLocal({
    required String prompt,
    required String styleKey,
    required int width,
    required int height,
    void Function(String message)? onStatus,
  }) async {
    await _ensureFlutterReady();

    onStatus?.call('Creating offline artwork…');
    final analysis = PromptAnalyzer.analyze(prompt);
    final seed = prompt.hashCode ^ styleKey.hashCode ^ width ^ height;

    final bytes = await _renderPng(
      analysis: analysis,
      styleKey: styleKey,
      seed: seed,
      width: width,
      height: height,
    );

    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(
        dir.path,
        'billkaro_local_${seed.abs()}_${DateTime.now().millisecondsSinceEpoch}.png',
      ),
    );
    await file.writeAsBytes(bytes);

    return GeneratedImageResult(
      filePath: file.path,
      width: width,
      height: height,
      provider: 'Billkaro Offline',
      isCloud: false,
    );
  }

  Future<void> _ensureFlutterReady() async {
    final binding = WidgetsBinding.instance;
    if (binding.rootElement == null) {
      await binding.endOfFrame;
    }
  }

  Future<Uint8List> _renderPng({
    required PromptAnalysis analysis,
    required String styleKey,
    required int seed,
    required int width,
    required int height,
  }) async {
    final painter = BillkaroAiImagePainter(
      analysis: analysis,
      styleKey: styleKey,
      seed: seed,
    );
    final size = Size(width.toDouble(), height.toDouble());

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(width, height);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw Exception('PNG encode failed');
        return data.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  }
}

class GeneratedImageResult {
  GeneratedImageResult({
    required this.filePath,
    required this.width,
    required this.height,
    required this.provider,
    required this.isCloud,
  });

  final String filePath;
  final int width;
  final int height;
  final String provider;
  final bool isCloud;

  double get aspectRatio => width / height;
}
