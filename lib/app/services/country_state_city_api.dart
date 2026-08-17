import 'package:billkaro/utils/trusted_http_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Country State City API client ([docs](https://docs.countrystatecity.in/api/introduction)).
///
/// Auth: `X-CSCAPI-KEY` from `.env` `STATE_CITY_KEY`.
/// Portal: https://app.countrystatecity.in/
class CountryStateCityApi {
  CountryStateCityApi() : _dio = Dio() {
    configureTrustedDio(_dio);
  }

  static const baseUrl = 'https://api.countrystatecity.in/v1';
  static const defaultCountryCode = 'IN';

  static final Map<String, List<CscPlace>> _statesCache = {};
  static final Map<String, List<CscPlace>> _citiesCache = {};
  static final Map<String, Future<List<CscPlace>>> _statesInFlight = {};
  static final Map<String, Future<List<CscPlace>>> _citiesInFlight = {};

  final Dio _dio;

  String get _apiKey => dotenv.env['STATE_CITY_KEY']?.trim() ?? '';

  Map<String, String> get _headers => {'X-CSCAPI-KEY': _apiKey};

  static List<CscPlace>? cachedStates([
    String countryCode = defaultCountryCode,
  ]) {
    return _statesCache[countryCode.trim().toUpperCase()];
  }

  static List<CscPlace>? cachedCities({
    required String stateIso2,
    String countryCode = defaultCountryCode,
  }) {
    final key =
        '${countryCode.trim().toUpperCase()}|${stateIso2.trim().toUpperCase()}';
    return _citiesCache[key];
  }

  /// Warm India states cache (call when Inventory opens).
  static Future<void> prefetchDefaultCountry() async {
    await CountryStateCityApi().getStatesByCountry();
  }

  Future<List<CscPlace>> getStatesByCountry({
    String countryCode = defaultCountryCode,
  }) async {
    final code = countryCode.trim().toUpperCase();
    final cached = _statesCache[code];
    if (cached != null) return cached;

    final inFlight = _statesInFlight[code];
    if (inFlight != null) return inFlight;

    final future = _fetchStates(code);
    _statesInFlight[code] = future;
    try {
      final list = await future;
      _statesCache[code] = list;
      return list;
    } finally {
      _statesInFlight.remove(code);
    }
  }

  Future<List<CscPlace>> getCitiesByState({
    required String stateIso2,
    String countryCode = defaultCountryCode,
  }) async {
    final country = countryCode.trim().toUpperCase();
    final iso = stateIso2.trim().toUpperCase();
    if (iso.isEmpty) return const [];

    final cacheKey = '$country|$iso';
    final cached = _citiesCache[cacheKey];
    if (cached != null) return cached;

    final inFlight = _citiesInFlight[cacheKey];
    if (inFlight != null) return inFlight;

    final future = _fetchCities(country: country, stateIso2: iso);
    _citiesInFlight[cacheKey] = future;
    try {
      final list = await future;
      _citiesCache[cacheKey] = list;
      return list;
    } finally {
      _citiesInFlight.remove(cacheKey);
    }
  }

  Future<List<CscPlace>> _fetchStates(String countryCode) async {
    final key = _apiKey;
    if (key.isEmpty) {
      debugPrint('STATE_CITY_KEY is not set in .env');
      return const [];
    }
    try {
      final response = await _dio.get(
        '$baseUrl/countries/$countryCode/states',
        options: Options(headers: _headers),
      );
      return _parseList(response.data);
    } catch (e) {
      debugPrint('CSC states error: $e');
      return const [];
    }
  }

  Future<List<CscPlace>> _fetchCities({
    required String country,
    required String stateIso2,
  }) async {
    final key = _apiKey;
    if (key.isEmpty) {
      debugPrint('STATE_CITY_KEY is not set in .env');
      return const [];
    }
    try {
      final response = await _dio.get(
        '$baseUrl/countries/$country/states/$stateIso2/cities',
        options: Options(headers: _headers),
      );
      return _parseList(response.data);
    } catch (e) {
      debugPrint('CSC cities error: $e');
      return const [];
    }
  }

  List<CscPlace> _parseList(dynamic data) {
    if (data is! List) return const [];
    final places = <CscPlace>[];
    for (final item in data) {
      if (item is! Map) continue;
      final place = CscPlace.fromJson(Map<String, dynamic>.from(item));
      if (place.name.isEmpty) continue;
      places.add(place);
    }
    places.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return places;
  }
}

class CscPlace {
  const CscPlace({
    required this.id,
    required this.name,
    this.iso2,
  });

  final String id;
  final String name;
  final String? iso2;

  factory CscPlace.fromJson(Map<String, dynamic> json) {
    return CscPlace(
      id: json['id']?.toString() ?? '',
      name: (json['name']?.toString() ?? '').trim(),
      iso2: json['iso2']?.toString().trim().toUpperCase(),
    );
  }
}
