import 'dart:async';

import 'package:billkaro/config/config.dart';



class InternetConnectionWidget extends StatelessWidget {
  InternetConnectionWidget({super.key});

  final InternetConnectionController controller =
      Get.put(InternetConnectionController());

  @override
  Widget build(BuildContext context) => Obx(() {
        final isConnected = controller._isConnected.isTrue;
        final isRestored = controller._isConnectionRestored.isTrue;

        if (controller._initialValue) {
          controller._initialValue = false;
          return const SizedBox.shrink();
        }

        if (!isConnected) {
          return const _NoInternetWidget();
        }

        if (isRestored) {
          return const _RestoredInternetWidget();
        }

        return const SizedBox.shrink();
      });
}

class InternetConnectionController extends BaseController {
  var _initialValue = true;
  final _isConnected = true.obs;
  final _isConnectionRestored = false.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();

    _initialValue = ConnectivityHelper.instance.isConnected;
    _isConnected.value = _initialValue;
  }

  @override
  void onReady() {
    super.onReady();

    streams.add(ConnectivityHelper.instance.networkConnectedRx.listen((event) {
      _isConnected.value = event;
      if (event) {
        _isConnectionRestored.value = true;
        _timer?.cancel();
        _timer = Timer(const Duration(milliseconds: 2750), () {
          _isConnectionRestored.value = false;
        });
      }
    }));
  }

  @override
  void onClose() {
    super.onClose();

    _timer?.cancel();
  }
}

class _NoInternetWidget extends StatelessWidget {
  const _NoInternetWidget();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Colors.redAccent,
        padding: const EdgeInsetsDirectional.all(8),
        alignment: AlignmentDirectional.center,
        child: RichText(
          maxLines: 1,
          text: TextSpan(
            text: '',
            style: const Text('', style: TextStyle(color: Colors.white,fontSize: 12),)
                .style,
            children: const [
              WidgetSpan(child: SizedBox(width: 6)),
              TextSpan(text: 'No Internet Connection Available'),
            ],
          ),
        ),
      );
}

class _RestoredInternetWidget extends StatelessWidget {
  const _RestoredInternetWidget();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Colors.blue,
        padding: const EdgeInsetsDirectional.all(8),
        alignment: AlignmentDirectional.center,
        child: RichText(
          maxLines: 1,
          text: TextSpan(
            text: '',
            style: const Text('', style: TextStyle(color: Colors.black,fontSize: 12),)
                .style,
            children: const [
              WidgetSpan(child: SizedBox(width: 6)),
              TextSpan(text: 'Internet Connection Restored'),
            ],
          ),
        ),
      );
}
