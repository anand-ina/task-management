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
      return _fallbackOrgChart();
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
      return _fallbackMyReporting();
    }
  }

  OrgChartResponseModel _fallbackOrgChart() {
    return const OrgChartResponseModel(
      total: 20,
      levels: [
        OrgChartLevelModel(
          level: 5,
          label: 'DIRECTOR',
          people: [
            OrgChartPersonModel(
              id: 35,
              name: 'Administrator',
              initials: 'AD',
              avatarColor: '#132a50',
              designation: 'Administrator',
              level: 5,
              roleLabel: 'Director',
              department: 'Administration',
              branchCode: 'SS00',
              branchName: 'Head Office',
            ),
            OrgChartPersonModel(
              id: 2,
              name: 'Madhumathi',
              initials: 'MA',
              avatarColor: '#e5484d',
              designation: 'Director',
              level: 5,
              roleLabel: 'Director',
              department: 'Administration',
              branchCode: 'SS01',
              branchName: 'Moti Nagar & Sanath Nagar',
              responsibility: 'All departments & campuses (Director)',
            ),
            OrgChartPersonModel(
              id: 1,
              name: 'Vamsi',
              initials: 'VA',
              avatarColor: '#1f9d57',
              designation: 'Director',
              level: 5,
              roleLabel: 'Director',
              department: 'Administration',
              branchCode: 'SS00',
              branchName: 'Head Office',
              responsibility: 'All departments & campuses (Director)',
            ),
          ],
        ),
        OrgChartLevelModel(
          level: 4,
          label: 'CENTER HEAD / CAMPUS HEAD',
          people: [
            OrgChartPersonModel(
              id: 101,
              name: 'Lalitha',
              initials: 'LA',
              avatarColor: '#7c3aed',
              designation: 'Center Head / Campus Head',
              level: 4,
              roleLabel: 'Center Head',
              department: 'Administration',
              branchCode: 'SS01',
              branchName: 'Moti Nagar',
              responsibility: 'Campus-wide operations (Center Head)',
              managers: ['Vamsi', 'Madhumathi'],
            ),
            OrgChartPersonModel(
              id: 102,
              name: 'Rajeswari',
              initials: 'RA',
              avatarColor: '#e5484d',
              designation: 'Center Head / Campus Head',
              level: 4,
              roleLabel: 'Center Head',
              department: 'Administration',
              branchCode: 'SS02',
              branchName: 'Peerzadiguda',
              responsibility: 'Campus-wide operations (Center Head)',
              managers: ['Vamsi', 'Madhumathi'],
            ),
            OrgChartPersonModel(
              id: 103,
              name: 'Renuka',
              initials: 'RE',
              avatarColor: '#1f9d57',
              designation: 'Center Head / Campus Head',
              level: 4,
              roleLabel: 'Center Head',
              department: 'Administration',
              branchCode: 'SS00',
              branchName: 'Head Office',
              responsibility: 'Campus-wide operations (Center Head)',
              managers: ['Vamsi', 'Madhumathi'],
            ),
          ],
        ),
        OrgChartLevelModel(
          level: 3,
          label: 'SYSTEM ADMIN / MANAGER',
          people: [
            OrgChartPersonModel(
              id: 104,
              name: 'Murali',
              initials: 'MU',
              avatarColor: '#cf3d8a',
              designation: 'System Admin / Manager',
              level: 3,
              roleLabel: 'Manager',
              department: 'Administration',
              branchCode: 'SS00',
              branchName: 'Head Office',
              responsibility: 'All admin systems (System Admin / Manager)',
              managers: ['Vamsi', 'Madhumathi'],
            ),
            OrgChartPersonModel(
              id: 105,
              name: 'Swapnika',
              initials: 'SW',
              avatarColor: '#e5484d',
              designation: 'System Admin / Manager',
              level: 3,
              roleLabel: 'Manager',
              department: 'Administration',
              branchCode: 'SS00',
              branchName: 'Head Office',
              responsibility: 'All admin systems (System Admin / Manager)',
              managers: ['Vamsi', 'Madhumathi'],
            ),
          ],
        ),
        OrgChartLevelModel(
          level: 2,
          label: 'TEAM LEAD',
          people: [
            OrgChartPersonModel(
              id: 106,
              name: 'Narasimha',
              initials: 'NA',
              avatarColor: '#eab308',
              designation: 'Team Lead',
              level: 2,
              roleLabel: 'Team Lead',
              department: 'Administration',
              branchCode: 'SS01',
              branchName: 'Moti Nagar',
              responsibility: 'Transport',
              managers: ['Murali'],
              dotted: ['Lalitha', 'Renuka'],
            ),
            OrgChartPersonModel(
              id: 13,
              name: 'Revathi',
              initials: 'RE',
              avatarColor: '#cf3d8a',
              designation: 'Team Lead',
              level: 2,
              roleLabel: 'Team Lead',
              department: 'Administration',
              branchCode: 'SS01',
              branchName: 'Moti Nagar & Sanath Nagar',
              responsibility: 'Facility & Store oversight',
              managers: ['Vamsi'],
              dotted: ['Lalitha'],
            ),
          ],
        ),
        OrgChartLevelModel(
          level: 1,
          label: 'ADMIN EXECUTIVE',
          people: [
            OrgChartPersonModel(
              id: 107,
              name: 'Ankima',
              initials: 'AN',
              avatarColor: '#cf3d8a',
              designation: 'Admin Executive',
              level: 1,
              roleLabel: 'Admin Executive',
              department: 'Administration',
              branchCode: 'SS01',
              branchName: 'Moti Nagar',
              responsibility: 'Expenses',
              managers: ['Murali'],
              dotted: ['Renuka'],
            ),
            OrgChartPersonModel(
              id: 14,
              name: 'Anusha',
              initials: 'AN',
              avatarColor: '#e5484d',
              designation: 'Admin Executive',
              level: 1,
              roleLabel: 'Admin Executive',
              department: 'Administration',
              branchCode: 'SS01',
              branchName: 'Moti Nagar & Sanath Nagar',
              responsibility: 'Store',
              managers: ['Revathi'],
            ),
            OrgChartPersonModel(
              id: 108,
              name: 'Chandra Kala',
              initials: 'CK',
              avatarColor: '#1f9d57',
              designation: 'Admin Executive',
              level: 1,
              roleLabel: 'Admin Executive',
              department: 'Administration',
              branchCode: 'SS00',
              branchName: 'Head Office',
              responsibility: 'Collection',
              managers: ['Murali'],
            ),
            OrgChartPersonModel(
              id: 109,
              name: 'Gyapika',
              initials: 'GY',
              avatarColor: '#eab308',
              designation: 'Admin Executive',
              level: 1,
              roleLabel: 'Admin Executive',
              department: 'Administration',
              branchCode: 'SS00',
              branchName: 'Head Office',
              managers: ['Murali'],
            ),
            OrgChartPersonModel(
              id: 110,
              name: 'Kalpana',
              initials: 'KA',
              avatarColor: '#f97316',
              designation: 'Admin Executive',
              level: 1,
              roleLabel: 'Admin Executive',
              department: 'Administration',
              branchCode: 'SS02',
              branchName: 'Peerzadiguda',
              managers: ['Rajeswari'],
            ),
          ],
        ),
      ],
      edges: [],
    );
  }

  MyReportingResponseModel _fallbackMyReporting() {
    return const MyReportingResponseModel(
      me: MyReportingPersonModel(
        id: 14,
        name: 'Anusha',
        initials: 'AN',
        avatarColor: '#e5484d',
        designation: 'Admin Executive',
        level: 1,
        roleLabel: 'Admin Executive',
        department: 'Administration',
        branchCode: 'SS01',
        branchName: 'Moti Nagar & Sanath Nagar',
        responsibility: 'Store',
      ),
      managers: [
        MyReportingPersonModel(
          id: 13,
          name: 'Revathi',
          initials: 'RE',
          avatarColor: '#cf3d8a',
          designation: 'Team Lead',
          level: 2,
          roleLabel: 'Team Lead',
          department: 'Administration',
          branchCode: 'SS01',
          branchName: 'Moti Nagar & Sanath Nagar',
          responsibility: 'Facility & Store oversight',
        ),
      ],
      peers: [
        MyReportingPersonModel(
          id: 9,
          name: 'sudhamahi',
          initials: 'SU',
          avatarColor: '#1f9d57',
          designation: 'Admin Executive',
          level: 1,
          roleLabel: 'Admin Executive',
          department: 'Administration',
          branchCode: 'SS01',
          branchName: 'Moti Nagar & Sanath Nagar',
          responsibility: 'Facility',
        ),
      ],
    );
  }
}
