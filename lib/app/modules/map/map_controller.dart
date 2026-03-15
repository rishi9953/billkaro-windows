import 'dart:io';

import 'package:billkaro/config/config.dart' hide Marker;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapController extends BaseController {
  GoogleMapController? mapController;

  final center = const LatLng(37.7749, -122.4194).obs;
  final markers = <Marker>{}.obs;
  final isLoading = true.obs;
  final selectedPlace = Rxn<Placemark>();

  // Address fields
  final country = ''.obs;
  final state = ''.obs;
  final city = ''.obs;
  final postalCode = ''.obs;
  final street = ''.obs;
  final locality = ''.obs;
  final subLocality = ''.obs;
  final subAdministrativeArea = ''.obs;
  final fullAddress = 'Tap on the map to get address'.obs;

  @override
  void onInit() {
    super.onInit();
    getCurrentLocation();
  }

  @override
  void onClose() {
    mapController?.dispose();
    super.onClose();
  }

  Future<void> getCurrentLocation() async {
    try {
      // Don't block UI: map shows as soon as onMapCreated runs; we update location in background
      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          isLoading.value = false;
          showSuccess(
            description:
                'Location permission is required to show your current location',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        isLoading.value = false;
        showError(description: 'Please enable location permission in settings');
        return;
      }

      // On iOS, request full accuracy so we get exact location (not approximate)
      if (Platform.isIOS) {
        try {
          await Geolocator.requestTemporaryFullAccuracy(purposeKey: 'MapSelectLocation');
        } catch (_) {
          // Ignore if plist key not set or user denies
        }
      }

      // Fast path: use last known position so map can center roughly immediately
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final lastLatLng = LatLng(lastKnown.latitude, lastKnown.longitude);
        center.value = lastLatLng;
        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: lastLatLng, zoom: 14.0),
            ),
          );
        }
      }

      // Then get exact position with best accuracy (may take a few seconds)
      const timeout = Duration(seconds: 15);
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: timeout,
        ),
      );

      LatLng currentLocation = LatLng(position.latitude, position.longitude);
      center.value = currentLocation;
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: currentLocation,
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      );

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: currentLocation, zoom: 16.0),
          ),
        );
      }

      await getAddress(currentLocation);
    } catch (e) {
      print('Error getting current location: $e');
      showError(description: 'Failed to get current location: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;

    // Move to current location if already obtained
    if (markers.isNotEmpty) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center.value, zoom: 14.0),
        ),
      );
    }

    isLoading.value = false;
  }

  void onMapTapped(LatLng position) async {
    // Clear existing markers and add new marker at tapped position
    markers.clear();
    markers.add(
      Marker(
        markerId: const MarkerId('selected'),
        position: position,
        infoWindow: const InfoWindow(title: 'Selected Location'),
      ),
    );

    // Get address from coordinates
    await getAddress(position);
  }

  Future<void> getAddress(LatLng position) async {
    try {
      // Convert coordinates to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        selectedPlace.value = placemarks[0];
        final place = placemarks[0];

        country.value = place.country ?? '';
        state.value = place.administrativeArea ?? '';
        city.value = place.locality ?? '';
        postalCode.value = place.postalCode ?? '';
        street.value = place.street ?? '';
        locality.value = place.locality ?? '';
        subLocality.value = place.subLocality ?? '';
        subAdministrativeArea.value = place.subAdministrativeArea ?? '';

        // Build full address
        List<String> addressParts = [
          if (street.value.isNotEmpty) street.value,
          if (subLocality.value.isNotEmpty) subLocality.value,
          if (locality.value.isNotEmpty) locality.value,
          if (city.value.isNotEmpty && city.value != locality.value) city.value,
          if (state.value.isNotEmpty) state.value,
          if (country.value.isNotEmpty) country.value,
          if (postalCode.value.isNotEmpty) postalCode.value,
        ];
        fullAddress.value = addressParts.join(', ');

        print('Address Details: ${place.toJson()}');
      }
    } catch (e) {
      fullAddress.value = 'Error getting address';
      print('Error: $e');
      showError(description: 'Failed to get address details');
    }
  }

  void clearMarkers() {
    markers.clear();
    fullAddress.value = 'Tap on the map to get address';
    selectedPlace.value = null;
    country.value = '';
    state.value = '';
    city.value = '';
    postalCode.value = '';
    street.value = '';
    locality.value = '';
    subLocality.value = '';
    subAdministrativeArea.value = '';
  }

  void confirmLocation() {
    if (selectedPlace.value == null || markers.isEmpty) {
      showError(description: 'Please select a location on the map');
      return;
    }

    final marker = markers.first;
    final addressData = {
      'address': fullAddress.value,
      'street': street.value,
      'subLocality': subLocality.value,
      'city': city.value.isNotEmpty ? city.value : locality.value,
      'state': state.value,
      'country': country.value,
      'zipcode': postalCode.value,
      'latitude': marker.position.latitude,
      'longitude': marker.position.longitude,
    };

    Get.back(result: addressData);
  }
}
