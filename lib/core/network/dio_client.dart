import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_navigator.dart';
import '../utils/network_connectivity_service.dart';
import '../utils/preferences_service.dart';
import '../../shared_widgets/dialogs/no_internet_dialog.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;

  factory DioClient() => _instance;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          return status != null && ((status >= 200 && status < 300) || status == 304);
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final uriStr = options.uri.toString();
          final isLoginApi = uriStr.contains('/auth/login') || options.path.contains('/auth/login');
          final token = await PreferencesService().getToken();
          final isAuthenticated = token != null && token.isNotEmpty;

          // Before calling login API, check internet connectivity with tight 4s timeout
          if (isLoginApi) {
            options.connectTimeout = const Duration(seconds: 4);
            options.receiveTimeout = const Duration(seconds: 5);
            options.sendTimeout = const Duration(seconds: 4);

            final isConnected = await NetworkConnectivityService().checkConnection();
            if (!isConnected) {
              final currentContext = AppNavigator.navigatorKey.currentContext;
              if (currentContext != null && currentContext.mounted) {
                NoInternetDialog.show(currentContext);
              }
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  error: const SocketException('No internet connection'),
                  message: 'No internet connection',
                ),
              );
            }
          } else if (isAuthenticated) {
            // For authenticated requests inside the app, check internet connectivity
            final isConnected = await NetworkConnectivityService().checkConnection();
            if (!isConnected) {
              final currentContext = AppNavigator.navigatorKey.currentContext;
              if (currentContext != null && currentContext.mounted) {
                NoInternetDialog.showForceLogout(currentContext);
              }
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  error: const SocketException('No internet connection'),
                  message: 'No internet connection',
                ),
              );
            }
            options.headers['Authorization'] = 'Bearer $token';
          }

          debugPrint('==================== API REQUEST ====================');
          debugPrint('URL: [${options.method}] ${options.uri}');
          debugPrint('Headers: ${options.headers}');
          if (options.data != null) {
            debugPrint('Payload: ${options.data}');
          }
          debugPrint('=====================================================');

          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('==================== API RESPONSE ====================');
          debugPrint('URL: [${response.requestOptions.method}] ${response.requestOptions.uri}');
          debugPrint('Status Code: ${response.statusCode}');
          debugPrint('Response Body: ${response.data}');
          debugPrint('======================================================');

          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          debugPrint('==================== API ERROR ====================');
          debugPrint('URL: [${error.requestOptions.method}] ${error.requestOptions.uri}');
          debugPrint('Status Code: ${error.response?.statusCode}');
          debugPrint('Error Data: ${error.response?.data ?? error.message}');
          debugPrint('===================================================');

          // If 401 Unauthorized, clear invalid session token
          if (error.response?.statusCode == 401) {
            await PreferencesService().clearSession();
          }

          // Check if error is due to network disconnection
          final isNetworkError = error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.error is SocketException;

          final isLoginApi = error.requestOptions.uri.toString().contains('/auth/login') ||
              error.requestOptions.path.contains('/auth/login');

          if (isNetworkError) {
            if (isLoginApi) {
              final currentContext = AppNavigator.navigatorKey.currentContext;
              if (currentContext != null && currentContext.mounted) {
                NoInternetDialog.show(currentContext);
              }
            } else {
              final token = await PreferencesService().getToken();
              final isAuthenticated = token != null && token.isNotEmpty;
              if (isAuthenticated) {
                final isConnected = await NetworkConnectivityService().checkConnection();
                if (!isConnected) {
                  final currentContext = AppNavigator.navigatorKey.currentContext;
                  if (currentContext != null && currentContext.mounted) {
                    NoInternetDialog.showForceLogout(currentContext);
                  }
                }
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }
}
