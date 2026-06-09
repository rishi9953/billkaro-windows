import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/Network/api_config.dart';
import 'package:billkaro/config/config.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the backend web Kitchen Display (`/api/kds/display`) in the system browser.
class KitchenDisplayBrowser {
  static String buildDisplayUrl({
    required String apiBase,
    required String outletId,
    required String token,
    String? outletName,
  }) {
    final base = apiBase.endsWith('/') ? apiBase : '$apiBase/';
    return Uri.parse('${base}kds/display')
        .replace(
          queryParameters: {
            'outletId': outletId,
            'token': token,
            if (outletName != null && outletName.trim().isNotEmpty)
              'outletName': outletName.trim(),
          },
        )
        .toString();
  }

  static bool canOpenForCurrentOutlet() {
    if (!HomeMainRoutes.kotFeatureEnabled()) return false;
    final outletId = Get.find<AppPref>().selectedOutlet?.id;
    return outletId != null && outletId.isNotEmpty;
  }

  static Future<void> open() async {
    if (!HomeMainRoutes.kotFeatureEnabled()) {
      showError(description: 'Enable KOT mode in Settings for a cafe/restaurant outlet');
      return;
    }

    final appPref = Get.find<AppPref>();
    final outletId = appPref.selectedOutlet?.id;
    final token = appPref.token;

    if (outletId == null || outletId.isEmpty) {
      showError(description: 'Please select an outlet first');
      return;
    }

    if (token.isEmpty) {
      showError(description: 'Please log in again');
      return;
    }

    final url = buildDisplayUrl(
      apiBase: ApiConfig.baseUrl,
      outletId: outletId,
      token: token,
      outletName: appPref.selectedOutlet?.businessName,
    );

    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        showError(description: 'Could not open browser for Kitchen Display');
      }
    } catch (e) {
      debugPrint('Kitchen Display browser open failed: $e');
      showError(description: 'Could not open browser for Kitchen Display');
    }
  }
}
