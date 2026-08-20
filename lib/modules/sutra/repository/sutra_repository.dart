import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
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
    final results = await Future.wait([
      _dioClient.dio.get(ApiConstants.dashboard),
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
}
