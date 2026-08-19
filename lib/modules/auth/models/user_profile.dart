class BranchInfo {
  final int id;
  final String code;
  final String name;
  final bool isAll;

  BranchInfo({
    required this.id,
    required this.code,
    required this.name,
    required this.isAll,
  });

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isAll: json['is_all'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'is_all': isAll,
      };
}

class DepartmentInfo {
  final int id;
  final String name;

  DepartmentInfo({required this.id, required this.name});

  factory DepartmentInfo.fromJson(Map<String, dynamic> json) {
    return DepartmentInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class UserScope {
  final int level;
  final bool isAll;
  final List<dynamic>? visibleUsers;

  UserScope({
    required this.level,
    required this.isAll,
    this.visibleUsers,
  });

  factory UserScope.fromJson(Map<String, dynamic> json) {
    return UserScope(
      level: json['level'] as int? ?? 0,
      isAll: json['isAll'] as bool? ?? false,
      visibleUsers: json['visibleUsers'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'isAll': isAll,
        'visibleUsers': visibleUsers,
      };
}

class UserProfile {
  final int id;
  final String name;
  final String email;
  final String role;
  final String roleLabel;
  final int level;
  final bool isTaskCreator;
  final bool confidentialAccess;
  final BranchInfo? branch;
  final DepartmentInfo? department;
  final List<String> permissions;
  final UserScope? scope;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roleLabel,
    required this.level,
    required this.isTaskCreator,
    required this.confidentialAccess,
    this.branch,
    this.department,
    required this.permissions,
    this.scope,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      roleLabel: json['roleLabel'] as String? ?? '',
      level: json['level'] as int? ?? 0,
      isTaskCreator: json['isTaskCreator'] as bool? ?? false,
      confidentialAccess: json['confidentialAccess'] as bool? ?? false,
      branch: json['branch'] != null ? BranchInfo.fromJson(json['branch']) : null,
      department: json['department'] != null ? DepartmentInfo.fromJson(json['department']) : null,
      permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      scope: json['scope'] != null ? UserScope.fromJson(json['scope']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'roleLabel': roleLabel,
        'level': level,
        'isTaskCreator': isTaskCreator,
        'confidentialAccess': confidentialAccess,
        'branch': branch?.toJson(),
        'department': department?.toJson(),
        'permissions': permissions,
        'scope': scope?.toJson(),
      };
}

