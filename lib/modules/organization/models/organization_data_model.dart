import '../../dashboard/models/branch_model.dart';
import '../../dashboard/models/dashboard_stats.dart';
import 'trends_model.dart';

class BranchUnitStatModel {
  final BranchModel branch;
  final DashboardStats stats;

  BranchUnitStatModel({
    required this.branch,
    required this.stats,
  });
}

class OrganizationDataModel {
  final DashboardData overallDashboard;
  final TrendsResponseModel trends;
  final List<BranchModel> branches;
  final List<BranchUnitStatModel> branchUnitStats;

  OrganizationDataModel({
    required this.overallDashboard,
    required this.trends,
    required this.branches,
    required this.branchUnitStats,
  });
}
