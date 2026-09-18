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
      final list = response.data as List<dynamic>;
      return list.map((j) => AdminRoleModel.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[AdminRolesRepository] Roles error: $e');
      return _fallbackRoles();
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
      final list = response.data as List<dynamic>;
      return list.map((j) => AdminPermissionModel.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[AdminRolesRepository] Permissions error: $e');
      return _fallbackPermissions();
    }
  }

  List<AdminRoleModel> _fallbackRoles() {
    return [
      AdminRoleModel(id: 1, name: 'DIRECTOR', label: 'Director', level: 1, permissions: ['view_all', 'manage_users', 'manage_roles'], users: 1),
      AdminRoleModel(id: 2, name: 'CENTER_HEAD', label: 'Center Head', level: 2, permissions: ['view_branch', 'assign_tasks'], users: 3),
      AdminRoleModel(id: 3, name: 'MANAGER', label: 'Manager', level: 3, permissions: ['view_team', 'create_tasks'], users: 5),
      AdminRoleModel(id: 4, name: 'TEAM_LEAD', label: 'Team Lead', level: 4, permissions: ['view_team', 'create_tasks'], users: 8),
      AdminRoleModel(id: 5, name: 'EXECUTIVE', label: 'Executive', level: 5, permissions: ['view_own'], users: 25),
    ];
  }

  List<AdminPermissionModel> _fallbackPermissions() {
    return [
      const AdminPermissionModel(id: 1, code: 'view_all', description: 'View all organisation data'),
      const AdminPermissionModel(id: 2, code: 'view_branch', description: 'View branch data'),
      const AdminPermissionModel(id: 3, code: 'view_team', description: 'View team data'),
      const AdminPermissionModel(id: 4, code: 'view_own', description: 'View own data only'),
      const AdminPermissionModel(id: 5, code: 'manage_users', description: 'Create/edit users'),
      const AdminPermissionModel(id: 6, code: 'manage_roles', description: 'Manage roles & permissions'),
      const AdminPermissionModel(id: 7, code: 'assign_tasks', description: 'Assign tasks to others'),
      const AdminPermissionModel(id: 8, code: 'create_tasks', description: 'Create new tasks'),
      const AdminPermissionModel(id: 9, code: 'approve_tasks', description: 'Approve task completion'),
      const AdminPermissionModel(id: 10, code: 'view_reports', description: 'View status reports'),
      const AdminPermissionModel(id: 11, code: 'manage_meetings', description: 'Create/manage meetings'),
      const AdminPermissionModel(id: 12, code: 'issue_fines', description: 'Issue fines and rewards'),
    ];
  }
}
