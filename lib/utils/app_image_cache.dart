import 'dart:io';

import 'package:billkaro/utils/trusted_http_client.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Windows-safe image cache for [CachedNetworkImage].
///
/// Uses JSON metadata (not sqflite) and the same trusted HTTP client as Dio,
/// so release builds can download and cache media reliably on desktop.
class AppImageCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'billkaroMediaCache';

  static AppImageCacheManager? _instance;

  factory AppImageCacheManager() {
    return _instance ??= AppImageCacheManager._();
  }

  AppImageCacheManager._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 500,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(
            httpClient: kIsWeb ? null : trustedHttpClient(),
          ),
        ),
      );

  /// Call once from [main] before the first network image loads.
  static Future<void> ensureInitialized() async {
    if (!kIsWeb) {
      try {
        final support = await getApplicationSupportDirectory();
        final cacheDir = Directory(p.join(support.path, key));
        if (!await cacheDir.exists()) {
          await cacheDir.create(recursive: true);
        }
      } catch (e) {
        debugPrint('⚠️ [IMAGE CACHE] Failed to prepare cache dir: $e');
      }
    }

    CachedNetworkImageProvider.defaultCacheManager = AppImageCacheManager();
  }
}
