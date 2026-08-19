import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/dashboard_stats.dart';
import '../models/team_performance.dart';
import '../models/notification_model.dart';
import '../models/branch_model.dart';
import '../models/todo_model.dart';

class DashboardRepository {
  final DioClient _dioClient = DioClient();

  Future<NotificationsResponse> getNotifications() async {
    final response = await _dioClient.dio.get(ApiConstants.notifications);
    return NotificationsResponse.fromJson(response.data);
  }

  Future<DashboardData> getDashboardData() async {
    final response = await _dioClient.dio.get(ApiConstants.dashboard);
    return DashboardData.fromJson(response.data);
  }

  Future<TeamData> getTeamData() async {
    final response = await _dioClient.dio.get(ApiConstants.dashboardTeam);
    return TeamData.fromJson(response.data);
  }

  Future<List<TodoItem>> getTodos() async {
    final response = await _dioClient.dio.get(ApiConstants.todos);
    if (response.data is List) {
      return (response.data as List).map((e) => TodoItem.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<BranchModel>> getBranches() async {
    final response = await _dioClient.dio.get(ApiConstants.branches);
    if (response.data is List) {
      return (response.data as List).map((e) => BranchModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<dynamic>> getScheduleMy() async {
    final response = await _dioClient.dio.get(ApiConstants.scheduleMy);
    if (response.data is List) {
      return response.data as List;
    }
    return [];
  }
}
