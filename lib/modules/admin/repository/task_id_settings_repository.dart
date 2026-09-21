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
    } catch (e) {
      debugPrint('[TaskIdSettingsRepository] Error getTaskCounter: $e');
    }
    return _fallbackTaskCounter();
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
    } catch (e) {
      debugPrint('[TaskIdSettingsRepository] Error getTicketSettings: $e');
    }
    return _fallbackTicketSettings();
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
    } catch (e) {
      debugPrint('[TaskIdSettingsRepository] Error getAssignees: $e');
    }
    return _fallbackAssignees();
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

  TaskCounterResponse _fallbackTaskCounter() {
    return const TaskCounterResponse(
      branches: [
        TaskCounterBranch(
          branchId: 1,
          code: 'SS00',
          name: 'Head Office',
          lastNo: 26,
          next: 'SS00-0027/09-26',
        ),
        TaskCounterBranch(
          branchId: 2,
          code: 'SS01',
          name: 'Moti Nagar & Sanath Nagar',
          lastNo: 56,
          next: 'SS01-0057/09-26',
        ),
        TaskCounterBranch(
          branchId: 3,
          code: 'SS02',
          name: 'Peerzadiguda',
          lastNo: 0,
          next: 'SS02-0001/09-26',
        ),
        TaskCounterBranch(
          branchId: 4,
          code: 'SS03',
          name: 'Test Branch',
          lastNo: 2,
          next: 'SS03-0003/09-26',
        ),
      ],
      periodStart: '2026-06-01',
      max: 9999,
    );
  }

  TicketSettingsResponse _fallbackTicketSettings() {
    return const TicketSettingsResponse(
      branches: [
        TicketBranchSetting(
          branchId: 1,
          code: 'SS00',
          name: 'Head Office',
          defaultOwnerId: 11,
          defaultOwnerName: 'Renuka',
          effectiveOwner: 'Renuka',
        ),
        TicketBranchSetting(
          branchId: 2,
          code: 'SS01',
          name: 'Moti Nagar & Sanath Nagar',
          defaultOwnerId: null,
          defaultOwnerName: null,
          effectiveOwner: 'Renuka',
        ),
        TicketBranchSetting(
          branchId: 3,
          code: 'SS02',
          name: 'Peerzadiguda',
          defaultOwnerId: null,
          defaultOwnerName: null,
          effectiveOwner: 'Renuka',
        ),
        TicketBranchSetting(
          branchId: 4,
          code: 'SS03',
          name: 'Test Branch',
          defaultOwnerId: null,
          defaultOwnerName: null,
          effectiveOwner: 'Test_principal',
        ),
      ],
      defaultOwnerId: null,
      defaultOwnerName: null,
      effectiveFallback: 'Renuka',
    );
  }

  List<AssigneeLookupItem> _fallbackAssignees() {
    return const [
      AssigneeLookupItem(
        id: 35,
        name: 'Administrator',
        initials: 'AD',
        avatarColor: '#132a50',
        department: 'Administration',
        isTaskCreator: true,
      ),
      AssigneeLookupItem(
        id: 11,
        name: 'Renuka',
        initials: 'RE',
        avatarColor: '#b91c1c',
        department: 'Administration',
        isTaskCreator: true,
      ),
      AssigneeLookupItem(
        id: 12,
        name: 'Test_principal',
        initials: 'TP',
        avatarColor: '#047857',
        department: 'Academics',
        isTaskCreator: false,
      ),
    ];
  }
}
