import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../dashboard/models/branch_model.dart';
import '../models/lookup_models.dart';
import '../models/recurring_task_model.dart';
import '../models/task_model.dart';

class RecurringLookupsData {
  final List<BranchModel> branches;
  final List<LookupAssigneeModel> assignees;
  final LookupEnumsModel enums;

  RecurringLookupsData({
    required this.branches,
    required this.assignees,
    required this.enums,
  });
}

class TaskDetailWithAssignees {
  final TaskDetailModel detail;
  final List<LookupAssigneeModel> assigneesLookup;

  TaskDetailWithAssignees({
    required this.detail,
    required this.assigneesLookup,
  });
}

class AllTasksRepository {
  final DioClient _dioClient = DioClient();

  void _logServiceCall({
    required String serviceMethod,
    required String url,
    dynamic payload,
    dynamic response,
  }) {
    debugPrint('---------------- [AllTasksService: $serviceMethod] ----------------');
    debugPrint('Service URL: $url');
    if (payload != null) {
      debugPrint('Service Payload / QueryParams: $payload');
    }
    if (response != null) {
      debugPrint('Service Response: $response');
    }
    debugPrint('-------------------------------------------------------------------');
  }

  Future<TasksResponseModel> getAllTasks({
    String scope = 'all',
    int limit = 20,
    int offset = 0,
    String? status,
    String? priority,
    String? owner,
    String? dueFrom,
    String? dueTo,
    int? progressMin,
    int? progressMax,
    String? category,
    String? search,
    int? branchId,
  }) async {
    final Map<String, dynamic> params = {
      'scope': scope,
      'limit': limit,
      'offset': offset,
    };
    if (status != null && status.isNotEmpty && status != 'all') {
      params['status'] = status;
    }
    if (priority != null && priority.isNotEmpty && priority != 'all') {
      params['priority'] = priority;
    }
    if (owner != null && owner.isNotEmpty && owner != 'all') {
      params['owner'] = owner;
    }
    if (dueFrom != null && dueFrom.isNotEmpty) {
      params['dueFrom'] = dueFrom;
    }
    if (dueTo != null && dueTo.isNotEmpty) {
      params['dueTo'] = dueTo;
    }
    if (progressMin != null) {
      params['progressMin'] = progressMin;
    }
    if (progressMax != null) {
      params['progressMax'] = progressMax;
    }
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      params['category'] = category.toLowerCase();
    }
    if (search != null && search.isNotEmpty) {
      params['q'] = search;
    }
    if (branchId != null && branchId > 0) {
      params['branchId'] = branchId;
    }

    _logServiceCall(
      serviceMethod: 'getAllTasks',
      url: ApiConstants.tasks,
      payload: params,
    );

    final response = await _dioClient.dio.get(
      ApiConstants.tasks,
      queryParameters: params,
    );

    _logServiceCall(
      serviceMethod: 'getAllTasks',
      url: ApiConstants.tasks,
      payload: params,
      response: response.data,
    );

    return TasksResponseModel.fromJson(response.data);
  }

  Future<TaskDetailWithAssignees> getTaskDetail(int id) async {
    final results = await Future.wait([
      _dioClient.dio.get('${ApiConstants.tasks}/$id'),
      _dioClient.dio.get(ApiConstants.assignees),
    ]);

    final detail = TaskDetailModel.fromJson(results[0].data);
    List<LookupAssigneeModel> assignees = [];
    if (results[1].data is List) {
      assignees = (results[1].data as List).map((e) => LookupAssigneeModel.fromJson(e)).toList();
    }

    return TaskDetailWithAssignees(
      detail: detail,
      assigneesLookup: assignees,
    );
  }

  Future<RecurringLookupsData> getRecurringLookups() async {
    final results = await Future.wait([
      _dioClient.dio.get(ApiConstants.branches),
      _dioClient.dio.get(ApiConstants.assignees),
      _dioClient.dio.get(ApiConstants.enums),
      _dioClient.dio.get(ApiConstants.notifications),
    ]);

    List<BranchModel> branches = [];
    if (results[0].data is List) {
      branches = (results[0].data as List).map((e) => BranchModel.fromJson(e)).toList();
    }

    List<LookupAssigneeModel> assignees = [];
    if (results[1].data is List) {
      assignees = (results[1].data as List).map((e) => LookupAssigneeModel.fromJson(e)).toList();
    }

    final enums = LookupEnumsModel.fromJson(results[2].data);

    return RecurringLookupsData(
      branches: branches,
      assignees: assignees,
      enums: enums,
    );
  }

  Future<List<RecurringTaskModel>> getRecurringTasks({String? frequency}) async {
    final Map<String, dynamic> params = {};
    if (frequency != null && frequency.isNotEmpty && frequency != 'all') {
      params['frequency'] = frequency;
    }

    final response = await _dioClient.dio.get(
      ApiConstants.recurring,
      queryParameters: params,
    );

    if (response.data is List) {
      return (response.data as List).map((e) => RecurringTaskModel.fromJson(e)).toList();
    }
    return [];
  }
}
