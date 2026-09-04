import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/preferences_service.dart';

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
          // Attach authorization token if available
          final token = await PreferencesService().getToken();
          if (token != null && token.isNotEmpty) {
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

          return handler.next(error);
        },
      ),
    );
  }
}
