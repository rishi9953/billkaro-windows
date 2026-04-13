// import 'dart:io';

// import 'package:billkaro/config/config.dart';
// import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class MapController extends BaseController {
//   final isLoading = true.obs;
//   final selectedPlace = Rxn<Placemark>();

//   // Address fields
//   final country = ''.obs;
//   final state = ''.obs;
//   final city = ''.obs;
//   final postalCode = ''.obs;
//   final street = ''.obs;
//   final locality = ''.obs;
//   final subLocality = ''.obs;
//   final subAdministrativeArea = ''.obs;
//   final fullAddress = 'Tap on the map to get address'.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     getCurrentLocation();
//   }

//   Future<void> getCurrentLocation() async {
//     try {
//       // On Windows, skip Geolocator completely (desktop often has no proper
//       // location service). We just show the map with a sensible default center
//       // and let the user pick a point manually.
//       if (Platform.isWindows) {
//         // Keep whatever default center you want here; using existing default.
//         isLoading.value = false;
//         markers.clear();
//         return;
//       }

//       // Don't block UI: map shows as soon as onMapCreated runs; we update location in background
//       // Check and request permission
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           isLoading.value = false;
//           showSuccess(
//             description:
//                 'Location permission is required to show your current location',
//           );
//           return;
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         isLoading.value = false;
//         showError(description: 'Please enable location permission in settings');
//         return;
//       }

//       // On iOS, request full accuracy so we get exact location (not approximate)
//       if (Platform.isIOS) {
//         try {
//           await Geolocator.requestTemporaryFullAccuracy(purposeKey: 'MapSelectLocation');
//         } catch (_) {
//           // Ignore if plist key not set or user denies
//         }
//       }

//       // Fast path: use last known position so map can center roughly immediately
//       Position? lastKnown = await Geolocator.getLastKnownPosition();
//       if (lastKnown != null) {
//         center.value = lat.LatLng(lastKnown.latitude, lastKnown.longitude);
//       }

//       // Then get exact position with best accuracy (may take a few seconds)
//       const timeout = Duration(seconds: 15);
//       Position position = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.best,
//           timeLimit: timeout,
//         ),
//       );

//       final currentLocation = lat.LatLng(position.latitude, position.longitude);
//       center.value = currentLocation;
//       markers.clear();
//       markers.add(
//         fm.Marker(
//           width: 40,
//           height: 40,
//           point: currentLocation,
//           alignment: Alignment.topCenter,
//           child: const Icon(Icons.location_on, color: Colors.red, size: 40),
//         ),
//       );

//       await getAddress(currentLocation);
//     } catch (e) {
//       print('Error getting current location: $e');
//       showError(description: 'Failed to get current location: ${e.toString()}');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   void onMapTapped(lat.LatLng position) async {
//     // Clear existing markers and add new marker at tapped position
//     markers.clear();
//     markers.add(
//       fm.Marker(
//         width: 40,
//         height: 40,
//         point: position,
//         alignment: Alignment.topCenter,
//         child: const Icon(Icons.location_on, color: Colors.red, size: 40),
//       ),
//     );

//     // Get address from coordinates
//     await getAddress(position);
//   }

//   Future<void> getAddress(lat.LatLng position) async {
//     try {
//       // Use OpenStreetMap Nominatim HTTP API for reverse‑geocoding so it
//       // works on Windows and other desktop platforms without native plugins.
//       final uri = Uri.parse(
//         'https://nominatim.openstreetmap.org/reverse'
//         '?format=jsonv2'
//         '&lat=${position.latitude}'
//         '&lon=${position.longitude}',
//       );

//       final response = await http.get(
//         uri,
//         headers: {
//           'User-Agent': 'billkaro/1.0 (desktop-location-picker)',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body) as Map<String, dynamic>;
//         final addr = (data['address'] as Map?) ?? {};

//         country.value = (addr['country'] ?? '').toString();
//         state.value =
//             (addr['state'] ?? addr['region'] ?? '').toString();
//         city.value =
//             (addr['city'] ?? addr['town'] ?? addr['village'] ?? '').toString();
//         postalCode.value = (addr['postcode'] ?? '').toString();
//         street.value =
//             (addr['road'] ?? addr['pedestrian'] ?? '').toString();
//         locality.value =
//             (addr['suburb'] ?? addr['neighbourhood'] ?? '').toString();
//         subLocality.value =
//             (addr['hamlet'] ?? addr['quarter'] ?? '').toString();
//         subAdministrativeArea.value =
//             (addr['county'] ?? addr['state_district'] ?? '').toString();

//         List<String> addressParts = [
//           if (street.value.isNotEmpty) street.value,
//           if (subLocality.value.isNotEmpty) subLocality.value,
//           if (locality.value.isNotEmpty) locality.value,
//           if (city.value.isNotEmpty && city.value != locality.value) city.value,
//           if (state.value.isNotEmpty) state.value,
//           if (country.value.isNotEmpty) country.value,
//           if (postalCode.value.isNotEmpty) postalCode.value,
//         ];

//         fullAddress.value = addressParts.isNotEmpty
//             ? addressParts.join(', ')
//             : '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
//       } else {
//         fullAddress.value =
//             '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
//       }
//     } catch (e) {
//       fullAddress.value = 'Error getting address';
//       print('Error: $e');
//       showError(description: 'Failed to get address details');
//     }
//   }

//   void clearMarkers() {
//     markers.clear();
//     fullAddress.value = 'Tap on the map to get address';
//     selectedPlace.value = null;
//     country.value = '';
//     state.value = '';
//     city.value = '';
//     postalCode.value = '';
//     street.value = '';
//     locality.value = '';
//     subLocality.value = '';
//     subAdministrativeArea.value = '';
//   }

//   void confirmLocation() {
//     if (selectedPlace.value == null || markers.isEmpty) {
//       showError(description: 'Please select a location on the map');
//       return;
//     }

//     final marker = markers.first;
//     final addressData = {
//       'address': fullAddress.value,
//       'street': street.value,
//       'subLocality': subLocality.value,
//       'city': city.value.isNotEmpty ? city.value : locality.value,
//       'state': state.value,
//       'country': country.value,
//       'zipcode': postalCode.value,
//       'latitude': marker.point.latitude,
//       'longitude': marker.point.longitude,
//     };

//     Get.back(result: addressData);
//   }
// }
