enum InternetSpeedPhase {
  idle,
  ping,
  download,
  upload,
  completed,
  failed,
}

enum InternetSpeedError { none, offline, failed }

enum InternetSpeedQuality { unknown, poor, fair, good, excellent }

class InternetSpeedProgress {
  const InternetSpeedProgress({
    required this.phase,
    this.pingMs = 0,
    this.downloadMbps = 0,
    this.uploadMbps = 0,
    this.liveMbps = 0,
    this.error = InternetSpeedError.none,
  });

  final InternetSpeedPhase phase;
  final double pingMs;
  final double downloadMbps;
  final double uploadMbps;
  final double liveMbps;
  final InternetSpeedError error;

  InternetSpeedQuality get downloadQuality =>
      InternetSpeedQualityX.fromDownloadMbps(downloadMbps);

  static const idle = InternetSpeedProgress(phase: InternetSpeedPhase.idle);
}

extension InternetSpeedQualityX on InternetSpeedQuality {
  static InternetSpeedQuality fromDownloadMbps(double mbps) {
    if (mbps <= 0) return InternetSpeedQuality.unknown;
    if (mbps < 5) return InternetSpeedQuality.poor;
    if (mbps < 20) return InternetSpeedQuality.fair;
    if (mbps < 50) return InternetSpeedQuality.good;
    return InternetSpeedQuality.excellent;
  }

  static InternetSpeedQuality fromPingMs(double pingMs) {
    if (pingMs <= 0) return InternetSpeedQuality.unknown;
    if (pingMs < 40) return InternetSpeedQuality.excellent;
    if (pingMs < 80) return InternetSpeedQuality.good;
    if (pingMs < 150) return InternetSpeedQuality.fair;
    return InternetSpeedQuality.poor;
  }
}

String formatSpeedMbps(double mbps) {
  if (mbps <= 0) return '—';
  if (mbps < 10) return mbps.toStringAsFixed(1);
  if (mbps < 100) return mbps.toStringAsFixed(1);
  return mbps.round().toString();
}

String formatPingMs(double pingMs) {
  if (pingMs <= 0) return '—';
  return pingMs.round().toString();
}
