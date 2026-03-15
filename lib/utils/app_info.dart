import 'package:package_info_plus/package_info_plus.dart';

class AppInfoUtil {
  static PackageInfo? _packageInfo;

  /// Initialize package info (call this once in main or early in the app)
  static Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  static String get appName => _packageInfo?.appName ?? 'Unknown';
  static String get packageName => _packageInfo?.packageName ?? 'Unknown';
  static String get version => _packageInfo?.version ?? 'Unknown';
  static String get buildNumber => _packageInfo?.buildNumber ?? 'Unknown';

  /// Optional: Get formatted version string
  static String get formattedVersion => 'Version $version';
}
