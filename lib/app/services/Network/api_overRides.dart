import 'dart:io';

import 'package:flutter/foundation.dart';

/// Global HTTP overrides so every dart:io client uses the same TLS rules.
///
/// Must use [super.createHttpClient] — never construct [HttpClient] here, or
/// the factory re-enters this override and stack-overflows on startup.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(
      context ?? SecurityContext(withTrustedRoots: true),
    );
    if (!kIsWeb && Platform.isWindows) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }
    return client;
  }
}
