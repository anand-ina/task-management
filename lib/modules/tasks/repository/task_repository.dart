import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../dashboard/models/branch_model.dart';
import '../models/task_model.dart';

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
    String sort = 'entry',
    String dir = 'desc',
    int limit = 50,
    int offset = 0,
  }) async {
    final Map<String, dynamic> params = {
      'scope': scope,
      'sort': sort,
      'dir': dir,
      'limit': limit,
      'offset': offset,
    };

    if (period != null && period.isNotEmpty && period != 'year') {
      params['period'] = period;
    }
    if (priority != null && priority.isNotEmpty) params['priority'] = priority;
    if (overdue == true) params['overdue'] = 'true';
    if (overdueAge != null && overdueAge.isNotEmpty) params['overdueAge'] = overdueAge;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (search != null && search.isNotEmpty) params['q'] = search;

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
    final response = await _dioClient.dio.get('${ApiConstants.tasks}/$taskId');
    return TaskDetailModel.fromJson(response.data);
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
}
