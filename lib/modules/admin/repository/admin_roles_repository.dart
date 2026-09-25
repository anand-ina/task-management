import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/admin_role_model.dart';
import '../models/admin_permission_model.dart';

class AdminRolesRepository {
  final DioClient _dioClient = DioClient();

  Future<List<AdminRoleModel>> getRoles() async {
    const url = '${ApiConstants.baseUrl}/admin/roles';
    debugPrint('[AdminRolesRepository] GET $url');
    try {
      final response = await _dioClient.dio.get(url);
      debugPrint('[AdminRolesRepository] Roles status: ${response.statusCode}');
      debugPrint('[AdminRolesRepository] Roles response: ${response.data}');
      if (response.data is List) {
        final list = response.data as List<dynamic>;
        return list.map((j) => AdminRoleModel.fromJson(j as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[AdminRolesRepository] Roles error: $e');
      rethrow;
    }
  }

  Future<int?> createRole({
    required String name,
    required String label,
    required int level,
  }) async {
    const url = ApiConstants.adminRoles;
    final payload = {
      'name': name,
      'label': label,
      'level': level,
    };
    debugPrint('[AdminRolesRepository] POST $url with $payload');
    try {
      final response = await _dioClient.dio.post(url, data: payload);
      debugPrint('[AdminRolesRepository] Status: ${response.statusCode}');
      debugPrint('[AdminRolesRepository] Response: ${response.data}');
      if (response.data is Map<String, dynamic> && response.data['id'] != null) {
        return response.data['id'] as int;
      }
    } catch (e) {
      debugPrint('[AdminRolesRepository] Error createRole: $e');
    }
    return null;
  }

  Future<List<AdminPermissionModel>> getPermissions() async {
    const url = '${ApiConstants.baseUrl}/admin/permissions';
    debugPrint('[AdminRolesRepository] GET $url');
    try {
      final response = await _dioClient.dio.get(url);
      debugPrint('[AdminRolesRepository] Permissions status: ${response.statusCode}');
      debugPrint('[AdminRolesRepository] Permissions response: ${response.data}');
      if (response.data is List) {
        final list = response.data as List<dynamic>;
        return list.map((j) => AdminPermissionModel.fromJson(j as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[AdminRolesRepository] Permissions error: $e');
      rethrow;
    }
  }
}
