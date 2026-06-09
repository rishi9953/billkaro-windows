import 'dart:io';

import 'package:flutter/foundation.dart';

/// Debug-only TLS override for local dev tunnels. Never enabled in release builds.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    if (kDebugMode) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }
    return client;
  }
}
