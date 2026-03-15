import 'package:flutter/foundation.dart';

/// Utility class to filter and manage log messages
class LogFilter {
  /// Suppress non-critical warnings in release mode
  static void setupLogFiltering() {
    if (kReleaseMode) {
      // In release mode, suppress verbose logs
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null && _shouldLog(message)) {
          debugPrintThrottled(message, wrapWidth: wrapWidth);
        }
      };
    }
  }

  /// Check if a log message should be displayed
  static bool _shouldLog(String message) {
    // Filter out known harmless warnings
    final suppressedPatterns = [
      'userfaultfd',
      'ApkAssets: Deleting',
      'hiddenapi: Accessing hidden method',
      'FilePhenotypeFlags',
      'clearcut_client',
    ];

    for (final pattern in suppressedPatterns) {
      if (message.contains(pattern)) {
        return false; // Don't log this message
      }
    }

    return true; // Log this message
  }

  /// Throttled debug print to avoid log spam
  static void debugPrintThrottled(String? message, {int? wrapWidth}) {
    if (kDebugMode && message != null) {
      debugPrint(message, wrapWidth: wrapWidth);
    }
  }
}












