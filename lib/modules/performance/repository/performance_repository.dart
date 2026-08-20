import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/leaderboard_model.dart';
import '../models/ledger_model.dart';
import '../models/performance_me_model.dart';
import '../models/team_performance_model.dart';

class LeaderboardDashboardData {
  final List<LeaderboardMemberModel> members;
  final LedgerModel ledger;
  final PerformanceMeModel me;

  LeaderboardDashboardData({
    required this.members,
    required this.ledger,
    required this.me,
  });
}

class PerformanceRepository {
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

  Future<LeaderboardDashboardData> getLeaderboardData() async {
    final results = await Future.wait([
      _dioClient.dio.get(ApiConstants.performanceLeaderboard),
      _dioClient.dio.get(ApiConstants.performanceLedger),
      _dioClient.dio.get(ApiConstants.performanceMe),
    ]);

    final res0 = _safeParse(results[0].data);
    List<LeaderboardMemberModel> members = [];
    if (res0 is List) {
      members = res0.map((e) => LeaderboardMemberModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
    }

    final res1 = _safeParse(results[1].data);
    LedgerModel ledger = LedgerModel(total: 0, rows: []);
    if (res1 is Map<String, dynamic>) {
      ledger = LedgerModel.fromJson(res1);
    }

    final res2 = _safeParse(results[2].data);
    PerformanceMeModel me = PerformanceMeModel(assigned: 0, done: 0, overdue: 0, points: 0);
    if (res2 is Map<String, dynamic>) {
      me = PerformanceMeModel.fromJson(res2);
    }

    return LeaderboardDashboardData(
      members: members,
      ledger: ledger,
      me: me,
    );
  }

  Future<TeamPerformanceModel> getTeamPerformanceData() async {
    final response = await _dioClient.dio.get(ApiConstants.teamPerformance);
    final res = _safeParse(response.data);
    if (res is Map<String, dynamic>) {
      return TeamPerformanceModel.fromJson(res);
    }
    return TeamPerformanceModel(
      members: [],
      totals: TeamTotalsModel(teamSize: 0, assigned: 0, done: 0, inProgress: 0, toBeStarted: 0, dropped: 0, overdue: 0, dueToday: 0, emergencyHighOpen: 0, points: 0, completion: 0, onTime: 0),
      departments: [],
      teamSize: 0,
    );
  }
}
