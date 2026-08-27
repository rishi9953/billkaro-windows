import 'package:billkaro/app/services/auth/auth_session_service.dart';
import 'package:billkaro/app/services/Network/api_config.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/trusted_http_client.dart';
import 'package:dio/dio.dart';

String get _dioBaseUrl {
  const fromDefine = String.fromEnvironment('BASE_URL');
  if (fromDefine.isNotEmpty) return fromDefine;
  return ApiConfig.baseUrl;
}

class NetworkModule {
  // Flag to track if an error message is already shown
  static bool _isErrorBeingHandled = false;

  /// Login / signup / OTP calls are not an active session — skip forced logout.
  static bool _isPublicAuthRequest(RequestOptions options) {
    final path = '${options.uri.path} ${options.path}'.toLowerCase();
    return path.contains('auth/login') ||
        path.contains('auth/staff/login') ||
        path.contains('auth/register') ||
        path.contains('auth/forgot-password') ||
        path.contains('auth/staff/forgot-password') ||
        path.contains('auth/phone/') ||
        path.contains('auth/staff/phone/') ||
        path.contains('auth/resend-activation') ||
        path.contains('auth/verify-email') ||
        path.contains('auth/check-email') ||
        path.contains('auth/check-mobile');
  }

  static Future<void> _handleUnauthorizedResponse({
    required RequestOptions requestOptions,
    dynamic data,
  }) async {
    final message = AuthSessionService.messageFromBody(data);
    if (_isPublicAuthRequest(requestOptions)) {
      showError(
        description: (message != null && message.trim().isNotEmpty)
            ? message
            : 'Invalid credentials',
      );
      return;
    }
    await AuthSessionService.handleUnauthorized(message: message);
  }

  // Helper method to safely dismiss loaders with error handling
  static void safelyDismissLoader() {
    try {
      dismissAllAppLoader();
      debugPrint('Loader dismissed successfully');
    } catch (e) {
      debugPrint('Error dismissing loader: $e');
    }
  }

  static Dio prepareDio() {
    final dio = Dio();
    configureTrustedDio(dio);
    final appPref = Get.find<AppPref>();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (option, handler) async {
          // Reset the error flag at the start of each request
          _isErrorBeingHandled = false;

          final customHeaders = <String, dynamic>{
            "authorization": "Bearer ${appPref.token}",
            "Content-Type": "application/json",
          };
          option.headers.addAll(customHeaders);

          handler.next(option);
        },
        onResponse: (response, handler) async {
          // Handle different status codes properly
          if (response.statusCode == 200) {
            // Call API on successful response only when URL contains '/books' and user is logged in
            return handler.next(response);
          } else if (response.statusCode == 401) {
            safelyDismissLoader();
            if (!_isErrorBeingHandled) {
              _isErrorBeingHandled = true;
              await _handleUnauthorizedResponse(
                requestOptions: response.requestOptions,
                data: response.data,
              );
            }
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
          } else if (response.statusCode == 502) {
            // Handle bad gateway - logout user
            if (!_isErrorBeingHandled) {
              _isErrorBeingHandled = true;
              safelyDismissLoader();
              debugPrint('Response: ${response.data}');
              showError(
                description: 'Something went wrong. Please try again later.',
              );
              // await _handleTokenExpiration();
            }
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response.data,
                type: DioExceptionType.badResponse,
              ),
            );
          } else if (response.statusCode == 400) {
            if (!_isErrorBeingHandled) {
              _isErrorBeingHandled = true;
              safelyDismissLoader();
              debugPrint('Response: ${response.data}');
              if (response.data['message'] is String) {
                showError(description: response.data['message']);
              } else if (response.data['message'] is List) {
                showError(description: response.data['message'].join(', '));
              }
            }
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
          } else if (response.statusCode == 404) {
            // Handle not found error
            safelyDismissLoader();
            final errorMessage = response.data?['message'];
            showError(description: errorMessage);
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
          } else if (response.statusCode == 409) {
            safelyDismissLoader();
            final errorMessage = response.data?['message'];
            showError(description: errorMessage);
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
          } else if ((response.statusCode ?? 0) >= 500) {
            if (!_isErrorBeingHandled) {
              _isErrorBeingHandled = true;
              safelyDismissLoader();
              final errorMessage = response.data is Map
                  ? response.data['message']
                  : null;
              showError(
                description:
                    (errorMessage is String && errorMessage.trim().isNotEmpty)
                    ? errorMessage
                    : 'Something went wrong. Please try again later.',
              );
            }
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
          }

          // Pass other successful responses through (e.g. 201 Created)
          handler.next(response);
        },
        onError: (DioException error, handler) async {
          // ALWAYS dismiss loader first for any error
          safelyDismissLoader();

          // Only handle errors if not already being handled
          if (!_isErrorBeingHandled) {
            _isErrorBeingHandled = true;

            if (error.response?.statusCode == 401) {
              try {
                await _handleUnauthorizedResponse(
                  requestOptions: error.requestOptions,
                  data: error.response?.data,
                );
              } catch (e) {
                debugPrint(
                  'Error handling token expiration in error handler: $e',
                );
                safelyDismissLoader();
              }
            } else if (error.response?.statusCode == 502) {
              showError(
                description:
                    'Server is temporarily unavailable. Please try again shortly.',
              );
            } else if (error.response?.statusCode == 400) {
              final errorMessage =
                  error.response?.data?['message'] ??
                  error.message ??
                  'Bad request';
              showError(description: errorMessage);
            } else if (error.response?.statusCode == 409) {
              final errorMessage =
                  error.response?.data?['message'] ??
                  error.message ??
                  'Bad request';
              showError(description: errorMessage);
            } else {
              // Reset flag for other errors that we're passing through
              _isErrorBeingHandled = false;
            }
          }

          handler.reject(error);
        },
      ),
    );

    /// print api log in DEBUG mode
    if (AppGlobal.debugLoggerEnable) {
      dio.interceptors.add(
        TalkerDioLogger(
          settings: TalkerDioLoggerSettings(
            printResponseMessage: false,
            printRequestHeaders: true,
            printErrorHeaders: false,
            responseFilter: (response) {
              return true;
            },
          ),
        ),
      );
    }

    // Add base options
    dio.options = BaseOptions(
      validateStatus: (status) {
        // Consider all responses as valid to handle them in interceptors
        return status! < 600;
      },
      receiveTimeout: const Duration(seconds: 30),
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    );

    return dio;
  }

  // Clears session and returns to login without a dialog
  static Future<void> _handleTokenExpiration() async {
    try {
      debugPrint('Starting token expiration handling...');

      safelyDismissLoader();
      await AuthSessionService.clearSessionData();
      Get.offAllNamed(AppRoute.main);

      debugPrint('Token expiration handling completed');
    } catch (e) {
      debugPrint('Error in _handleTokenExpiration: $e');
      safelyDismissLoader();

      try {
        Get.offAllNamed(AppRoute.main);
      } catch (navError) {
        debugPrint('Error navigating to main screen: $navError');
      }
    } finally {
      _isErrorBeingHandled = false;
      safelyDismissLoader();
    }
  }

  static ApiClient getApiClient() =>
      ApiClient(Get.find<Dio>(), baseUrl: _dioBaseUrl);
}
