import 'dart:io';

import 'package:path_provider/path_provider.dart';

class DownloadPathUtil {
  static Future<String> resolveSaveDirectory({String? preferredPath}) async {
    final customPath = (preferredPath ?? '').trim();
    if (customPath.isNotEmpty) {
      final customDir = Directory(customPath);
      if (await customDir.exists()) return customPath;
      await customDir.create(recursive: true);
      return customPath;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        await downloadsDir.create(recursive: true);
        return downloadsDir.path;
      }
    }

    const androidFallbackPaths = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/sdcard/Download',
      '/sdcard/Downloads',
    ];

    for (final path in androidFallbackPaths) {
      if (await Directory(path).exists()) return path;
    }

    final fallback = androidFallbackPaths.first;
    await Directory(fallback).create(recursive: true);
    return fallback;
  }
}
