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
    List<StaffModel> staffList = [];
    List<DepartmentModel> departments = [];
    List<RoleModel> roles = [];
    List<Map<String, dynamic>> branches = [];

    try {
      final results = await Future.wait([
        _dioClient.dio.get(ApiConstants.staff),
        _dioClient.dio.get(ApiConstants.departments),
        _dioClient.dio.get(ApiConstants.roles),
        _dioClient.dio.get(ApiConstants.branches),
      ]);

      final res0 = _safeParse(results[0].data);
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
      if (res1 is List) {
        departments = res1
            .map((e) => DepartmentModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }

      final res2 = _safeParse(results[2].data);
      if (res2 is List) {
        roles = res2
            .map((e) => RoleModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList();
      }

      final res3 = _safeParse(results[3].data);
      if (res3 is List) {
        branches = res3.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {
      // Fallback on network/error
    }

    if (staffList.isEmpty) {
      staffList = _getFallbackStaffList();
    }

    return StaffOverviewData(
      staffList: staffList,
      departments: departments,
      roles: roles,
      branches: branches,
    );
  }

  List<StaffModel> _getFallbackStaffList() {
    return [
      StaffModel(id: 1, name: 'Administrator', firstName: 'Administrator', email: 'admin@samskara.edu', phone: '', countryCode: '+91', designation: 'Administrator', employmentType: 'non_teaching', isTaskCreator: true, confidentialAccess: true, avatarColor: '#1E293B', initials: 'AD', department: 'Administration', roleLabel: 'Administrator', roleName: 'admin', created: 0, assigned: 0, done: 0, fines: '0', isPasswordPending: false),
      StaffModel(id: 2, name: 'Ankima', firstName: 'Ankima', email: 'ankima@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#EC4899', initials: 'AN', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 8, done: 0, fines: '0', isPasswordPending: false),
      StaffModel(id: 3, name: 'Anusha', firstName: 'Anusha', email: 'anusha@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#EF4444', initials: 'AN', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 2, done: 0, fines: '0', isPasswordPending: true),
      StaffModel(id: 4, name: 'Chandra Kala', firstName: 'Chandra', lastName: 'Kala', email: 'chandra.kala@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#10B981', initials: 'CK', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 6, done: 0, fines: '0', isPasswordPending: true),
      StaffModel(id: 5, name: 'Gyapika', firstName: 'Gyapika', email: 'gyapika@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#D97706', initials: 'GY', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 7, done: 0, fines: '0', isPasswordPending: true),
      StaffModel(id: 6, name: 'Kalpana', firstName: 'Kalpana', email: 'kalpana@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#F59E0B', initials: 'KA', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 0, done: 0, fines: '0', isPasswordPending: true),
      StaffModel(id: 7, name: 'Lalitha', firstName: 'Lalitha', email: 'lalitha@samskara.edu', phone: '', countryCode: '+91', designation: 'Center Head / Principal', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#8B5CF6', initials: 'LA', department: 'Administration', roleLabel: 'Center Head / Principal', roleName: 'principal', created: 0, assigned: 0, done: 0, fines: '0', isPasswordPending: true),
      StaffModel(id: 8, name: 'Madhumathi', firstName: 'Madhumathi', email: 'madhumathi@samskara.edu', phone: '', countryCode: '+91', designation: 'Director', employmentType: 'non_teaching', isTaskCreator: true, confidentialAccess: true, avatarColor: '#DC2626', initials: 'MA', department: 'Administration', roleLabel: 'Director', roleName: 'director', created: 0, assigned: 0, done: 0, fines: '0', isPasswordPending: true),
      StaffModel(id: 9, name: 'Murali', firstName: 'Murali', email: 'murali@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#EA580C', initials: 'MU', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 3, done: 0, fines: '0', isPasswordPending: false),
      StaffModel(id: 10, name: 'Nageshwari', firstName: 'Nageshwari', email: 'nageshwari@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#DB2777', initials: 'NA', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 1, done: 0, fines: '0', isPasswordPending: false),
      StaffModel(id: 11, name: 'Narasimha', firstName: 'Narasimha', email: 'narasimha@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#D97706', initials: 'NA', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 4, done: 0, fines: '0', isPasswordPending: false),
      StaffModel(id: 12, name: 'Narender', firstName: 'Narender', email: 'narender@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#2563EB', initials: 'NA', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 0, done: 0, fines: '0', isPasswordPending: false),
      StaffModel(id: 13, name: 'Nirosha', firstName: 'Nirosha', email: 'nirosha@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#4F46E5', initials: 'NI', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 0, done: 0, fines: '0', isPasswordPending: true),
      StaffModel(id: 14, name: 'Padma', firstName: 'Padma', email: 'padma@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#059669', initials: 'PA', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 2, done: 0, fines: '0', isPasswordPending: true),
      StaffModel(id: 15, name: 'Pavani', firstName: 'Pavani', email: 'pavani@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#0284C7', initials: 'PA', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 5, done: 0, fines: '0', isPasswordPending: true),
      StaffModel(id: 16, name: 'Pradeep', firstName: 'Pradeep', email: 'pradeep@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#7C3AED', initials: 'PR', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 1, done: 0, fines: '0', isPasswordPending: true),
      StaffModel(id: 17, name: 'Radha', firstName: 'Radha', email: 'radha@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#C026D3', initials: 'RA', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 3, done: 0, fines: '0', isPasswordPending: true),
      StaffModel(id: 18, name: 'Rajesh', firstName: 'Rajesh', email: 'rajesh@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#E11D48', initials: 'RA', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 0, done: 0, fines: '0', isPasswordPending: true),
      StaffModel(id: 19, name: 'Ramesh', firstName: 'Ramesh', email: 'ramesh@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#16A34A', initials: 'RA', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 2, done: 0, fines: '0', isPasswordPending: true),
      StaffModel(id: 20, name: 'Srinivas', firstName: 'Srinivas', email: 'srinivas@samskara.edu', phone: '', countryCode: '+91', designation: 'Academic Executive', employmentType: 'non_teaching', isTaskCreator: false, confidentialAccess: false, avatarColor: '#D97706', initials: 'SR', department: 'Administration', roleLabel: 'Academic Executive', roleName: 'executive', created: 0, assigned: 4, done: 0, fines: '0', isPasswordPending: true),
    ];
  }
}
