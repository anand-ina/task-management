import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/admin_branch_model.dart';
import '../models/admin_branch_user_model.dart';
import '../models/admin_department_model.dart';
import '../models/admin_dept_user_model.dart';

class AdminAccessRepository {
  final DioClient _dioClient = DioClient();

  void _log(String label, dynamic data) {
    if (kDebugMode) {
      debugPrint('[AdminAccessRepository] $label: $data');
    }
  }

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

  Future<List<AdminBranchModel>> getBranches() async {
    const url = '${ApiConstants.baseUrl}/admin/branches';
    _log('GET Request URL', url);
    try {
      final response = await _dioClient.dio.get(url);
      _log('GET Response Status', response.statusCode);
      _log('GET Response Data', response.data);

      final resData = _safeParse(response.data);
      if (resData is List) {
        return resData
            .map((e) => AdminBranchModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }
    } catch (e) {
      _log('GET Error (Fallback mock branches loaded)', e);
    }
    return _getFallbackBranches();
  }

  Future<List<AdminDepartmentModel>> getDepartments() async {
    const url = '${ApiConstants.baseUrl}/admin/departments';
    _log('GET Request URL', url);
    try {
      final response = await _dioClient.dio.get(url);
      _log('GET Response Status', response.statusCode);
      _log('GET Response Data', response.data);

      final resData = _safeParse(response.data);
      if (resData is List) {
        return resData
            .map((e) => AdminDepartmentModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }
    } catch (e) {
      _log('GET Error (Fallback mock departments loaded)', e);
    }
    return _getFallbackDepartments();
  }

  Future<List<AdminBranchUserModel>> getBranchUsers(int branchId) async {
    final url = '${ApiConstants.baseUrl}/admin/branches/$branchId/users';
    _log('GET Request URL', url);
    try {
      final response = await _dioClient.dio.get(url);
      _log('GET Response Status', response.statusCode);
      _log('GET Response Data', response.data);

      final resData = _safeParse(response.data);
      if (resData is List) {
        return resData
            .map((e) => AdminBranchUserModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }
    } catch (e) {
      _log('GET Error (Fallback mock branch users loaded)', e);
    }
    return _getFallbackBranchUsers(branchId);
  }

  Future<List<AdminDeptUserModel>> getDeptUsers(int deptId) async {
    final url = '${ApiConstants.baseUrl}/admin/departments/$deptId/users';
    _log('GET Request URL', url);
    try {
      final response = await _dioClient.dio.get(url);
      _log('GET Response Status', response.statusCode);
      _log('GET Response Data', response.data);

      final resData = _safeParse(response.data);
      if (resData is List) {
        return resData
            .map((e) => AdminDeptUserModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }
    } catch (e) {
      _log('GET Error (Fallback mock dept users loaded)', e);
    }
    return _getFallbackDeptUsers(deptId);
  }

  Future<int?> createBranch({required String code, required String name, bool isAll = false}) async {
    const url = ApiConstants.adminBranches;
    _log('POST Request URL', url);
    final payload = {'code': code, 'name': name, 'isAll': isAll};
    _log('POST Payload', payload);
    try {
      final response = await _dioClient.dio.post(url, data: payload);
      _log('POST Response Status', response.statusCode);
      _log('POST Response Data', response.data);
      final resData = _safeParse(response.data);
      if (resData is Map<String, dynamic> && resData['id'] != null) {
        return resData['id'] as int;
      }
    } catch (e) {
      _log('POST Error createBranch', e);
    }
    return null;
  }

  Future<bool> updateBranch({required int id, required String code, required String name, bool isAll = false}) async {
    final url = '${ApiConstants.adminBranches}/$id';
    _log('PATCH Request URL', url);
    final payload = {'id': id, 'code': code, 'name': name, 'isAll': isAll};
    _log('PATCH Payload', payload);
    try {
      final response = await _dioClient.dio.patch(url, data: payload);
      _log('PATCH Response Status', response.statusCode);
      _log('PATCH Response Data', response.data);
      return response.statusCode == 200;
    } catch (e) {
      _log('PATCH Error updateBranch', e);
      return false;
    }
  }

  Future<int?> createDepartment({required String name}) async {
    const url = ApiConstants.adminDepartments;
    _log('POST Request URL', url);
    final payload = {'name': name};
    _log('POST Payload', payload);
    try {
      final response = await _dioClient.dio.post(url, data: payload);
      _log('POST Response Status', response.statusCode);
      _log('POST Response Data', response.data);
      final resData = _safeParse(response.data);
      if (resData is Map<String, dynamic> && resData['id'] != null) {
        return resData['id'] as int;
      }
    } catch (e) {
      _log('POST Error createDepartment', e);
    }
    return null;
  }

  Future<bool> updateDepartment({required int id, required String name}) async {
    final url = '${ApiConstants.adminDepartments}/$id';
    _log('PATCH Request URL', url);
    final payload = {'name': name};
    _log('PATCH Payload', payload);
    try {
      final response = await _dioClient.dio.patch(url, data: payload);
      _log('PATCH Response Status', response.statusCode);
      _log('PATCH Response Data', response.data);
      return response.statusCode == 200;
    } catch (e) {
      _log('PATCH Error updateDepartment', e);
      return false;
    }
  }

  List<AdminBranchModel> _getFallbackBranches() {
    return [
      AdminBranchModel(id: 1, code: 'SS00', name: 'Head Office', isAll: true, users: 2),
      AdminBranchModel(id: 2, code: 'SS01', name: 'Moti Nagar & Sanath Nagar', isAll: false, users: 18),
      AdminBranchModel(id: 3, code: 'SS02', name: 'Peerzadiguda', isAll: false, users: 0),
    ];
  }

  List<AdminDepartmentModel> _getFallbackDepartments() {
    return [
      AdminDepartmentModel(id: 7, name: 'Academics', users: 0),
      AdminDepartmentModel(id: 1, name: 'Administration', users: 19),
      AdminDepartmentModel(id: 2, name: 'Admission Counselling', users: 1),
      AdminDepartmentModel(id: 3, name: 'Finance', users: 0),
      AdminDepartmentModel(id: 4, name: 'Front Office', users: 0),
      AdminDepartmentModel(id: 5, name: 'HR', users: 0),
      AdminDepartmentModel(id: 6, name: 'Transport', users: 0),
    ];
  }

  List<AdminBranchUserModel> _getFallbackBranchUsers(int branchId) {
    if (branchId == 1) {
      return [
        AdminBranchUserModel(
          id: 35,
          name: 'Administrator',
          initials: 'AD',
          avatarColor: '#132a50',
          email: 'admin@samskara.edu.in',
          designation: 'Administrator',
          department: 'Administration',
          roleLabel: 'Administrator',
        ),
        AdminBranchUserModel(
          id: 1,
          name: 'Vamsi',
          initials: 'VA',
          avatarColor: '#1f9d57',
          email: 'vamsi@samskara.edu.in',
          designation: 'Director',
          department: 'Administration',
          roleLabel: 'Director',
        ),
      ];
    }
    return [];
  }

  List<AdminDeptUserModel> _getFallbackDeptUsers(int deptId) {
    if (deptId == 2) {
      return [
        AdminDeptUserModel(
          id: 4,
          name: 'Swapnika',
          initials: 'SW',
          avatarColor: '#e5484d',
          email: 'swapnika@samskara.edu.in',
          designation: 'System Admin / Manager',
          branchCode: 'SS01',
          roleLabel: 'Manager',
        ),
      ];
    } else if (deptId == 1) {
      return [
        AdminDeptUserModel(
          id: 35,
          name: 'Administrator',
          initials: 'AD',
          avatarColor: '#132a50',
          email: 'admin@samskara.edu.in',
          designation: 'Administrator',
          branchCode: 'SS00',
          roleLabel: 'Administrator',
        ),
        AdminDeptUserModel(
          id: 1,
          name: 'Vamsi',
          initials: 'VA',
          avatarColor: '#1f9d57',
          email: 'vamsi@samskara.edu.in',
          designation: 'Director',
          branchCode: 'SS00',
          roleLabel: 'Director',
        ),
      ];
    }
    return [];
  }
}
