import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:billkaro/app/services/download/download_notification_service.dart';
import 'package:billkaro/utils/download_path_util.dart';
import 'package:flutter/foundation.dart';

/// Saves files on a background isolate and notifies when the download finishes.
///
/// Use this for invoice / PDF / Excel exports instead of writing on the UI
/// isolate and calling [showSuccess].
class FileDownloadService {
  FileDownloadService._();
  static final FileDownloadService instance = FileDownloadService._();

  /// Writes [bytes] to the downloads folder on a background isolate.
  ///
  /// Returns the saved [File], or `null` if the write failed.
  /// When [notify] is true, shows a download notification (not a success snackbar).
  Future<File?> saveBytes({
    required Uint8List bytes,
    required String fileName,
    String? preferredDirectory,
    bool notify = true,
    String notificationTitle = 'Download complete',
    String? notificationBody,
    int? notificationId,
  }) async {
    if (bytes.isEmpty) {
      debugPrint('❌ [DOWNLOAD] empty bytes for $fileName');
      return null;
    }

    try {
      final dir = await DownloadPathUtil.resolveSaveDirectory(
        preferredPath: preferredDirectory,
      );
      await Directory(dir).create(recursive: true);

      final safeName = _sanitizeFileName(fileName);
      final filePath = '$dir/$safeName';

      final savedPath = await Isolate.run(
        () => _writeBytesToDisk(filePath, bytes),
      );

      final file = File(savedPath);
      if (!await file.exists()) {
        debugPrint('❌ [DOWNLOAD] file missing after write: $savedPath');
        return null;
      }

      if (notify) {
        await DownloadNotificationService.instance.notifyComplete(
          fileName: safeName,
          filePath: savedPath,
          title: notificationTitle,
          body: notificationBody,
          notificationId: notificationId,
        );
      }

      return file;
    } catch (e, st) {
      debugPrint('❌ [DOWNLOAD] save failed: $e\n$st');
      rethrow;
    }
  }

  static String _sanitizeFileName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'download';
    return trimmed.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
  }
}

/// Top-level so [Isolate.run] can execute it on a background isolate.
Future<String> _writeBytesToDisk(String filePath, Uint8List bytes) async {
  final file = File(filePath);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
  return filePath;
}
