import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../dashboard/models/branch_model.dart';
import '../models/clone_task_models.dart' hide BranchModel;
import '../models/subtask_models.dart';
import '../models/task_model.dart';
import '../models/task_draft_model.dart';

class TaskRepository {
  final DioClient _dioClient = DioClient();

  Future<List<BranchModel>> getBranches() async {
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [GET] ${ApiConstants.branches}');
    debugPrint('=====================================================');
    final response = await _dioClient.dio.get(ApiConstants.branches);
    debugPrint('==================== API RESPONSE ====================');
    debugPrint('URL: [GET] ${ApiConstants.branches}');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Data: ${response.data}');
    debugPrint('======================================================');
    if (response.data is List) {
      return (response.data as List).map((e) => BranchModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<TasksResponseModel> getTasks({
    String scope = 'mine',
    String? period,
    String? priority,
    bool? overdue,
    String? overdueAge,
    String? status,
    String? search,
    bool? activeOnly,
    int? assigneeId,
    String sort = 'entry',
    String dir = 'desc',
    int limit = 50,
    int offset = 0,
  }) async {
    final Map<String, dynamic> params = {
      'scope': scope,
    };

    if (assigneeId != null) params['assigneeId'] = assigneeId;
    if (period != null && period.isNotEmpty && period != 'year') {
      params['period'] = period;
    }
    if (priority != null && priority.isNotEmpty) params['priority'] = priority;
    if (activeOnly == true) params['activeOnly'] = 'true';
    if (overdue == true) params['overdue'] = 'true';
    if (overdueAge != null && overdueAge.isNotEmpty) params['overdueAge'] = overdueAge;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (search != null && search.isNotEmpty) params['q'] = search;

    params['sort'] = sort;
    params['dir'] = dir;
    params['limit'] = limit;
    params['offset'] = offset;

    final uri = Uri.parse(ApiConstants.tasks).replace(
      queryParameters: params.map((k, v) => MapEntry(k, v.toString())),
    );

    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [GET] $uri');
    debugPrint('Query Parameters / Payload: $params');
    debugPrint('=====================================================');

    final response = await _dioClient.dio.get(
      ApiConstants.tasks,
      queryParameters: params,
    );

    debugPrint('==================== API RESPONSE ====================');
    debugPrint('URL: [GET] $uri');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Data: ${response.data}');
    debugPrint('======================================================');

    return TasksResponseModel.fromJson(response.data);
  }

  Future<TaskDetailModel> getTaskDetail(int taskId) async {
    final url = '${ApiConstants.tasks}/$taskId';
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('=====================================================');
    final response = await _dioClient.dio.get(url);
    debugPrint('==================== API RESPONSE ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Data: ${response.data}');
    debugPrint('======================================================');
    return TaskDetailModel.fromJson(response.data);
  }

  Future<List<AssigneeModel>> getAssigneesLookup() async {
    const url = ApiConstants.assignees;
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('=====================================================');
    final response = await _dioClient.dio.get(url);
    debugPrint('==================== API RESPONSE ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Data: ${response.data}');
    debugPrint('======================================================');
    if (response.data is List) {
      return (response.data as List)
          .map((e) => AssigneeModel.fromJson(e is Map ? Map<String, dynamic>.from(e) : {}))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getEnumsLookup() async {
    const url = ApiConstants.enums;
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('=====================================================');
    final response = await _dioClient.dio.get(url);
    debugPrint('==================== API RESPONSE ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Data: ${response.data}');
    debugPrint('======================================================');
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  Future<List<dynamic>> getDraftsLookup({String kind = 'task'}) async {
    final url = '${ApiConstants.drafts}?kind=$kind';
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('=====================================================');
    final response = await _dioClient.dio.get(
      ApiConstants.drafts,
      queryParameters: {'kind': kind},
    );
    debugPrint('==================== API RESPONSE ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Data: ${response.data}');
    debugPrint('======================================================');
    if (response.data is List) {
      return response.data as List;
    }
    return [];
  }

  Future<String> getNextSubtaskId(int parentId) async {
    final url = '${ApiConstants.tasksNextId}?parentId=$parentId';
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('=====================================================');
    final response = await _dioClient.dio.get(
      ApiConstants.tasksNextId,
      queryParameters: {'parentId': parentId},
    );
    debugPrint('==================== API RESPONSE ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Data: ${response.data}');
    debugPrint('======================================================');
    if (response.data is Map && response.data['taskNo'] != null) {
      return response.data['taskNo'].toString();
    }
    return '';
  }

  Future<SubtaskCreateResult> createSubTask(Map<String, dynamic> payload) async {
    const url = ApiConstants.tasks;
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [POST] $url');
    debugPrint('Payload: $payload');
    debugPrint('=====================================================');
    try {
      final response = await _dioClient.dio.post(url, data: payload);
      debugPrint('==================== API RESPONSE ====================');
      debugPrint('URL: [POST] $url');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
      debugPrint('======================================================');
      final isOk = response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
      return SubtaskCreateResult(
        isSuccess: isOk,
        statusCode: response.statusCode,
        data: response.data,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String? errorMessage;
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message']?.toString();
      }
      errorMessage ??= e.message ?? 'An error occurred';

      debugPrint('==================== API ERROR ====================');
      debugPrint('URL: [POST] $url');
      debugPrint('Status Code: $statusCode');
      debugPrint('Error Response: ${e.response?.data}');
      debugPrint('Error Message: $errorMessage');
      debugPrint('===================================================');

      return SubtaskCreateResult(
        isSuccess: false,
        statusCode: statusCode,
        message: errorMessage,
        data: e.response?.data,
      );
    } catch (e) {
      debugPrint('==================== API ERROR ====================');
      debugPrint('URL: [POST] $url');
      debugPrint('Error: $e');
      debugPrint('===================================================');
      return SubtaskCreateResult(
        isSuccess: false,
        message: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> updateTaskDetail(int taskId, Map<String, dynamic> payload) async {
    final url = '${ApiConstants.tasks}/$taskId';
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [PATCH] $url');
    debugPrint('Payload: $payload');
    debugPrint('=====================================================');
    final response = await _dioClient.dio.patch(url, data: payload);
    debugPrint('==================== API RESPONSE ====================');
    debugPrint('URL: [PATCH] $url');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Data: ${response.data}');
    debugPrint('======================================================');
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  Future<TaskDetailModel> reviewTask({
    required int taskId,
    required String decision,
    required int pointsDelta,
    required String note,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.taskReview(taskId),
      data: {
        'decision': decision,
        'pointsDelta': pointsDelta,
        'note': note,
      },
    );
    return TaskDetailModel.fromJson(response.data);
  }

  Future<Map<String, dynamic>> updateTaskStatus({
    required int taskId,
    required String status,
    required String priority,
    required int progress,
    String blockReason = '',
    required String comment,
    List<int> mentionIds = const [],
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    final url = '${ApiConstants.tasks}/$taskId';
    final payload = {
      'status': status,
      'priority': priority,
      'progress': progress,
      'blockReason': blockReason,
      'comment': comment,
      'mentionIds': mentionIds,
      'attachments': attachments,
    };

    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [PATCH] $url');
    debugPrint('Payload: $payload');
    debugPrint('=====================================================');

    final response = await _dioClient.dio.patch(
      url,
      data: payload,
    );

    debugPrint('==================== API RESPONSE ====================');
    debugPrint('URL: [PATCH] $url');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Data: ${response.data}');
    debugPrint('======================================================');

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> payload) async {
    const url = ApiConstants.tasks;
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [POST] $url');
    debugPrint('Payload: $payload');
    debugPrint('=====================================================');

    final response = await _dioClient.dio.post(
      url,
      data: payload,
    );

    debugPrint('==================== API RESPONSE ====================');
    debugPrint('URL: [POST] $url');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Data: ${response.data}');
    debugPrint('======================================================');

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  Future<int?> saveTaskDraft(Map<String, dynamic> draftData) async {
    const url = ApiConstants.drafts;
    final payload = {
      if (draftData['id'] != null) 'id': draftData['id'],
      'kind': 'task',
      'label': draftData['label'] ?? draftData['title'] ?? 'Untitled Draft',
      'payload': draftData['payload'] ?? draftData,
    };

    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [POST] $url');
    debugPrint('Payload: $payload');
    debugPrint('=====================================================');

    final response = await _dioClient.dio.post(
      url,
      data: payload,
    );

    debugPrint('==================== API RESPONSE ====================');
    debugPrint('URL: [POST] $url');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Data: ${response.data}');
    debugPrint('======================================================');

    if (response.data is Map && response.data['id'] != null) {
      return response.data['id'] is int
          ? response.data['id'] as int
          : int.tryParse(response.data['id'].toString());
    }
    return null;
  }

  Future<List<TaskDraftModel>> getTaskDrafts() async {
    final url = '${ApiConstants.drafts}?kind=task';
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('=====================================================');

    final response = await _dioClient.dio.get(
      ApiConstants.drafts,
      queryParameters: {'kind': 'task'},
    );

    debugPrint('==================== API RESPONSE ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Data: ${response.data}');
    debugPrint('======================================================');

    dynamic rawData = response.data;
    if (rawData is String) {
      try {
        rawData = jsonDecode(rawData);
      } catch (_) {}
    }

    List<dynamic> list = [];
    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map && rawData['data'] is List) {
      list = rawData['data'] as List;
    } else if (rawData is Map && rawData['drafts'] is List) {
      list = rawData['drafts'] as List;
    }

    final List<TaskDraftModel> results = [];
    for (final item in list) {
      try {
        if (item is Map) {
          results.add(TaskDraftModel.fromJson(Map<String, dynamic>.from(item)));
        }
      } catch (e) {
        debugPrint('[TaskRepository] Error parsing individual draft: $e');
      }
    }
    return results;
  }

  Future<bool> deleteTaskDraft(int draftId) async {
    final url = ApiConstants.draftDetail(draftId);
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [DELETE] $url');
    debugPrint('=====================================================');

    final response = await _dioClient.dio.delete(url);

    debugPrint('==================== API RESPONSE ====================');
    debugPrint('URL: [DELETE] $url');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response Data: ${response.data}');
    debugPrint('======================================================');

    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<String?> getNextTaskId({int? branchId}) async {
    final Map<String, dynamic> queryParams = {};
    if (branchId != null) {
      queryParams['branchId'] = branchId;
    }
    final uri = Uri.parse(ApiConstants.tasksNextId).replace(
      queryParameters: queryParams.isEmpty ? null : queryParams.map((k, v) => MapEntry(k, v.toString())),
    );

    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [GET] $uri');
    debugPrint('Query Parameters / Payload: $queryParams');
    debugPrint('=====================================================');

    try {
      final response = await _dioClient.dio.get(
        ApiConstants.tasksNextId,
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      debugPrint('==================== API RESPONSE ====================');
      debugPrint('URL: [GET] $uri');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
      debugPrint('======================================================');

      if (response.data is Map && response.data['taskNo'] != null) {
        return response.data['taskNo'].toString();
      }
    } catch (e) {
      debugPrint('[TaskRepository] getNextTaskId error: $e');
    }
    return null;
  }
}

