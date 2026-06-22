import 'dart:async';

import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/app_snackbar.dart';

Widget wrapWithConnectivityBanner(BuildContext context, Widget? child) {
  Get.put(InternetConnectionController(), permanent: true);
  return child ?? const SizedBox.shrink();
}

class InternetConnectionController extends BaseController {
  bool? _lastState;
  bool _initialized = false;
  bool _wasEverDisconnected = false;

  @override
  void onReady() {
    super.onReady();

    _handleConnectivity(ConnectivityHelper.instance.isConnected);

    unawaited(
      ConnectivityHelper.instance.refreshStatus().then((_) {
        _handleConnectivity(ConnectivityHelper.instance.isConnected);
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
    if (_lastState == connected) return;

    final previous = _lastState;
    _lastState = connected;

    if (!_initialized) {
      _initialized = true;
      if (!connected) {
        _wasEverDisconnected = true;
        _showOfflineToast();
      }
      return;
    }

    if (!connected) {
      _wasEverDisconnected = true;
      _showOfflineToast();
      return;
    }

    if (_wasEverDisconnected && previous == false) {
      _showOnlineToast();
    }
  }

  void _showOfflineToast() {
    final context = Get.context;
    if (context == null) return;

    final loc = AppLocalizations.of(context)!;
    AppSnackbar.showConnectivity(
      title: loc.status_offline,
      message: loc.internet_connection_lost,
      badge: loc.status_offline,
      isOnline: false,
    );
  }

  void _showOnlineToast() {
    final context = Get.context;
    if (context == null) return;

    final loc = AppLocalizations.of(context)!;
    AppSnackbar.showConnectivity(
      title: loc.status_online,
      message: loc.internet_connection_restored,
      badge: loc.status_online,
      isOnline: true,
    );
  }
}
