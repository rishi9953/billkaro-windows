import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client? _httpClient;

/// Native [HttpClient] with trusted certificate roots.
///
/// Relies on [HttpOverrides.global] ([MyHttpOverrides]) when set. Do not
/// implement TLS here by calling [HttpClient] in a way that re-enters overrides
/// without `super.createHttpClient`, or startup will stack-overflow.
HttpClient createTrustedHttpClient() {
  // Goes through [MyHttpOverrides] when installed; otherwise uses Dart defaults.
  final client = HttpClient(context: SecurityContext(withTrustedRoots: true));
  if (!kIsWeb && Platform.isWindows) {
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
  }
  return client;
}

/// Applies the same TLS settings to Dio used by Retrofit API calls.
void configureTrustedDio(Dio dio) {
  if (kIsWeb) return;
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: createTrustedHttpClient,
  );
}

/// Shared HTTP client for direct REST calls (e.g. signup fallback, Nominatim).
http.Client trustedHttpClient() {
  if (kIsWeb) {
    return http.Client();
  }

  _httpClient ??= IOClient(createTrustedHttpClient());
  return _httpClient!;
}
