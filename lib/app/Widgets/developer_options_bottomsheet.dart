import 'dart:io' show Platform;

import 'package:billkaro/config/config.dart';
// import 'package:developer_mode_finder/developer_mode_finder.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show SystemNavigator;

/// Tracks if the developer options sheet was already shown this app session.
/// Ensures it shows only once when the app is opened, not when changing outlets.
// bool _hasShownDeveloperSheetThisSession = false;

/// Call this when you want to check developer options and show a bottom sheet if enabled.
/// Safe to call on any platform; only runs the check on Android.
/// Shows at most once per app launch (not when navigating back to home / changing outlets).
// Future<void> checkDeveloperOptionsAndShowSheet() async {
//   if (kIsWeb || !Platform.isAndroid) return;
//   if (_hasShownDeveloperSheetThisSession) return;
//   try {
//     final finder = DeveloperModeFinder();
//     final isEnabled = await finder.isDeveloperModeEnabled();
//     if (isEnabled && Get.context != null) {
//       _hasShownDeveloperSheetThisSession = true;
//       Get.bottomSheet(
//         const DeveloperOptionsBottomSheet(),
//         isScrollControlled: true,
//         backgroundColor: Colors.transparent,
//         isDismissible: false,
//         enableDrag: false,
//       );
//     }
//   } catch (_) {
//     // Package may throw on unsupported platform or if settings unavailable
//   }
// }

/// Bottom sheet shown when device has Developer Options enabled (Android).
class DeveloperOptionsBottomSheet extends StatelessWidget {
  const DeveloperOptionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Lottie Animation
            Center(
              child: Lottie.asset(
                'assets/lottie/developer.json', // or your animation file
                height: 150,
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'Developer Options Enabled',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    'Your device has Developer Options turned on. Features like mock location may affect app behavior.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Settings → System → Developer options',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => SystemNavigator.pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          label: const Text('Close App'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[600],
                            side: BorderSide(
                              color: Colors.red.withOpacity(0.3),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Get.back(),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                          label: const Text('Continue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
