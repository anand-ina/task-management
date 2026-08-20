import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../dashboard/models/branch_model.dart';
import '../../dashboard/models/dashboard_stats.dart';
import '../models/organization_data_model.dart';
import '../models/trends_model.dart';

class OrganizationRepository {
  final DioClient _dioClient = DioClient();

  Future<OrganizationDataModel> getOrganizationData({String bucket = 'week'}) async {
    // 1. Fetch overall dashboard, trends, and branches in parallel
    final results = await Future.wait([
      _dioClient.dio.get(ApiConstants.dashboard),
      _dioClient.dio.get('${ApiConstants.dashboard}/trends', queryParameters: {'bucket': bucket}),
      _dioClient.dio.get(ApiConstants.branches),
    ]);

    final overallDashboard = DashboardData.fromJson(results[0].data);
    final trends = TrendsResponseModel.fromJson(results[1].data);
    List<BranchModel> branches = [];
    if (results[2].data is List) {
      branches = (results[2].data as List).map((e) => BranchModel.fromJson(e)).toList();
    }

    // 2. Fetch stats for individual branch units in parallel (e.g. branchId=1, 2, 3)
    final branchUnitsToFetch = branches.where((b) => !b.isAll).toList();
    final branchStatsResults = await Future.wait(
      branchUnitsToFetch.map((b) => _dioClient.dio.get(
        ApiConstants.dashboard,
        queryParameters: {'branchId': b.id},
      )),
    );

    final List<BranchUnitStatModel> branchUnitStats = [];
    for (int i = 0; i < branchUnitsToFetch.length; i++) {
      final branch = branchUnitsToFetch[i];
      final res = branchStatsResults[i];
      final bDashboard = DashboardData.fromJson(res.data);
      branchUnitStats.add(BranchUnitStatModel(
        branch: branch,
        stats: bDashboard.stats,
      ));
    }

    return OrganizationDataModel(
      overallDashboard: overallDashboard,
      trends: trends,
      branches: branches,
      branchUnitStats: branchUnitStats,
    );
  }
}
