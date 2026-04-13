// part of 'api_client.dart';

import 'dart:io';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/app_snackbar.dart';
import 'package:dio/dio.dart';

typedef ApiErrorHandler = Future<bool> Function(DioException error);
typedef Json = Map<String, dynamic>;

Future<T?> callApi<T>(
  Future<T> request, {
  bool showLoader = true,
  double? loaderTopPadding,
  ApiErrorHandler? apiErrorHandler,
  bool rethrowError = false,
}) async {
  try {
    if (showLoader) showAppLoader(loaderTopPadding: loaderTopPadding);
    debugPrint('callApi :: Starting request');

    final response = await request;
    debugPrint('callApi :: Success response: $response');

    if (showLoader) dismissAppLoader();
    return response;
  } on DioException catch (dioError, stack) {
    debugPrint('callApi :: DioException -> ${dioError.type}');
    debugPrint('callApi :: Error Response Data -> ${dioError.response?.data}');
    debugPrint(
      'callApi :: Error Response Status -> ${dioError.response?.statusCode}',
    );
    debugPrint('callApi :: Stack -> $stack');
    if (showLoader) dismissAppLoader();

    if (apiErrorHandler != null) {
      final result = await apiErrorHandler(dioError);
      if (!result) {
        onResponseError(dioError);
      }
    } else {
      onResponseError(dioError);
    }
  } catch (error, stack) {
    debugPrint('callApi :: General Error Type: ${error.runtimeType}');
    debugPrint('callApi :: Is DioException? ${error is DioException}');
    debugPrint('callApi :: Error Details -> $error');
    debugPrint('callApi :: Stack -> $stack');

    if (showLoader) dismissAppLoader();

    if (rethrowError) rethrow;
  }

  return null;
}

void onResponseError(DioException error) {
  debugPrint('onResponseError: Status Code: ${error.response?.statusCode}');
  debugPrint(
    'onResponseError: Response Data: ${error.response?.statusMessage}',
  );

  // Handle network errors
  if (error.type == DioExceptionType.unknown &&
      error.error is SocketException) {
    showError(
      title: 'Connection Error',
      description: 'Please check your internet connection and try again.',
    );
    return;
  }

  // Safely get error data, ensuring it's not null
  final errorData = error.response?.data ?? error.response?.statusMessage;
  final List<String> validationErrors = _processErrorResponse(errorData);

  if (validationErrors.isNotEmpty) {
    // If we have specific validation errors, show them
    showError(description: validationErrors.join('\n'));
    return;
  }

  // If no specific validation errors were found, handle general error cases
  // _handleGeneralErrors(error);
}

List<String> _processErrorResponse(dynamic errorData) {
  List<String> errors = [];

  if (errorData == null) return errors;

  try {
    if (errorData is Map) {
      // Case 1: Nested errors object with field-specific errors
      if (errorData['errors'] is Map) {
        final validationErrors = errorData['errors'] as Map;
        validationErrors.forEach((field, messages) {
          if (messages is List) {
            errors.addAll(messages.map((msg) => '$field: $msg'));
          } else if (messages != null) {
            errors.add('$field: $messages');
          }
        });
      }
      // Add other cases as needed
    } else if (errorData is String) {
      errors.add(errorData);
    }
  } catch (e) {
    debugPrint('Error processing error response: $e');
    // Add the raw error data as a fallback
    if (errorData.toString().isNotEmpty) {
      errors.add(errorData.toString());
    }
  }

  return errors;
}

void _showRawSnackBar({
  String? description,
  String? title,
  Widget? icon,
  bool closeAllSnackbars = false,
  bool? isTop = false,
}) async {
  if (closeAllSnackbars) {
    Get.closeAllSnackbars();
  }

  // Prevent loader/snackbar overlap from leaving a stale loader on screen.
  dismissAllAppLoader();
  await Future<void>.delayed(const Duration(milliseconds: 50));

  AppSnackbar.showRaw(
    backgroundColor: AppColor.primary,
    titleText: title != null
        ? AppText.bold(title, color: AppColor.white)
        : null,
    messageText: description == null
        ? null
        : title == null
        ? AppText.regular(description, color: AppColor.white)
        : AppText.regular(description, size: 12, color: AppColor.white),
    icon:
        icon ?? const Icon(Icons.error_outline_rounded, color: AppColor.white),
    snackPosition: isTop == true ? SnackPosition.TOP : SnackPosition.BOTTOM,
    duration: const Duration(milliseconds: 3000),
  );
}

void showError({
  required String? description,
  String? title,
  Widget? icon,
  bool closeAllSnackbars = false,
  bool isTop = false,
}) {
  _showRawSnackBar(
    description: description,
    title: title,
    icon: icon,
    closeAllSnackbars: closeAllSnackbars,
    isTop: isTop,
  );
}

void showSuccess({
  required String? description,
  String? title,
  Widget? icon,
  bool closeAllSnackbars = false,
  bool isTop = false,
}) {
  _showRawSnackBar(
    description: description,
    title: title,
    icon: icon,
    closeAllSnackbars: closeAllSnackbars,
    isTop: isTop,
  );
}
