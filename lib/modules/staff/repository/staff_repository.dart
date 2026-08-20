import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/department_model.dart';
import '../models/role_model.dart';
import '../models/staff_model.dart';

class StaffOverviewData {
  final List<StaffModel> staffList;
  final List<DepartmentModel> departments;
  final List<RoleModel> roles;
  final List<Map<String, dynamic>> branches;

  StaffOverviewData({
    required this.staffList,
    required this.departments,
    required this.roles,
    required this.branches,
  });
}

class StaffRepository {
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

  Future<StaffOverviewData> getStaffOverviewData() async {
    final results = await Future.wait([
      _dioClient.dio.get(ApiConstants.staff),
      _dioClient.dio.get(ApiConstants.departments),
      _dioClient.dio.get(ApiConstants.roles),
      _dioClient.dio.get(ApiConstants.branches),
    ]);

    final res0 = _safeParse(results[0].data);
    List<StaffModel> staffList = [];
    if (res0 is Map<String, dynamic> && res0['items'] is List) {
      staffList = (res0['items'] as List)
          .map((e) => StaffModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    } else if (res0 is List) {
      staffList = res0
          .map((e) => StaffModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }

    final res1 = _safeParse(results[1].data);
    List<DepartmentModel> departments = [];
    if (res1 is List) {
      departments = res1
          .map((e) => DepartmentModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }

    final res2 = _safeParse(results[2].data);
    List<RoleModel> roles = [];
    if (res2 is List) {
      roles = res2
          .map((e) => RoleModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }

    final res3 = _safeParse(results[3].data);
    List<Map<String, dynamic>> branches = [];
    if (res3 is List) {
      branches = res3.whereType<Map<String, dynamic>>().toList();
    }

    return StaffOverviewData(
      staffList: staffList,
      departments: departments,
      roles: roles,
      branches: branches,
    );
  }
}
