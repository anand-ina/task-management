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
    final codeVal = json['code']?.toString() ?? json['branch_code']?.toString() ?? '';
    final nameVal = json['name']?.toString() ??
        json['branch_name']?.toString() ??
        json['branchName']?.toString() ??
        json['title']?.toString() ??
        '';
    return BranchInfo(
      id: json['id'] as int? ?? (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      code: codeVal,
      name: nameVal.isNotEmpty ? nameVal : codeVal,
      isAll: json['is_all'] as bool? ?? json['isAll'] as bool? ?? false,
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
    List<dynamic>? usersList;
    if (json['visibleUsers'] is List) {
      usersList = json['visibleUsers'] as List<dynamic>;
    } else if (json['visibleUsers'] != null) {
      usersList = [json['visibleUsers']];
    }
    return UserScope(
      level: json['level'] as int? ?? 0,
      isAll: json['isAll'] as bool? ?? false,
      visibleUsers: usersList,
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
  final List<BranchInfo> branches;
  final DepartmentInfo? department;
  final List<String> permissions;
  final UserScope? scope;
  final String? academicYear;
  final List<int> academicYears;

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
    this.branches = const [],
    this.department,
    required this.permissions,
    this.scope,
    this.academicYear,
    this.academicYears = const [],
  });

  String get firstBranchName {
    if (branch != null && branch!.name.isNotEmpty) {
      return branch!.name;
    }
    if (branches.isNotEmpty && branches.first.name.isNotEmpty) {
      return branches.first.name;
    }
    return '';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Dynamically resolve role and roleLabel from possible response formats
    final dynamic rawRole = json['role'] ?? json['user_role'] ?? json['role_name'];
    String roleStr = '';
    if (rawRole is String) {
      roleStr = rawRole;
    } else if (rawRole is Map<String, dynamic>) {
      roleStr = rawRole['name']?.toString() ?? rawRole['role']?.toString() ?? '';
    }

    final dynamic rawRoleLabel = json['roleLabel'] ??
        json['role_label'] ??
        json['role_title'] ??
        json['designation'] ??
        json['designation_name'];
    String roleLabelStr = '';
    if (rawRoleLabel is String) {
      roleLabelStr = rawRoleLabel;
    } else if (rawRole is Map<String, dynamic>) {
      roleLabelStr = rawRole['label']?.toString() ?? rawRole['role_label']?.toString() ?? '';
    }

    if (roleLabelStr.isEmpty && roleStr.isNotEmpty) {
      roleLabelStr = roleStr;
    }
    if (roleStr.isEmpty && roleLabelStr.isNotEmpty) {
      roleStr = roleLabelStr;
    }

    String resolvedName = json['name']?.toString() ?? json['username']?.toString() ?? '';
    if (resolvedName.isEmpty) {
      final fName = json['first_name']?.toString() ?? '';
      final lName = json['last_name']?.toString() ?? '';
      resolvedName = ('$fName $lName').trim();
    }

    // Extract branches / branch from response (first item if list)
    List<BranchInfo> parsedBranches = [];
    final rawBranches = json['branches'];
    if (rawBranches is List) {
      for (final item in rawBranches) {
        if (item is Map<String, dynamic>) {
          parsedBranches.add(BranchInfo.fromJson(item));
        } else if (item != null && item.toString().isNotEmpty) {
          parsedBranches.add(BranchInfo(id: 0, code: '', name: item.toString(), isAll: false));
        }
      }
    }

    BranchInfo? resolvedBranch;
    final rawBranch = json['branch'];
    if (rawBranch is List) {
      for (final item in rawBranch) {
        if (item is Map<String, dynamic>) {
          parsedBranches.add(BranchInfo.fromJson(item));
        } else if (item != null && item.toString().isNotEmpty) {
          parsedBranches.add(BranchInfo(id: 0, code: '', name: item.toString(), isAll: false));
        }
      }
    } else if (rawBranch is Map<String, dynamic>) {
      resolvedBranch = BranchInfo.fromJson(rawBranch);
    } else if (rawBranch is String && rawBranch.isNotEmpty) {
      resolvedBranch = BranchInfo(id: 0, code: '', name: rawBranch, isAll: false);
    }

    if (resolvedBranch == null && parsedBranches.isNotEmpty) {
      resolvedBranch = parsedBranches.first;
    }

    if (resolvedBranch == null && json['primary_branch'] != null) {
      final pb = json['primary_branch'];
      if (pb is Map<String, dynamic>) {
        resolvedBranch = BranchInfo.fromJson(pb);
      } else if (pb is String && pb.isNotEmpty) {
        resolvedBranch = BranchInfo(id: 0, code: '', name: pb, isAll: false);
      }
    }

    final dynamic explicitBranchRaw = json['branch_id'] ?? json['branchId'] ?? (rawBranch is num ? rawBranch : null);
    final explicitBranchId = int.tryParse(explicitBranchRaw?.toString() ?? '');
    if (explicitBranchId != null && explicitBranchId > 0) {
      if (resolvedBranch == null) {
        resolvedBranch = BranchInfo(id: explicitBranchId, code: '', name: '', isAll: false);
      } else if (resolvedBranch.id == 0) {
        resolvedBranch = BranchInfo(
          id: explicitBranchId,
          code: resolvedBranch.code,
          name: resolvedBranch.name,
          isAll: resolvedBranch.isAll,
        );
      }
    }

    if (resolvedBranch != null && resolvedBranch.id > 0) {
      final matchingParsed = parsedBranches.where((b) => b.id == resolvedBranch!.id).firstOrNull;
      if (matchingParsed != null && matchingParsed.name.isNotEmpty) {
        resolvedBranch = matchingParsed;
      } else if (!parsedBranches.any((b) => b.id == resolvedBranch!.id)) {
        parsedBranches.add(resolvedBranch);
      }
    }

    // Dynamic Academic Year Resolution from API or current date
    String? resolvedAcademicYear;
    final dynamic rawYear = json['academic_year'] ??
        json['academicYear'] ??
        json['current_academic_year'] ??
        json['currentAcademicYear'] ??
        json['fy'] ??
        json['financial_year'];
    if (rawYear != null && rawYear.toString().trim().isNotEmpty) {
      resolvedAcademicYear = rawYear.toString().trim();
    }

    final List<int> parsedAcademicYears = [];
    final dynamic rawYears = json['academic_years'] ??
        json['academicYears'] ??
        json['available_academic_years'] ??
        json['years'];
    if (rawYears is List) {
      for (final item in rawYears) {
        if (item is int) {
          if (!parsedAcademicYears.contains(item)) parsedAcademicYears.add(item);
        } else if (item != null) {
          final str = item.toString();
          final match = RegExp(r'\b(20\d{2})\b').firstMatch(str);
          if (match != null) {
            final y = int.tryParse(match.group(1)!);
            if (y != null && !parsedAcademicYears.contains(y)) {
              parsedAcademicYears.add(y);
            }
          }
        }
      }
    }

    final now = DateTime.now();
    final defaultBaseYear = now.month >= 6 ? now.year : now.year - 1;
    if (parsedAcademicYears.isEmpty) {
      parsedAcademicYears.addAll([defaultBaseYear, defaultBaseYear - 1, defaultBaseYear - 2]);
    }

    return UserProfile(
      id: json['id'] as int? ?? (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      name: resolvedName,
      email: json['email']?.toString() ?? '',
      role: roleStr,
      roleLabel: roleLabelStr,
      level: json['level'] as int? ?? 0,
      isTaskCreator: json['isTaskCreator'] as bool? ?? json['is_task_creator'] as bool? ?? false,
      confidentialAccess: json['confidentialAccess'] as bool? ?? json['confidential_access'] as bool? ?? false,
      branch: resolvedBranch,
      branches: parsedBranches,
      department: json['department'] is Map<String, dynamic> ? DepartmentInfo.fromJson(json['department'] as Map<String, dynamic>) : null,
      permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      scope: json['scope'] is Map<String, dynamic> ? UserScope.fromJson(json['scope'] as Map<String, dynamic>) : null,
      academicYear: resolvedAcademicYear,
      academicYears: parsedAcademicYears,
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
        'branches': branches.map((b) => b.toJson()).toList(),
        'department': department?.toJson(),
        'permissions': permissions,
        'scope': scope?.toJson(),
        'academic_year': academicYear,
        'academic_years': academicYears,
      };

  String get academicYearFormatted {
    if (academicYear != null && academicYear!.trim().isNotEmpty) {
      final clean = academicYear!.trim();
      if (clean.toLowerCase().startsWith('fy')) return clean;
      return 'FY $clean';
    }
    final now = DateTime.now();
    final startYear = now.month >= 6 ? now.year : now.year - 1;
    final endYearStr = (startYear + 1).toString().substring(2);
    return 'FY $startYear–$endYearStr';
  }

  bool get isDirector {
    final r = role.toLowerCase();
    final rl = roleLabel.toLowerCase();
    return r.contains('director') || rl.contains('director');
  }

  bool get isPrincipal {
    final r = role.toLowerCase();
    final rl = roleLabel.toLowerCase();
    return r.contains('principal') ||
        r.contains('center_head') ||
        r.contains('campus_head') ||
        r.contains('center head') ||
        r.contains('campus head') ||
        rl.contains('principal') ||
        rl.contains('center head') ||
        rl.contains('campus head');
  }

  bool get isAdmin {
    final r = role.toLowerCase();
    final rl = roleLabel.toLowerCase();
    return r.contains('admin') || rl.contains('admin');
  }

  bool get isManager {
    final r = role.toLowerCase();
    final rl = roleLabel.toLowerCase();
    return r.contains('manager') || rl.contains('manager');
  }

  bool get isAcademicExecutive {
    final r = role.toLowerCase();
    final rl = roleLabel.toLowerCase();
    return r.contains('academic_executive') ||
        r.contains('academic executive') ||
        r.contains('executive') ||
        r.contains('ae') ||
        rl.contains('academic executive') ||
        rl.contains('executive');
  }

  bool get hasMultiBranchAccess {
    return isDirector || isPrincipal || isAdmin;
  }

  int? get assignedBranchId {
    if (branch != null && branch!.id > 0) return branch!.id;
    for (final b in branches) {
      if (b.id > 0) return b.id;
    }
    return null;
  }
}

