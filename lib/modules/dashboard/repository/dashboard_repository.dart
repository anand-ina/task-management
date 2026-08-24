import 'dart:convert';
import 'package:intl/intl.dart';
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
    try {
      final response = await _dioClient.dio.get(ApiConstants.notifications);
      final data = _safeParse(response.data);
      if (data is Map<String, dynamic>) {
        return NotificationsResponse.fromJson(data);
      }
    } catch (_) {}
    return NotificationsResponse.fromJson({});
  }

  Future<DashboardData> getDashboardData({int? branchId, int? mine}) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (mine != null) {
        queryParams['mine'] = mine;
      }
      if (branchId != null && branchId > 0) {
        queryParams['branch_id'] = branchId;
      }
      final response = await _dioClient.dio.get(
        ApiConstants.dashboard,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = _safeParse(response.data);
      if (data is Map<String, dynamic>) {
        return DashboardData.fromJson(data);
      }
    } catch (_) {}
    return DashboardData.fromJson({});
  }

  Future<TeamData> getTeamData({int? branchId}) async {
    try {
      String url = ApiConstants.dashboardTeam;
      if (branchId != null && branchId > 0) {
        url = '$url?branch_id=$branchId';
      }
      final response = await _dioClient.dio.get(url);
      final data = _safeParse(response.data);
      if (data is Map<String, dynamic>) {
        return TeamData.fromJson(data);
      }
    } catch (_) {}
    return TeamData.fromJson({});
  }

  Future<List<TodoItem>> getTodos() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.todos);
      final data = _safeParse(response.data);
      if (data is List) {
        return data.map((e) => TodoItem.fromJson(e is Map<String, dynamic> ? e : {})).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<BranchModel>> getBranches() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.branches);
      final data = _safeParse(response.data);
      if (data is List) {
        return data.map((e) => BranchModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<dynamic>> getScheduleMy() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.scheduleMy);
      final data = _safeParse(response.data);
      if (data is List) {
        return data;
      }
    } catch (_) {}
    return [];
  }

  Future<TodoItem?> addTodo(String text) async {
    try {
      final dayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final response = await _dioClient.dio.post(
        ApiConstants.todos,
        data: {'text': text, 'day': dayStr},
      );
      final data = _safeParse(response.data);
      if (data is Map<String, dynamic>) {
        return TodoItem.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<TodoItem?> patchTodo(int id, bool done) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConstants.todos}/$id',
        data: {'done': done},
      );
      final data = _safeParse(response.data);
      if (data is Map<String, dynamic>) {
        return TodoItem.fromJson(data);
      }
    } catch (_) {}
    return null;
  }
}
