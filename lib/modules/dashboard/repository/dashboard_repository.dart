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

import '../../../core/utils/preferences_service.dart';

class DashboardRepository {
  final DioClient _dioClient = DioClient();
  final PreferencesService _prefs = PreferencesService();

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
      final role = (await _prefs.getUserRole())?.toLowerCase() ?? '';
      final roleLabel = (await _prefs.getUserRoleLabel())?.toLowerCase() ?? '';
      final isManager = role.contains('manager') || roleLabel.contains('manager');

      Map<String, dynamic> queryParams = {};
      if (isManager || mine == 1) {
        queryParams['mine'] = 1;
      } else {
        if (mine != null) {
          queryParams['mine'] = mine;
        }
        if (branchId != null && branchId > 0) {
          queryParams['branch_id'] = branchId;
          queryParams['branchId'] = branchId;
        }
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
      final role = (await _prefs.getUserRole())?.toLowerCase() ?? '';
      final roleLabel = (await _prefs.getUserRoleLabel())?.toLowerCase() ?? '';
      final isManager = role.contains('manager') || roleLabel.contains('manager');

      String url = ApiConstants.dashboardTeam;
      Map<String, dynamic>? queryParams;
      if (isManager || mine == 1) {
        queryParams = {'mine': 1};
      } else if (branchId != null && branchId > 0) {
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
      _logServiceCall(
        serviceMethod: 'getBranches',
        url: ApiConstants.branches,
        response: response.data,
      );
      final data = _safeParse(response.data);
      List<dynamic>? rawList;
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          rawList = data['data'] as List;
        } else if (data['branches'] is List) {
          rawList = data['branches'] as List;
        } else if (data['results'] is List) {
          rawList = data['results'] as List;
        }
      }
      if (rawList != null) {
        final list = rawList.map((e) => BranchModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
        if (list.isNotEmpty && !list.any((b) => b.id == 0 || b.code.toUpperCase() == 'ALL' || b.name.toLowerCase().contains('all branches'))) {
          list.insert(0, BranchModel(id: 0, code: 'ALL', name: 'All Branches', isAll: true));
        }
        return list;
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
