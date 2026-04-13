import 'dart:convert';

import 'package:billkaro/config/config.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as lat;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final fm.MapController _mapController = fm.MapController();

  bool _isLoading = false;
  String _addressText = 'Tap on the map to choose a location.';
  String _city = '';
  String _state = '';
  String _postalCode = '';
  String _country = '';

  lat.LatLng _center = const lat.LatLng(20.5937, 78.9629); // India center
  lat.LatLng? _selectedPosition;
  List<fm.Marker> _markers = [];

  String _pickFirstNonEmpty(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = (source[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String _stateFromDisplayName(String displayName) {
    final parts = displayName
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length >= 3) {
      // Typical reverse format: road, locality, city, state, country, zip.
      // We avoid first/last components and prefer middle-high admin area.
      final candidate = parts[parts.length - 3];
      if (candidate.isNotEmpty) return candidate;
    }
    return '';
  }

  String _extractState(Map<String, dynamic> address, String displayName) {
    final primary = _pickFirstNonEmpty(address, const [
      'state',
      'province',
      'region',
      'state_district',
      'county',
      'state_code',
      'territory',
      'union_territory',
      'administrative',
      'admin_level_4',
      'admin_level_5',
    ]);

    if (primary.isNotEmpty) return primary;
    return _stateFromDisplayName(displayName);
  }

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  Future<void> _initCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final current = lat.LatLng(position.latitude, position.longitude);
      _center = current;
      _selectedPosition = current;
      _markers = [
        fm.Marker(
          width: 40,
          height: 40,
          point: current,
          alignment: Alignment.topCenter,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      ];

      _mapController.move(current, 16);

      await _updateAddressFromPosition(current);
    } catch (_) {
      // Ignore errors; user can still tap map.
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateAddressFromPosition(lat.LatLng position) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2'
        '&lat=${position.latitude}'
        '&lon=${position.longitude}',
      );

      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'billkaro/1.0 (desktop-location-picker)'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addr = ((data['address'] as Map?) ?? {}).cast<String, dynamic>();
        final displayName = (data['display_name'] ?? '').toString();

        final country = (addr['country'] ?? '').toString();
        final mappedState = _extractState(addr, displayName);
        final city = (addr['city'] ?? addr['town'] ?? addr['village'] ?? '')
            .toString();
        final postalCode = (addr['postcode'] ?? '').toString();
        final street = (addr['road'] ?? addr['pedestrian'] ?? '').toString();
        final locality = (addr['suburb'] ?? addr['neighbourhood'] ?? '')
            .toString();
        final subLocality = (addr['hamlet'] ?? addr['quarter'] ?? '')
            .toString();

        final parts = <String>[
          if (street.isNotEmpty) street,
          if (subLocality.isNotEmpty) subLocality,
          if (locality.isNotEmpty) locality,
          if (city.isNotEmpty && city != locality) city,
          if (mappedState.isNotEmpty) mappedState,
          if (country.isNotEmpty) country,
          if (postalCode.isNotEmpty) postalCode,
        ];

        setState(() {
          _city = city.isNotEmpty ? city : locality;
          _state = mappedState;
          _postalCode = postalCode;
          _country = country;
          _addressText = parts.isNotEmpty
              ? parts.join(', ')
              : '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
      } else {
        setState(() {
          _city = '';
          _state = '';
          _postalCode = '';
          _country = '';
          _addressText =
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      setState(() {
        _addressText = 'Failed to get address';
      });
      showError(description: 'Failed to get address details: $e');
    }
  }

  Future<void> _onMapTap(lat.LatLng position) async {
    setState(() {
      _selectedPosition = position;
      _markers = [
        fm.Marker(
          width: 40,
          height: 40,
          point: position,
          alignment: Alignment.topCenter,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      ];
      _addressText = 'Fetching address...';
    });

    await _updateAddressFromPosition(position);
  }

  void _confirmAndReturn() {
    if (_selectedPosition == null) {
      showError(description: 'Please tap on the map to select a location.');
      return;
    }

    final result = {
      'address': _addressText,
      'city': _city,
      'state': _state,
      'zipcode': _postalCode,
      'country': _country,
      'latitude': _selectedPosition!.latitude,
      'longitude': _selectedPosition!.longitude,
    };

    Get.back(result: result);
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final hasValue = value.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColor.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ${hasValue ? value : '-'}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backGroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColor.backGroundColor,
        iconTheme: const IconThemeData(color: AppColor.black87),
        title: Text(
          'Select Location',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColor.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        fm.FlutterMap(
                          mapController: _mapController,
                          options: fm.MapOptions(
                            initialCenter: _center,
                            initialZoom: 5,
                            onTap: (_, point) => _onMapTap(point),
                          ),
                          children: [
                            fm.TileLayer(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                              userAgentPackageName:
                                  'com.example.billkaro_windows',
                            ),
                            fm.MarkerLayer(markers: _markers),
                          ],
                        ),
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Material(
                            elevation: 0,
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: _isLoading ? null : _initCurrentLocation,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.my_location_rounded,
                                      size: 18,
                                      color: AppColor.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Use current location',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(color: AppColor.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_isLoading)
                          Container(
                            color: Colors.black.withOpacity(0.08),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Selected Address',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _addressText,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildMetaChip(
                              icon: Icons.location_city_rounded,
                              label: 'City',
                              value: _city,
                            ),
                            _buildMetaChip(
                              icon: Icons.map_rounded,
                              label: 'State',
                              value: _state,
                            ),
                            _buildMetaChip(
                              icon: Icons.markunread_mailbox_rounded,
                              label: 'Zip',
                              value: _postalCode,
                            ),
                            _buildMetaChip(
                              icon: Icons.public_rounded,
                              label: 'Country',
                              value: _country,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _confirmAndReturn,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColor.primary,
                              foregroundColor: AppColor.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Confirm Location',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
