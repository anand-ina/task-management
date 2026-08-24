import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/pull_tasks_model.dart';
import '../models/report_compliance_model.dart';
import '../models/report_stats_model.dart';
import '../models/status_report_model.dart';

class ReportsDashboardData {
  final List<dynamic> reports;
  final ReportStatsModel stats;
  final ReportComplianceModel compliance;

  ReportsDashboardData({
    required this.reports,
    required this.stats,
    required this.compliance,
  });
}

class ReportsRepository {
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

  Future<List<StatusReportItemModel>> getReports() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.reports);
      final data = _safeParse(response.data);
      if (data is List) {
        return data.map((e) => StatusReportItemModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<PullTasksResponseModel> pullTasks({required String type, required String date}) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiConstants.reports}/pull-tasks',
        queryParameters: {'type': type, 'date': date},
      );
      final data = _safeParse(response.data);
      if (data is Map<String, dynamic>) {
        return PullTasksResponseModel.fromJson(data);
      }
    } catch (_) {}
    return PullTasksResponseModel(workCompleted: [], workInProgress: [], pendingTasks: []);
  }

  Future<StatusReportItemModel?> submitReport(Map<String, dynamic> payload) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.reports,
        data: payload,
      );
      final data = _safeParse(response.data);
      if (data is Map<String, dynamic>) {
        return StatusReportItemModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<ReportsDashboardData> getReportsDashboardData() async {
    try {
      final results = await Future.wait([
        _dioClient.dio.get(ApiConstants.reports),
        _dioClient.dio.get(ApiConstants.reportsStats),
        _dioClient.dio.get(ApiConstants.reportsCompliance, queryParameters: {'days': 14}),
      ]);

      List<dynamic> reports = [];
      if (results[0].data is List) {
        reports = results[0].data as List;
      }

      ReportStatsModel stats = ReportStatsModel(
        total: 0,
        submitted: 0,
        draft: 0,
        submittedToday: 0,
        dsr: 0,
        wsr: 0,
        msr: 0,
      );
      if (results[1].data is Map<String, dynamic>) {
        stats = ReportStatsModel.fromJson(results[1].data as Map<String, dynamic>);
      }

      ReportComplianceModel compliance = ReportComplianceModel(days: [], people: []);
      if (results[2].data is Map<String, dynamic>) {
        compliance = ReportComplianceModel.fromJson(results[2].data as Map<String, dynamic>);
      }

      return ReportsDashboardData(
        reports: reports,
        stats: stats,
        compliance: compliance,
      );
    } catch (_) {
      return ReportsDashboardData(
        reports: [],
        stats: ReportStatsModel(total: 0, submitted: 0, draft: 0, submittedToday: 0, dsr: 0, wsr: 0, msr: 0),
        compliance: ReportComplianceModel(days: [], people: []),
      );
    }
  }
}
