import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/config/config.dart';
import 'package:dio/dio.dart';

const String baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: baseURL,
);

class NetworkModule {
  // Flag to track if an error message is already shown
  static bool _isErrorBeingHandled = false;

  // Flag to track manual logout to prevent session expired message
  static bool _isManualLogout = false;

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
            // ALWAYS dismiss loader first for 401 errors
            safelyDismissLoader();
            showError(description: response.data['message']);
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
          }

          // Pass other responses through
          handler.next(response);
        },
        onError: (DioException error, handler) async {
          // ALWAYS dismiss loader first for any error
          safelyDismissLoader();

          // Only handle errors if not already being handled
          if (!_isErrorBeingHandled) {
            _isErrorBeingHandled = true;

            if (error.response?.statusCode == 401) {
              // Handle token expiration
              try {
                await _handleTokenExpiration();
              } catch (e) {
                debugPrint(
                  'Error handling token expiration in error handler: $e',
                );
                safelyDismissLoader(); // Ensure loader is dismissed even on error
              }
            } else if (error.response?.statusCode == 502) {
              // Handle server error
              showError(description: 'Server error. Please try again later.');
              try {
                await _handleTokenExpiration();
              } catch (e) {
                debugPrint('Error handling 502 error: $e');
                safelyDismissLoader(); // Ensure loader is dismissed even on error
              }
              return;
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

  // Enhanced _handleTokenExpiration method with session expired dialog
  static Future<void> _handleTokenExpiration() async {
    try {
      debugPrint('Starting token expiration handling...');

      // Ensure loader is dismissed at the start
      safelyDismissLoader();

      final appPref = Get.find<AppPref>();

      // Clear user token first
      appPref.token = '';

      // Clear all database data
      try {
        final db = AppDatabase();
        await db.clearAllData();
      } catch (e) {
        debugPrint('Error clearing database: $e');
      }

      // Clear all SharedPreferences data
      await appPref.clearAllData();

      debugPrint('User data cleared, showing session expired dialog...');

      // Only show session expired dialog if it's not a manual logout
      if (!_isManualLogout) {
        await showSessionExpiredDialog();
      } else {
        // Navigate directly for manual logout
        Get.offAllNamed(AppRoute.main);
      }

      // Reset the manual logout flag
      _isManualLogout = false;

      debugPrint('Token expiration handling completed');
    } catch (e) {
      debugPrint('Error in _handleTokenExpiration: $e');
      // Ensure loader is dismissed even if there's an error
      safelyDismissLoader();

      // Try to navigate to main screen even on error
      try {
        Get.offAllNamed(AppRoute.main);
      } catch (navError) {
        debugPrint('Error navigating to main screen: $navError');
      }
    } finally {
      // Always reset flags and dismiss loader in finally block
      _isErrorBeingHandled = false;
      _isManualLogout = false;
      safelyDismissLoader();
    }
  }

  // Method to show session expired dialog
  static Future<void> showSessionExpiredDialog() async {
    try {
      await Get.dialog(
        WillPopScope(
          onWillPop: () async => false, // Prevent back button dismissal
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Session Expired',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            content: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'You will be redirected to the main screen to login again.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Close dialog and navigate to main screen
                    Get.back();
                    Get.offAllNamed(AppRoute.main);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Login Again',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        barrierDismissible: false, // Prevent dismissing by tapping outside
        barrierColor: Colors.black.withOpacity(0.7),
      );
    } catch (e) {
      debugPrint('Error showing session expired dialog: $e');
      // Fallback: navigate directly if dialog fails
      Get.offAllNamed(AppRoute.main);
    }
  }

  static ApiClient getApiClient() =>
      ApiClient(Get.find<Dio>(), baseUrl: baseUrl);
}
