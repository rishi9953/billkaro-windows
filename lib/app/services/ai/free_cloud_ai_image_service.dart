import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Free third-party image APIs — no user API key or payment required.
///
/// Uses Stable Horde's public anonymous key and Pollinations open URLs.
/// Falls back to caller's local engine when cloud is busy.
class FreeCloudAiImageService {
  /// Stable Horde anonymous key (official, free, no signup).
  static const _hordeAnonKey = '00000000000000000000000000000000';
  static const _hordeBase = 'https://stablehorde.net/api/v2';
  static const _hordeAgent = 'billkaro:1.0:anonymous@billkaro.app';

  static const _pollinationsHost = 'https://image.pollinations.ai';

  static String _styleSuffix(String styleKey) {
    switch (styleKey) {
      case 'realistic':
        return ', photorealistic, highly detailed, professional photography';
      case 'cartoon':
        return ', cartoon style, vibrant colors, clean illustration';
      case 'anime':
        return ', anime style, detailed digital illustration';
      case 'digital':
        return ', digital art, concept art, dramatic lighting';
      case 'watercolor':
        return ', watercolor painting, soft brush strokes';
      case 'render3d':
        return ', 3d render, octane render, cinematic lighting';
      default:
        return ', high quality, detailed';
    }
  }

  static String _pollinationsModel(String styleKey) {
    switch (styleKey) {
      case 'anime':
      case 'cartoon':
        return 'flux-anime';
      case 'realistic':
        return 'flux';
      default:
        return 'turbo';
    }
  }

  /// Tries cloud providers in order. Returns local file path to PNG/JPEG.
  Future<CloudImageResult> generate({
    required String prompt,
    String styleKey = 'balanced',
    int width = 512,
    int height = 512,
    void Function(String message)? onStatus,
  }) async {
    final fullPrompt = '$prompt${_styleSuffix(styleKey)}';

    // 1) Stable Horde — most reliable free tier (public anonymous key)
    try {
      onStatus?.call('Connecting to Stable Horde (free)…');
      final path = await _generateViaStableHorde(
        prompt: fullPrompt,
        width: width,
        height: height,
        onStatus: onStatus,
      );
      return CloudImageResult(
        filePath: path,
        provider: 'Stable Horde',
        width: width,
        height: height,
      );
    } catch (e) {
      onStatus?.call('Stable Horde busy, trying Pollinations…');
    }

    // 2) Pollinations legacy URL (no user key in query)
    try {
      onStatus?.call('Please wait generating image…');
      final path = await _generateViaPollinations(
        prompt: fullPrompt,
        styleKey: styleKey,
        width: width,
        height: height,
      );
      return CloudImageResult(
        filePath: path,
        provider: 'Pollinations',
        width: width,
        height: height,
      );
    } catch (_) {
      // try alternate pollinations path
      try {
        final path = await _generateViaPollinationsAlt(
          prompt: fullPrompt,
          styleKey: styleKey,
          width: width,
          height: height,
        );
        return CloudImageResult(
          filePath: path,
          provider: 'Pollinations',
          width: width,
          height: height,
        );
      } catch (_) {}
    }

    throw Exception(
      'Free AI servers are busy. Retrying may help, or use again in a minute.',
    );
  }

