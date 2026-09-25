import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/task_id_settings_model.dart';

class TaskIdSettingsRepository {
  final DioClient _dioClient = DioClient();

  Future<TaskCounterResponse> getTaskCounter() async {
    const url = ApiConstants.adminTaskCounter;
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('Payload: null');
    debugPrint('=====================================================');
    try {
      final response = await _dioClient.dio.get(url);
      debugPrint('==================== API RESPONSE ====================');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
      debugPrint('======================================================');

      if (response.data is Map<String, dynamic>) {
        return TaskCounterResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('[TaskIdSettingsRepository] Error getTaskCounter: $e');
      rethrow;
    }
  }

  Future<TicketSettingsResponse> getTicketSettings() async {
    const url = ApiConstants.ticketSettings;
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('Payload: null');
    debugPrint('=====================================================');
    try {
      final response = await _dioClient.dio.get(url);
      debugPrint('==================== API RESPONSE ====================');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
      debugPrint('======================================================');

      if (response.data is Map<String, dynamic>) {
        return TicketSettingsResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Invalid response format');
    } catch (e) {
      debugPrint('[TaskIdSettingsRepository] Error getTicketSettings: $e');
      rethrow;
    }
  }

  Future<List<AssigneeLookupItem>> getAssignees() async {
    const url = ApiConstants.assignees;
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('Payload: null');
    debugPrint('=====================================================');
    try {
      final response = await _dioClient.dio.get(url);
      debugPrint('==================== API RESPONSE ====================');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
      debugPrint('======================================================');

      if (response.data is List) {
        return (response.data as List)
            .map((item) => AssigneeLookupItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[TaskIdSettingsRepository] Error getAssignees: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getNotifications() async {
    const url = ApiConstants.notifications;
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('Payload: null');
    debugPrint('=====================================================');
    try {
      final response = await _dioClient.dio.get(url);
      debugPrint('==================== API RESPONSE ====================');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
      debugPrint('======================================================');

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[TaskIdSettingsRepository] Error getNotifications: $e');
    }
    return {'items': [], 'unread': 0};
  }

  /// POST /api/v1/admin/task-counter/reset with payload {"branchId": branchId}
  Future<TaskCounterResponse?> resetBranchCounter(int branchId) async {
    const url = ApiConstants.adminTaskCounterReset;
    final payload = {'branchId': branchId};

    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [POST] $url');
    debugPrint('Payload: $payload');
    debugPrint('=====================================================');

    try {
      final response = await _dioClient.dio.post(url, data: payload);
      debugPrint('==================== API RESPONSE ====================');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
      debugPrint('======================================================');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return TaskCounterResponse.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[TaskIdSettingsRepository] Primary reset URL failed: $e, trying fallback endpoint');
      try {
        final fallbackUrl = '${ApiConstants.baseUrl}/admin/task-counter/reset';
        final response = await _dioClient.dio.post(fallbackUrl, data: payload);
        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          return TaskCounterResponse.fromJson(response.data as Map<String, dynamic>);
        }
      } catch (err) {
        debugPrint('[TaskIdSettingsRepository] Fallback reset URL error: $err');
      }
    }
    return null;
  }

  /// POST /api/v1/admin/task-counter/reset with payload {}
  Future<TaskCounterResponse?> resetAllCounters() async {
    const url = ApiConstants.adminTaskCounterReset;
    final payload = <String, dynamic>{};

    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [POST] $url');
    debugPrint('Payload: $payload');
    debugPrint('=====================================================');

    try {
      final response = await _dioClient.dio.post(url, data: payload);
      debugPrint('==================== API RESPONSE ====================');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
      debugPrint('======================================================');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return TaskCounterResponse.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[TaskIdSettingsRepository] Primary reset-all URL failed: $e, trying fallback endpoint');
      try {
        final fallbackUrl = '${ApiConstants.baseUrl}/admin/task-counter/reset';
        final response = await _dioClient.dio.post(fallbackUrl, data: payload);
        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          return TaskCounterResponse.fromJson(response.data as Map<String, dynamic>);
        }
      } catch (err) {
        debugPrint('[TaskIdSettingsRepository] Fallback reset-all error: $err');
      }
    }
    return null;
  }

  /// PUT /api/tickets/settings with payload {"branchId": branchId, "defaultOwnerId": ownerId}
  Future<TicketSettingsResponse?> updateBranchTicketOwner({
    required int branchId,
    required int? ownerId,
  }) async {
    const url = ApiConstants.ticketSettings;
    final payload = {
      'branchId': branchId,
      'defaultOwnerId': ownerId,
    };

    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [PUT] $url');
    debugPrint('Payload: $payload');
    debugPrint('=====================================================');

    try {
      final response = await _dioClient.dio.put(url, data: payload);
      debugPrint('==================== API RESPONSE ====================');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
      debugPrint('======================================================');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return TicketSettingsResponse.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[TaskIdSettingsRepository] Error updateBranchTicketOwner: $e');
    }
    return null;
  }

  /// PUT /api/tickets/settings with payload {"defaultOwnerId": ownerId}
  Future<TicketSettingsResponse?> updateFallbackTicketOwner(int? ownerId) async {
    const url = ApiConstants.ticketSettings;
    final payload = {
      'defaultOwnerId': ownerId,
    };

    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [PUT] $url');
    debugPrint('Payload: $payload');
    debugPrint('=====================================================');

    try {
      final response = await _dioClient.dio.put(url, data: payload);
      debugPrint('==================== API RESPONSE ====================');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
      debugPrint('======================================================');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return TicketSettingsResponse.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[TaskIdSettingsRepository] Error updateFallbackTicketOwner: $e');
    }
    return null;
  }
}
