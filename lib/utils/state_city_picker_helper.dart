import 'package:billkaro/app/services/country_state_city_api.dart';
import 'package:get/get.dart';

/// Loads India states/cities for dependent dropdowns.
class StateCityPickerHelper {
  StateCityPickerHelper({
    String? initialStateName,
    String? initialCityName,
    CountryStateCityApi? api,
  }) : _api = api ?? CountryStateCityApi(),
       preferredStateName = (initialStateName ?? '').trim(),
       preferredCityName = (initialCityName ?? '').trim();

  final CountryStateCityApi _api;

  final states = <CscPlace>[].obs;
  final cities = <CscPlace>[].obs;
  final isLoadingStates = false.obs;
  final isLoadingCities = false.obs;

  /// Selected state ISO2 (e.g. MH).
  final selectedStateIso = RxnString();

  /// Selected display names persisted to form payloads.
  final selectedStateName = RxnString();
  final selectedCityName = RxnString();

  String preferredStateName;
  String preferredCityName;

  List<String> get stateNames => states.map((s) => s.name).toList(growable: false);

  List<String> get cityNames => cities.map((c) => c.name).toList(growable: false);

  bool get hasStateSelected => (selectedStateIso.value ?? '').trim().isNotEmpty;

  /// Reset selection and optionally seed preferred names (edit mode).
  void applyInitial({String? stateName, String? cityName}) {
    preferredStateName = (stateName ?? '').trim();
    preferredCityName = (cityName ?? '').trim();
    selectedStateIso.value = null;
    selectedStateName.value = null;
    selectedCityName.value = null;
    cities.clear();
    initInBackground();
  }

  /// Uses warm cache when available; otherwise loads in the background.
  void initInBackground() {
    final cached = CountryStateCityApi.cachedStates();
    if (cached != null && cached.isNotEmpty) {
      states.assignAll(cached);
      if (preferredStateName.isNotEmpty) {
        // ignore: discarded_futures
        _applyPreferredFromCacheOrNetwork();
      }
      return;
    }
    if (states.isNotEmpty) {
      if (preferredStateName.isNotEmpty) {
        // ignore: discarded_futures
        _applyPreferredFromCacheOrNetwork();
      }
      return;
    }
    if (isLoadingStates.value) return;
    // ignore: discarded_futures
    init();
  }

  Future<void> init() async {
    await loadStates();
  }

  Future<void> _applyPreferredFromCacheOrNetwork() async {
    final match = _findByName(states, preferredStateName);
    if (match == null) return;
    await selectState(
      match,
      preferCityName: preferredCityName,
      clearCityIfMissing: false,
    );
  }

  Future<void> loadStates() async {
    if (isLoadingStates.value) return;
    isLoadingStates.value = true;
    try {
      final list = await _api.getStatesByCountry();
      states.assignAll(list);

      if (preferredStateName.isNotEmpty) {
        final match = _findByName(list, preferredStateName);
        if (match != null) {
          await selectState(
            match,
            preferCityName: preferredCityName,
            clearCityIfMissing: false,
          );
          return;
        }
      }
    } finally {
      isLoadingStates.value = false;
    }
  }

  Future<void> onStateNameChanged(String? stateName) async {
    final name = (stateName ?? '').trim();
    if (name.isEmpty) {
      selectedStateIso.value = null;
      selectedStateName.value = null;
      selectedCityName.value = null;
      cities.clear();
      return;
    }
    final match = _findByName(states, name);
    if (match == null) return;
    await selectState(match);
  }

  Future<void> selectState(
    CscPlace state, {
    String? preferCityName,
    bool clearCityIfMissing = true,
  }) async {
    selectedStateIso.value = state.iso2;
    selectedStateName.value = state.name;
    selectedCityName.value = null;
    cities.clear();

    final iso = (state.iso2 ?? '').trim();
    if (iso.isEmpty) return;

    final cachedCities = CountryStateCityApi.cachedCities(stateIso2: iso);
    if (cachedCities != null) {
      cities.assignAll(cachedCities);
      final prefer = (preferCityName ?? preferredCityName).trim();
      if (prefer.isNotEmpty) {
        final match = _findByName(cachedCities, prefer);
        if (match != null) {
          selectedCityName.value = match.name;
          return;
        }
      }
      if (clearCityIfMissing) {
        selectedCityName.value = null;
      }
      return;
    }

    isLoadingCities.value = true;
    try {
      final list = await _api.getCitiesByState(stateIso2: iso);
      cities.assignAll(list);

      final prefer = (preferCityName ?? preferredCityName).trim();
      if (prefer.isNotEmpty) {
        final match = _findByName(list, prefer);
        if (match != null) {
          selectedCityName.value = match.name;
          return;
        }
      }
      if (clearCityIfMissing) {
        selectedCityName.value = null;
      }
    } finally {
      isLoadingCities.value = false;
    }
  }

  void selectCity(String? cityName) {
    selectedCityName.value = (cityName ?? '').trim().isEmpty
        ? null
        : cityName!.trim();
  }

  CscPlace? _findByName(List<CscPlace> places, String name) {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    return places.firstWhereOrNull((p) => p.name.toLowerCase() == needle) ??
        places.firstWhereOrNull((p) => p.name.toLowerCase().contains(needle));
  }
}
