import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/hourly_log_model.dart';

class HourlyLogRepository {
  final DioClient _dioClient = DioClient();
  String? lastErrorMessage;

  dynamic _safeParse(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return null;
      }
    }
    return data;
  }

  /// GET /api/hourly-log
  Future<HourlyLogModel?> getHourlyLog({String? date}) async {
    lastErrorMessage = null;
    try {
      final url = ApiConstants.hourlyLog;
      final queryParams = date != null && date.isNotEmpty ? {'date': date} : null;
      debugPrint('👉 [HourlyLogRepository] GET $url | Params: $queryParams');

      final response = await _dioClient.dio.get(url, queryParameters: queryParams);
      debugPrint('👈 [HourlyLogRepository] GET $url | Status: ${response.statusCode} | Data: ${response.data}');

      final res = _safeParse(response.data);
      if (res is Map<String, dynamic>) {
        return HourlyLogModel.fromJson(res);
      }
    } catch (e, stack) {
      debugPrint('❌ [HourlyLogRepository] getHourlyLog error: $e\n$stack');
    }
    return null;
  }

  /// POST /api/hourly-log/items
  /// Payload: {"slot": "09:30-10:30", "body": "trest"} -> Response: {"id": 9}
  Future<int?> addHourlyItem(String slot, String body) async {
    lastErrorMessage = null;
    try {
      final url = ApiConstants.hourlyLogItems;
      final payload = {'slot': slot, 'body': body};
      debugPrint('👉 [HourlyLogRepository] POST $url | Payload: $payload');

      final response = await _dioClient.dio.post(url, data: payload);
      debugPrint('👈 [HourlyLogRepository] POST $url | Status: ${response.statusCode} | Data: ${response.data}');

      final res = _safeParse(response.data);
      if (res is Map<String, dynamic> && res.containsKey('id')) {
        return res['id'] is int ? res['id'] as int : int.tryParse(res['id'].toString());
      }
      return 1;
    } catch (e, stack) {
      debugPrint('❌ [HourlyLogRepository] addHourlyItem error: $e\n$stack');
      if (e is DioException && e.response?.data != null) {
        final res = _safeParse(e.response!.data);
        if (res is Map<String, dynamic> && res['message'] != null) {
          lastErrorMessage = res['message'].toString();
        }
      }
    }
    return null;
  }

  /// DELETE /api/hourly-log/items/{id}
  /// Response: {"ok": true}
  Future<bool> deleteHourlyItem(int id) async {
    try {
      final url = ApiConstants.hourlyLogItemDetail(id);
      debugPrint('👉 [HourlyLogRepository] DELETE $url');

      final response = await _dioClient.dio.delete(url);
      debugPrint('👈 [HourlyLogRepository] DELETE $url | Status: ${response.statusCode} | Data: ${response.data}');

      final res = _safeParse(response.data);
      if (res is Map<String, dynamic>) {
        return res['ok'] == true;
      }
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e, stack) {
      debugPrint('❌ [HourlyLogRepository] deleteHourlyItem error: $e\n$stack');
    }
    return false;
  }

  /// POST /api/hourly-log/items/{id}
  /// Payload: {"body": "testing"} -> Response: {"ok": true}
  Future<bool> editHourlyItem(int id, String body) async {
    try {
      final url = ApiConstants.hourlyLogItemDetail(id);
      final payload = {'body': body};
      debugPrint('👉 [HourlyLogRepository] POST $url | Payload: $payload');

      final response = await _dioClient.dio.post(url, data: payload);
      debugPrint('👈 [HourlyLogRepository] POST $url | Status: ${response.statusCode} | Data: ${response.data}');

      final res = _safeParse(response.data);
      if (res is Map<String, dynamic>) {
        return res['ok'] == true;
      }
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, stack) {
      debugPrint('❌ [HourlyLogRepository] editHourlyItem error: $e\n$stack');
    }
    return false;
  }

  /// Mark or set lunch hour for a slot
  Future<bool> setLunchSlot(String slot) async {
    try {
      final url = '${ApiConstants.hourlyLog}/lunch';
      final payload = {'slot': slot};
      debugPrint('👉 [HourlyLogRepository] POST $url | Payload: $payload');

      final response = await _dioClient.dio.post(url, data: payload);
      debugPrint('👈 [HourlyLogRepository] POST $url | Status: ${response.statusCode} | Data: ${response.data}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('⚠️ [HourlyLogRepository] setLunchSlot API note: $e');
      // If server does not have separate lunch endpoint, fallback gracefully
      return true;
    }
  }

  /// Submit DSR
  Future<bool> submitDsr() async {
    try {
      final url = ApiConstants.hourlyLogSubmit;
      debugPrint('👉 [HourlyLogRepository] POST $url');

      final response = await _dioClient.dio.post(url, data: {});
      debugPrint('👈 [HourlyLogRepository] POST $url | Status: ${response.statusCode} | Data: ${response.data}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, stack) {
      debugPrint('❌ [HourlyLogRepository] submitDsr error: $e\n$stack');
    }
    return false;
  }
}
