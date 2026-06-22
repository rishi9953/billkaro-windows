import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client? _httpClient;

/// Native [HttpClient] with system trusted certificate roots.
HttpClient createTrustedHttpClient() {
  return HttpClient(context: SecurityContext(withTrustedRoots: true));
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
