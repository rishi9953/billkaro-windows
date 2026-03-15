import 'dart:async';
import 'dart:io';

import 'package:billkaro/utils/connectivity/data_connection_checker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityHelper {
  static final ConnectivityHelper instance = ConnectivityHelper._();

  ConnectivityHelper._() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _stream;
  final _currentState = RxBool(true);

  final _onConnectivityChangeController = StreamController<bool>.broadcast();

  bool get isConnected => _currentState.value;

  RxBool get networkConnectedRx => _currentState;

  Stream<bool> get onConnectivityChange {
    _connectivity.checkConnectivity().then(
      (value) => _checkInternetStatus(value, forceUpdate: true),
    );
    return _onConnectivityChangeController.stream;
  }

  void _init() {
    _connectivity.checkConnectivity().then(
      (value) => _checkInternetStatus(value, forceUpdate: true),
    );
    _stream = _connectivity.onConnectivityChanged.listen(_checkInternetStatus);
  }

  void dispose() {
    _stream?.cancel();
  }

  Future<void> _checkInternetStatus(
    List<ConnectivityResult> result, {
    bool forceUpdate = false,
  }) async {
    if (result.contains(ConnectivityResult.none)) {
      if (_currentState.value || forceUpdate) {
        _currentState.value = false;
        _onConnectivityChangeController.add(_currentState.value);
      }
    } else {
      final state = await DataConnectionChecker().hasConnection;
      if (_currentState.value != state || forceUpdate) {
        _currentState.value = state;
        _onConnectivityChangeController.add(_currentState.value);
      }
    }
  }
}

class NetworkUtils {
  /// Check if device has actual internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      // First check if connected to network (WiFi/Cellular)
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Then verify actual internet access by pinging a reliable server
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));

      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      // No internet connection
      return false;
    } on TimeoutException catch (_) {
      // Timeout means no internet
      return false;
    } catch (e) {
      // Any other error, assume no internet
      return false;
    }
  }

  /// Legacy method for backwards compatibility (if used elsewhere)
  @Deprecated('Use hasInternetConnection() instead')
  static Future<bool> isConnected() async {
    return hasInternetConnection();
  }
}
