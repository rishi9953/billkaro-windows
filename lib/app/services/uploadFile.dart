import 'dart:io';
import 'package:billkaro/app/services/Network/urls.dart' as appconstants;
import 'package:dio/dio.dart';

class MediaApi {
  final Dio _dio = Dio();

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

      String fileName = file.path.split('/').last;

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
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
