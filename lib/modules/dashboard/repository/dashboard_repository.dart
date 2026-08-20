import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/dashboard_stats.dart';
import '../models/team_performance.dart';
import '../models/notification_model.dart';
import '../models/branch_model.dart';
import '../models/todo_model.dart';

class DashboardRepository {
  final DioClient _dioClient = DioClient();

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

  Future<NotificationsResponse> getNotifications() async {
    final response = await _dioClient.dio.get(ApiConstants.notifications);
    final data = _safeParse(response.data);
    if (data is Map<String, dynamic>) {
      return NotificationsResponse.fromJson(data);
    }
    return NotificationsResponse.fromJson({});
  }

  Future<DashboardData> getDashboardData({int? branchId}) async {
    String url = ApiConstants.dashboard;
    if (branchId != null && branchId > 0) {
      url = '$url?branch_id=$branchId';
    }
    final response = await _dioClient.dio.get(url);
    final data = _safeParse(response.data);
    if (data is Map<String, dynamic>) {
      return DashboardData.fromJson(data);
    }
    return DashboardData.fromJson({});
  }

  Future<TeamData> getTeamData({int? branchId}) async {
    String url = ApiConstants.dashboardTeam;
    if (branchId != null && branchId > 0) {
      url = '$url?branch_id=$branchId';
    }
    final response = await _dioClient.dio.get(url);
    final data = _safeParse(response.data);
    if (data is Map<String, dynamic>) {
      return TeamData.fromJson(data);
    }
    return TeamData.fromJson({});
  }

  Future<List<TodoItem>> getTodos() async {
    final response = await _dioClient.dio.get(ApiConstants.todos);
    final data = _safeParse(response.data);
    if (data is List) {
      return data.map((e) => TodoItem.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    }
    return [];
  }

  Future<List<BranchModel>> getBranches() async {
    final response = await _dioClient.dio.get(ApiConstants.branches);
    final data = _safeParse(response.data);
    if (data is List) {
      return data.map((e) => BranchModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    }
    return [];
  }

  Future<List<dynamic>> getScheduleMy() async {
    final response = await _dioClient.dio.get(ApiConstants.scheduleMy);
    final data = _safeParse(response.data);
    if (data is List) {
      return data;
    }
    return [];
  }
}
