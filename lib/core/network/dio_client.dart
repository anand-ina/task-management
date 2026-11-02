import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_toast.dart';
import '../utils/network_connectivity_service.dart';
import '../utils/preferences_service.dart';

class FriendlyDioException extends DioException {
  FriendlyDioException({
    required super.requestOptions,
    super.response,
    super.type = DioExceptionType.connectionError,
    super.error,
    String super.message = 'Internet not available',
  });

  @override
  String toString() => 'Internet not available';
}

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
              AppToast.showInternetToast(message: 'Internet not available');
              return handler.reject(
                FriendlyDioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  error: const SocketException('Internet not available'),
                  message: 'Internet not available',
                ),
              );
            }
          } else if (isAuthenticated) {
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
              error.error is SocketException ||
              error.message?.toLowerCase().contains('connection') == true;

          final isLoginApi = error.requestOptions.uri.toString().contains('/auth/login') ||
              error.requestOptions.path.contains('/auth/login');

          if (isNetworkError) {
            AppToast.showInternetToast(message: 'Internet not available');
            final friendlyError = FriendlyDioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: const SocketException('Internet not available'),
              message: 'Internet not available',
            );
            return handler.next(friendlyError);
          }

          return handler.next(error);
        },
      ),
    );
  }
}
