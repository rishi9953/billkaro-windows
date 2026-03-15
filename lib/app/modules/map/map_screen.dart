import 'package:billkaro/app/modules/map/map_controller.dart';
import 'package:billkaro/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart';


class MapScreen extends GetView<MapController> {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    Get.put(MapController());

    return Scaffold(
      appBar: AppBar(
        title:  Text('Select Location',style: TextStyle(color: AppColor.white),),
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.clear), onPressed: controller.clearMarkers, tooltip: 'Clear Selection')],
      ),
      body: Obx(
        () => Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    onMapCreated: controller.onMapCreated,
                    initialCameraPosition: CameraPosition(target: controller.center.value, zoom: 12.0),
                    markers: controller.markers,
                    onTap: controller.onMapTapped,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapToolbarEnabled: false,
                    zoomControlsEnabled: true,
                    compassEnabled: true,
                  ),
                ),

                // Address Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Lottie.asset(
                            'assets/lottie/LocationPin.json',
                            width: 30,
    
                            fit: BoxFit.cover,
                            repeat: true,
                          ),
                          // Icon(Icons.location_on, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Selected Location',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(controller.fullAddress.value, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4)),
                      const SizedBox(height: 16),

                      // Confirm Button
                      ElevatedButton(
                        onPressed: controller.confirmLocation,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: const Size(double.infinity, 48),
                          elevation: 0,
                        ),
                        child: const Text('Confirm Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Loading overlay
            if (controller.isLoading.value)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      const SizedBox(height: 16),
                      Text(
                        'Loading Map...',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Obx(
        () => !controller.isLoading.value
            ? FloatingActionButton(
                onPressed: controller.getCurrentLocation,
                backgroundColor: AppColor.primary,
                tooltip: 'Go to Current Location',
                child: const Icon(Icons.my_location, color: Colors.white),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
