import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  void _logServiceCall({
    required String serviceMethod,
    required String url,
    dynamic payload,
    dynamic response,
  }) {
    debugPrint('---------------- [DashboardService: $serviceMethod] ----------------');
    debugPrint('Service URL: $url');
    if (payload != null) {
      debugPrint('Service Payload / QueryParams: $payload');
    }
    if (response != null) {
      debugPrint('Service Response: $response');
    }
    debugPrint('-------------------------------------------------------------------');
  }

  Future<NotificationsResponse> getNotifications() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.notifications);
      _logServiceCall(
        serviceMethod: 'getNotifications',
        url: ApiConstants.notifications,
        response: response.data,
      );
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
      // When mine == 1 (e.g. Manager login), suppress branch_id and branchId
      if (mine != 1 && branchId != null && branchId > 0) {
        queryParams['branch_id'] = branchId;
        queryParams['branchId'] = branchId;
      }
      final response = await _dioClient.dio.get(
        ApiConstants.dashboard,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      _logServiceCall(
        serviceMethod: 'getDashboardData',
        url: ApiConstants.dashboard,
        payload: queryParams,
        response: response.data,
      );
      final data = _safeParse(response.data);
      if (data is Map<String, dynamic>) {
        return DashboardData.fromJson(data);
      }
    } catch (_) {}
    return DashboardData.fromJson({});
  }

  Future<TeamData> getTeamData({int? branchId, int? mine}) async {
    try {
      String url = ApiConstants.dashboardTeam;
      Map<String, dynamic>? queryParams;
      // When mine == 1 (e.g. Manager login), suppress branch_id and branchId
      if (mine != 1 && branchId != null && branchId > 0) {
        queryParams = {'branch_id': branchId, 'branchId': branchId};
      }
      final response = await _dioClient.dio.get(url, queryParameters: queryParams);
      _logServiceCall(
        serviceMethod: 'getTeamData',
        url: url,
        payload: queryParams,
        response: response.data,
      );
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
        final list = data.map((e) => BranchModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
        if (!list.any((b) => b.id == 0 || b.code == 'ALL')) {
          list.insert(0, BranchModel(id: 0, code: 'ALL', name: 'All Branches', isAll: true));
        }
        return list;
      }
    } catch (_) {}
    return [
      BranchModel(id: 0, code: 'ALL', name: 'All Branches', isAll: true),
      BranchModel(id: 1, code: 'SS00', name: 'Head Office', isAll: false),
      BranchModel(id: 2, code: 'SS01', name: 'Moti Nagar & Sanath Nagar', isAll: false),
      BranchModel(id: 3, code: 'SS02', name: 'Peerzadiguda', isAll: false),
    ];
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
