import 'dart:math';
import 'dart:typed_data';

import 'package:billkaro/app/services/internet_speed/internet_speed_models.dart';
import 'package:dio/dio.dart';

typedef InternetSpeedProgressCallback =
    void Function(InternetSpeedProgress progress);

/// Measures ping, download and upload against Cloudflare's public speed endpoints.
///
/// Uses a dedicated [Dio] client (no API interceptors) so auth headers and
/// logging do not skew the measurement.
class InternetSpeedTestService {
  InternetSpeedTestService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              sendTimeout: const Duration(seconds: 45),
              receiveTimeout: const Duration(seconds: 45),
              followRedirects: true,
              validateStatus: (status) => status != null && status < 500,
            ),
          );

  static const _downloadUrl = 'https://speed.cloudflare.com/__down';
  static const _uploadUrl = 'https://speed.cloudflare.com/__up';
  static const _pingUrl = 'https://speed.cloudflare.com/__down?bytes=1000';

  static const _warmupBytes = 200 * 1024;
  static const _downloadBytes = 8 * 1024 * 1024;
  static const _uploadBytes = 2 * 1024 * 1024;
  static const _pingSamples = 4;
  static const _uiThrottle = Duration(milliseconds: 80);

  final Dio _dio;
  CancelToken? _cancelToken;
  DateTime? _lastEmitAt;

  bool get isRunning => _cancelToken != null && !_cancelToken!.isCancelled;

  void cancel() {
    _cancelToken?.cancel('cancelled');
    _cancelToken = null;
  }

  Future<void> run({required InternetSpeedProgressCallback onProgress}) async {
    cancel();
    final token = CancelToken();
    _cancelToken = token;
    _lastEmitAt = null;

    var pingMs = 0.0;
    var downloadMbps = 0.0;
    var uploadMbps = 0.0;

    void emit({
      required InternetSpeedPhase phase,
      double liveMbps = 0,
      InternetSpeedError error = InternetSpeedError.none,
      bool force = false,
    }) {
      if (!force && !_shouldEmit()) return;
      onProgress(
        InternetSpeedProgress(
          phase: phase,
          pingMs: pingMs,
          downloadMbps: downloadMbps,
          uploadMbps: uploadMbps,
          liveMbps: liveMbps,
          error: error,
        ),
      );
    }

    try {
      emit(phase: InternetSpeedPhase.ping, force: true);
      pingMs = await _measurePing(token);
      emit(phase: InternetSpeedPhase.ping, force: true);

      emit(phase: InternetSpeedPhase.download, force: true);
      await _warmupDownload(token);
      downloadMbps = await _measureDownload(token, (live) {
        emit(phase: InternetSpeedPhase.download, liveMbps: live);
      });
      emit(
        phase: InternetSpeedPhase.download,
        liveMbps: downloadMbps,
        force: true,
      );

      emit(phase: InternetSpeedPhase.upload, force: true);
      uploadMbps = await _measureUpload(token, (live) {
        emit(phase: InternetSpeedPhase.upload, liveMbps: live);
      });

      emit(
        phase: InternetSpeedPhase.completed,
        liveMbps: downloadMbps,
        force: true,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      emit(
        phase: InternetSpeedPhase.failed,
        error: InternetSpeedError.failed,
        force: true,
      );
    } catch (_) {
      if (token.isCancelled) return;
      emit(
        phase: InternetSpeedPhase.failed,
        error: InternetSpeedError.failed,
        force: true,
      );
    } finally {
      if (identical(_cancelToken, token)) {
        _cancelToken = null;
      }
    }
  }

  bool _shouldEmit() {
    final now = DateTime.now();
    final last = _lastEmitAt;
    if (last != null && now.difference(last) < _uiThrottle) return false;
    _lastEmitAt = now;
    return true;
  }

  Future<double> _measurePing(CancelToken token) async {
    final samples = <double>[];
    for (var i = 0; i < _pingSamples; i++) {
      _throwIfCancelled(token);
      final sw = Stopwatch()..start();
      await _dio.get<List<int>>(
        _pingUrl,
        options: Options(responseType: ResponseType.bytes),
        cancelToken: token,
      );
      sw.stop();
      samples.add(sw.elapsedMilliseconds.toDouble());
    }
    if (samples.length > 1) {
      samples.removeAt(0);
    }
    samples.sort();
    return samples[samples.length ~/ 2];
  }

  Future<void> _warmupDownload(CancelToken token) async {
    try {
      await _dio.get<List<int>>(
        '$_downloadUrl?bytes=$_warmupBytes',
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 15),
        ),
        cancelToken: token,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
    }
  }

  Future<double> _measureDownload(
    CancelToken token,
    void Function(double liveMbps) onLive,
  ) async {
    final sw = Stopwatch()..start();
    var lastBytes = 0;
    await _dio.get<List<int>>(
      '$_downloadUrl?bytes=$_downloadBytes',
      options: Options(responseType: ResponseType.bytes),
      cancelToken: token,
      onReceiveProgress: (received, _) {
        lastBytes = received;
        onLive(_toMbps(received, sw.elapsed));
      },
    );
    sw.stop();
    return _toMbps(lastBytes, sw.elapsed);
  }

  Future<double> _measureUpload(
    CancelToken token,
    void Function(double liveMbps) onLive,
  ) async {
    final payload = Uint8List(_uploadBytes);
    final random = Random();
    for (var i = 0; i < payload.length; i += 4096) {
      payload[i] = random.nextInt(256);
    }

    final sw = Stopwatch()..start();
    var lastBytes = 0;
    await _dio.post<void>(
      _uploadUrl,
      data: payload,
      options: Options(
        headers: {Headers.contentTypeHeader: 'application/octet-stream'},
      ),
      cancelToken: token,
      onSendProgress: (sent, _) {
        lastBytes = sent;
        onLive(_toMbps(sent, sw.elapsed));
      },
    );
    sw.stop();
    return _toMbps(lastBytes, sw.elapsed);
  }

  double _toMbps(int bytes, Duration elapsed) {
    final seconds = elapsed.inMicroseconds / 1e6;
    if (seconds <= 0 || bytes <= 0) return 0;
    return (bytes * 8) / seconds / 1e6;
  }

  void _throwIfCancelled(CancelToken token) {
    if (token.isCancelled) {
      throw DioException(
        requestOptions: RequestOptions(path: _pingUrl),
        type: DioExceptionType.cancel,
      );
    }
  }
}
