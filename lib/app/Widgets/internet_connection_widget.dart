import 'dart:async';

import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/app_snackbar.dart';

Widget wrapWithConnectivityBanner(BuildContext context, Widget? child) {
  Get.put(InternetConnectionController(), permanent: true);
  return child ?? const SizedBox.shrink();
}

class InternetConnectionController extends BaseController {
  bool? _previousState;

  @override
  void onReady() {
    super.onReady();

    unawaited(
      ConnectivityHelper.instance.refreshStatus().then((_) {
        _previousState = ConnectivityHelper.instance.isConnected;
      }),
    );

    streams.add(
      ConnectivityHelper.instance.networkConnectedRx.listen(_handleConnectivity),
    );
    streams.add(
      ConnectivityHelper.instance.onConnectivityChange.listen(_handleConnectivity),
    );
  }

  void _handleConnectivity(bool connected) {
    if (_previousState == connected) return;

    final wasConnected = _previousState;
    _previousState = connected;

    // Skip the very first emission — no toast until we have a real previous state
    if (wasConnected == null) return;

    if (!connected) {
      _showToast(isOnline: false);
    } else {
      _showToast(isOnline: true);
    }
  }

  void _showToast({required bool isOnline}) {
    final context = Get.context;
    if (context == null) return;

    final loc = AppLocalizations.of(context)!;
    AppSnackbar.showConnectivity(
      title: isOnline ? loc.status_online : loc.status_offline,
      message: isOnline ? loc.internet_connection_restored : loc.internet_connection_lost,
      badge: isOnline ? loc.status_online : loc.status_offline,
      isOnline: isOnline,
    );
  }
}
