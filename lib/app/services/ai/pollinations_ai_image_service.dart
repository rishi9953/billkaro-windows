import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PollinationsAiImageService {
  static const _host = 'https://image.pollinations.ai';

  Future<String> generateImage({
    required String prompt,
    int width = 512,
    int height = 512,
  }) async {
    final encoded = Uri.encodeComponent(prompt.trim());
    final seed = DateTime.now().millisecondsSinceEpoch % 999999;
    final url = Uri.parse(
      '$_host/prompt/$encoded?model=flux&width=$width&height=$height&seed=$seed&nologo=true',
    );

    final response = await http.get(
      url,
      headers: const {'Accept': 'image/*'},
    ).timeout(const Duration(seconds: 35));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw Exception('Pollinations failed (${response.statusCode})');
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(
        dir.path,
        'billkaro_pollinations_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }
}