  Future<String> _generateViaStableHorde({
    required String prompt,
    required int width,
    required int height,
    void Function(String message)? onStatus,
  }) async {
    final submit = await http
        .post(
          Uri.parse('$_hordeBase/generate/async'),
          headers: _hordeHeaders(),
          body: jsonEncode({
            'prompt': prompt,
            'params': {
              'width': width.clamp(64, 1024),
              'height': height.clamp(64, 1024),
              'steps': 28,
              'cfg_scale': 7,
              'sampler_name': 'k_euler',
            },
            'nsfw': false,
            'censor_nsfw': true,
            'trusted_workers': false,
            'r2': true,
            'shared': false,
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (submit.statusCode != 202 && submit.statusCode != 200) {
      throw _hordeError(submit);
    }

    final jobId = (jsonDecode(submit.body) as Map)['id'] as String?;
    if (jobId == null) throw Exception('Horde rejected job');

    final deadline = DateTime.now().add(const Duration(minutes: 8));
    while (DateTime.now().isBefore(deadline)) {
      final check = await http
          .get(
            Uri.parse('$_hordeBase/generate/check/$jobId'),
            headers: _hordeHeaders(),
          )
          .timeout(const Duration(seconds: 25));

      if (check.statusCode != 200) throw _hordeError(check);

      final data = jsonDecode(check.body) as Map<String, dynamic>;
      if (data['faulted'] == true) {
        throw Exception('Generation faulted on workers');
      }

      if (data['done'] == true) {
        onStatus?.call('Downloading image…');
        final imgSource = await _hordeFetchImage(jobId);
        return _saveImageSource(imgSource, width, height);
      }

      final wait = data['wait_time'];
      if (wait is num && wait > 0) {
        onStatus?.call('Queue ~${wait.ceil()}s (free workers)…');
      } else {
        onStatus?.call('AI workers generating…');
      }
      await Future.delayed(const Duration(seconds: 4));
    }
    throw Exception('Stable Horde timed out');
  }

  Future<String> _hordeFetchImage(String jobId) async {
    final res = await http
        .get(
          Uri.parse('$_hordeBase/generate/status/$jobId'),
          headers: _hordeHeaders(),
        )
        .timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) throw _hordeError(res);

    final gens = (jsonDecode(res.body) as Map)['generations'] as List?;
    if (gens == null || gens.isEmpty) throw Exception('No image from Horde');

    final img = (gens.first as Map)['img'] as String?;
    if (img == null || img.isEmpty) throw Exception('Empty Horde image');
    return img;
  }

  Future<String> _generateViaPollinations({
    required String prompt,
    required String styleKey,
    required int width,
    required int height,
  }) async {
    final seed = DateTime.now().millisecondsSinceEpoch % 999999;
    final model = _pollinationsModel(styleKey);
    final encoded = Uri.encodeComponent(prompt);
    final url = Uri.parse('$_pollinationsHost/prompt/$encoded').replace(
      queryParameters: {
        'model': model,
        'width': '${width.clamp(256, 1024)}',
        'height': '${height.clamp(256, 1024)}',
        'seed': '$seed',
        'nologo': 'true',
        'enhance': 'false',
      },
    );
    return _downloadPollinationsUrl(url.toString());
  }

  Future<String> _generateViaPollinationsAlt({
    required String prompt,
    required String styleKey,
    required int width,
    required int height,
  }) async {
    final seed = DateTime.now().millisecondsSinceEpoch % 999999;
    final model = _pollinationsModel(styleKey);
    final url =
        '$_pollinationsHost/prompt/${Uri.encodeComponent(prompt)}?model=$model&width=$width&height=$height&seed=$seed&nologo=true';
    return _downloadPollinationsUrl(url);
  }

  Future<String> _downloadPollinationsUrl(String url) async {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 120));

    if (response.statusCode == 402 || response.statusCode == 429) {
      throw Exception('Pollinations rate limit');
    }

    final bytes = response.bodyBytes;
    if (bytes.isEmpty) throw Exception('Empty Pollinations response');

    // Rate-limit / payment errors return JSON (x402)
    if (_looksLikeJson(bytes)) {
      final text = utf8.decode(bytes);
      if (text.contains('Queue full') ||
          text.contains('x402') ||
          text.contains('pollinations.ai')) {
        throw Exception('Pollinations rate limit');
      }
      throw Exception('Pollinations returned an error');
    }

    if (!_isImageBytes(bytes)) {
      throw Exception('Invalid image from Pollinations');
    }

    return _writeBytes(bytes, 'pollinations');
  }

  Future<String> _saveImageSource(
    String source,
    int width,
    int height,
  ) async {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      final response = await http
          .get(Uri.parse(source))
          .timeout(const Duration(seconds: 120));
      if (response.statusCode != 200 || !_isImageBytes(response.bodyBytes)) {
        throw Exception('Failed to download cloud image');
      }
      return _writeBytes(response.bodyBytes, 'horde');
    }

    var payload = source;
    if (payload.contains(',')) payload = payload.split(',').last;
    final bytes = base64Decode(payload);
    if (!_isImageBytes(bytes)) throw Exception('Invalid Horde image data');
    return _writeBytes(bytes, 'horde');
  }

  Future<String> _writeBytes(Uint8List bytes, String tag) async {
    final dir = await getTemporaryDirectory();
    final ext = _isPng(bytes) ? 'png' : 'jpg';
    final file = File(
      p.join(
        dir.path,
        'billkaro_${tag}_${DateTime.now().millisecondsSinceEpoch}.$ext',
      ),
    );
    await file.writeAsBytes(bytes);
    return file.path;
  }

  bool _isImageBytes(Uint8List bytes) {
    if (bytes.length < 12) return false;
    if (_isPng(bytes)) return true;
    // JPEG
    return bytes[0] == 0xFF && bytes[1] == 0xD8;
  }

  bool _isPng(Uint8List bytes) =>
      bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47;

  bool _looksLikeJson(Uint8List bytes) {
    if (bytes.isEmpty) return false;
    final first = bytes[0];
    return first == 0x7B || first == 0x5B; // { or [
  }

  Map<String, String> _hordeHeaders() => {
        'Content-Type': 'application/json',
        'apikey': _hordeAnonKey,
        'Client-Agent': _hordeAgent,
      };

  Exception _hordeError(http.Response r) {
    try {
      final m = jsonDecode(r.body);
      if (m is Map && m['message'] != null) {
        return Exception(m['message'].toString());
      }
    } catch (_) {}
    return Exception('Stable Horde error (${r.statusCode})');
  }
}

class CloudImageResult {
  CloudImageResult({
    required this.filePath,
    required this.provider,
    required this.width,
    required this.height,
  });

  final String filePath;
  final String provider;
  final int width;
  final int height;
}
