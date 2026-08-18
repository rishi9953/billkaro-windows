import 'package:billkaro/app/services/internet_speed/internet_speed_models.dart';
import 'package:billkaro/app/services/internet_speed/internet_speed_test_service.dart';
import 'package:billkaro/config/config.dart';

class InternetSpeedController extends BaseController {
  InternetSpeedController({InternetSpeedTestService? service})
    : _service = service ?? InternetSpeedTestService();

  final InternetSpeedTestService _service;

  final Rx<InternetSpeedPhase> phase = InternetSpeedPhase.idle.obs;
  final RxDouble pingMs = 0.0.obs;
  final RxDouble downloadMbps = 0.0.obs;
  final RxDouble uploadMbps = 0.0.obs;
  final RxDouble liveMbps = 0.0.obs;
  final Rx<InternetSpeedError> error = InternetSpeedError.none.obs;

  bool get isRunning =>
      phase.value == InternetSpeedPhase.ping ||
      phase.value == InternetSpeedPhase.download ||
      phase.value == InternetSpeedPhase.upload;

  bool get hasResult =>
      phase.value == InternetSpeedPhase.completed && downloadMbps.value > 0;

  InternetSpeedQuality get quality =>
      InternetSpeedQualityX.fromDownloadMbps(downloadMbps.value);

  static InternetSpeedController ensure() {
    if (!Get.isRegistered<InternetSpeedController>()) {
      Get.put(InternetSpeedController(), permanent: true);
    }
    return Get.find<InternetSpeedController>();
  }

  Future<void> startTest() async {
    if (isRunning) return;

    if (!ConnectivityHelper.instance.isConnected) {
      phase.value = InternetSpeedPhase.failed;
      error.value = InternetSpeedError.offline;
      return;
    }

    pingMs.value = 0;
    downloadMbps.value = 0;
    uploadMbps.value = 0;
    liveMbps.value = 0;
    error.value = InternetSpeedError.none;
    phase.value = InternetSpeedPhase.ping;

    await _service.run(onProgress: _applyProgress);
  }

  void cancelTest() => _service.cancel();

  void _applyProgress(InternetSpeedProgress progress) {
    phase.value = progress.phase;
    pingMs.value = progress.pingMs;
    downloadMbps.value = progress.downloadMbps;
    uploadMbps.value = progress.uploadMbps;
    liveMbps.value = progress.liveMbps;
    error.value = progress.error;
  }

  @override
  void onClose() {
    _service.cancel();
    super.onClose();
  }
}
