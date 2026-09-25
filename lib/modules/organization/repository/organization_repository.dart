import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../dashboard/models/branch_model.dart';
import '../../dashboard/models/dashboard_stats.dart';
import '../models/organization_data_model.dart';
import '../models/trends_model.dart';
import '../models/org_chart_model.dart';
import '../models/my_reporting_model.dart';

class OrganizationRepository {
  final DioClient _dioClient = DioClient();

  void _logServiceCall({
    required String serviceMethod,
    required String url,
    dynamic payload,
    dynamic response,
  }) {
    debugPrint('---------------- [OrganizationService: $serviceMethod] ----------------');
    debugPrint('Service URL: $url');
    if (payload != null) {
      debugPrint('Service Payload / QueryParams: $payload');
    }
    if (response != null) {
      debugPrint('Service Response: $response');
    }
    debugPrint('-------------------------------------------------------------------');
  }

  Future<OrganizationDataModel> getOrganizationData({String bucket = 'week', int? branchId}) async {
    Map<String, dynamic>? dashParams;
    Map<String, dynamic> trendParams = {'bucket': bucket};
    if (branchId != null && branchId > 0) {
      dashParams = {'branchId': branchId, 'branch_id': branchId};
      trendParams['branchId'] = branchId;
      trendParams['branch_id'] = branchId;
    }

    _logServiceCall(
      serviceMethod: 'getOrganizationData',
      url: ApiConstants.dashboard,
      payload: {'dashParams': dashParams, 'trendParams': trendParams, 'branchId': branchId},
    );

    // 1. Fetch overall dashboard, trends, and branches in parallel
    final results = await Future.wait([
      _dioClient.dio.get(ApiConstants.dashboard, queryParameters: dashParams),
      _dioClient.dio.get('${ApiConstants.dashboard}/trends', queryParameters: trendParams),
      _dioClient.dio.get(ApiConstants.branches),
    ]);

    final overallDashboard = DashboardData.fromJson(results[0].data);
    final trends = TrendsResponseModel.fromJson(results[1].data);
    List<BranchModel> branches = [];
    if (results[2].data is List) {
      branches = (results[2].data as List).map((e) => BranchModel.fromJson(e)).toList();
    }

    // 2. Fetch stats for individual branch units in parallel (e.g. branchId=1, 2, 3)
    final branchUnitsToFetch = branchId != null && branchId > 0
        ? branches.where((b) => b.id == branchId).toList()
        : branches.where((b) => !b.isAll).toList();
    final branchStatsResults = await Future.wait(
      branchUnitsToFetch.map((b) => _dioClient.dio.get(
        ApiConstants.dashboard,
        queryParameters: {'branchId': b.id, 'branch_id': b.id},
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

  Future<OrgChartResponseModel> getOrgChart() async {
    const url = ApiConstants.orgChart;
    debugPrint('[OrganizationRepository] GET $url');
    try {
      final response = await _dioClient.dio.get(url);
      debugPrint('[OrganizationRepository] OrgChart Status: ${response.statusCode}');
      debugPrint('[OrganizationRepository] OrgChart Response: ${response.data}');
      return OrgChartResponseModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[OrganizationRepository] OrgChart Error: $e');
      rethrow;
    }
  }

  Future<MyReportingResponseModel> getMyReporting() async {
    const url = ApiConstants.orgMyReporting;
    debugPrint('[OrganizationRepository] GET $url');
    try {
      final response = await _dioClient.dio.get(url);
      debugPrint('[OrganizationRepository] MyReporting Status: ${response.statusCode}');
      debugPrint('[OrganizationRepository] MyReporting Response: ${response.data}');
      return MyReportingResponseModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[OrganizationRepository] MyReporting Error: $e');
      rethrow;
    }
  }
}
