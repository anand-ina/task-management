import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/preferences_service.dart';
import '../../dashboard/models/dashboard_stats.dart';
import '../models/sutra_task_model.dart';

class SutraDashboardData {
  final DashboardData dashboardData;
  final List<SutraTaskModel> activeTasks;

  SutraDashboardData({
    required this.dashboardData,
    required this.activeTasks,
  });
}

class SutraRepository {
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

  Future<SutraDashboardData> getSutraData() async {
    final role = (await _prefs.getUserRole())?.toLowerCase() ?? '';
    final roleLabel = (await _prefs.getUserRoleLabel())?.toLowerCase() ?? '';
    final isManager = role.contains('manager') || roleLabel.contains('manager');
    final Map<String, dynamic>? dashParams = isManager ? {'mine': 1} : null;

    final results = await Future.wait([
      _dioClient.dio.get(ApiConstants.dashboard, queryParameters: dashParams),
      _dioClient.dio.get(
        ApiConstants.tasks,
        queryParameters: {'scope': 'mine', 'status': 'in_progress', 'limit': 20},
      ),
    ]);

    final dashRes = _safeParse(results[0].data);
    DashboardData dashboardData = DashboardData.fromJson({});
    if (dashRes is Map<String, dynamic>) {
      dashboardData = DashboardData.fromJson(dashRes);
    }

    final tasksRes = _safeParse(results[1].data);
    List<SutraTaskModel> activeTasks = [];
    if (tasksRes is Map<String, dynamic> && tasksRes['items'] is List) {
      activeTasks = (tasksRes['items'] as List)
          .map((e) => SutraTaskModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    } else if (tasksRes is List) {
      activeTasks = tasksRes
          .map((e) => SutraTaskModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }

    return SutraDashboardData(
      dashboardData: dashboardData,
      activeTasks: activeTasks,
    );
  }

  Future<Map<String, dynamic>> sendSutraCommand(String text) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.sutraCommand,
        data: {'text': text},
      );
      final res = _safeParse(response.data);
      if (res is Map<String, dynamic>) {
        return res;
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final res = _safeParse(e.response!.data);
        if (res is Map<String, dynamic>) {
          return res;
        }
      }
    }
    return {
      'kind': 'unknown',
      'message': "I couldn't understand that. Try e.g. “Schedule a meeting with Swapnika and Narasimha tomorrow 4pm”.",
    };
  }
}
