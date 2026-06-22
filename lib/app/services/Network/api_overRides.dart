import 'dart:io';

import 'package:billkaro/utils/trusted_http_client.dart';

/// Global HTTP overrides so every dart:io client uses the same TLS rules.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    if (context == null) {
      return createTrustedHttpClient();
    }
    return super.createHttpClient(context);
  }
}
