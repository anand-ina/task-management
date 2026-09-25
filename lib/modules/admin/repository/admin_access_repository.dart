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
      _log('GET Error', e);
    }
    return [];
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
      _log('GET Error', e);
    }
    return [];
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
      _log('GET Error', e);
    }
    return [];
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
      _log('GET Error', e);
    }
    return [];
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
}
