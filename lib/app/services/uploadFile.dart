import 'dart:io';
import 'package:billkaro/app/services/Network/urls.dart' as appconstants;
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

class MediaApi {
  final Dio _dio = Dio();
  static const int _maxUploadBytes = 4 * 1024 * 1024; // 4 MB

  Future<File> _shrinkIfNeeded(File input) async {
    final int len = await input.length();
    if (len <= _maxUploadBytes) return input;

    try {
      final bytes = await input.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return input;

      const int maxDim = 1600;
      final resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxDim : null,
        height: decoded.height > decoded.width ? maxDim : null,
        interpolation: img.Interpolation.average,
      );

      final jpg = img.encodeJpg(resized, quality: 82);
      final out = File(
        p.join(
          Directory.systemTemp.path,
          'billkaro_upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      await out.writeAsBytes(jpg, flush: true);

      if (await out.length() > _maxUploadBytes) return input;
      return out;
    } catch (_) {
      return input;
    }
  }

  /// Upload a file to the server.
  ///
  /// The file is expected to be in the form of a File object.
  /// The folderName is the name of the folder to upload the file to.
  /// The userId is the id of the user who is uploading the file.
  ///
  /// Returns a Future which resolves to a Response object. If there is
  /// an error while uploading the file, the Future will resolve to null.
  ///
  /// *****  119e1311-8d86-449c-8c21-728a90320f7e  ******
  Future<Response?> uploadImage({
    required File file,
    required String folderName,
    required String userId,
    required String outletId,
  }) async {
    try {
      String url =
          "${appconstants.baseURL}${appconstants.mediaUrl}?folderName=$folderName&userId=$userId&outletId=$outletId";

      print(url);

      final uploadFile = await _shrinkIfNeeded(file);

      // Use a platform-safe basename (Windows uses backslashes).
      final fileName = p.basename(uploadFile.path);

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(uploadFile.path, filename: fileName),
      });

      Response response = await _dio.post(
        url,
        data: formData,
        options: Options(headers: {"Content-Type": "multipart/form-data"}),
      );

      return response;
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }
}
