import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../dashboard/models/branch_model.dart';
import '../models/task_model.dart';

class TaskRepository {
  final DioClient _dioClient = DioClient();

  Future<List<BranchModel>> getBranches() async {
    final response = await _dioClient.dio.get(ApiConstants.branches);
    if (response.data is List) {
      return (response.data as List).map((e) => BranchModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<TasksResponseModel> getTasks({
    String scope = 'all',
    String? period,
    String? priority,
    bool? overdue,
    String? overdueAge,
    String? status,
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

    if (period != null && period.isNotEmpty) params['period'] = period;
    if (priority != null && priority.isNotEmpty) params['priority'] = priority;
    if (overdue == true) params['overdue'] = 'true';
    if (overdueAge != null && overdueAge.isNotEmpty) params['overdueAge'] = overdueAge;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final response = await _dioClient.dio.get(
      ApiConstants.tasks,
      queryParameters: params,
    );
    return TasksResponseModel.fromJson(response.data);
  }

  Future<TaskDetailModel> getTaskDetail(int taskId) async {
    final response = await _dioClient.dio.get('${ApiConstants.tasks}/$taskId');
    return TaskDetailModel.fromJson(response.data);
  }
}
