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

  Future<TasksResponseModel> getAllTasks({
    String scope = 'all',
    int limit = 20,
    int offset = 0,
    String? status,
    String? priority,
    String? search,
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
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    final response = await _dioClient.dio.get(
      ApiConstants.tasks,
      queryParameters: params,
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
