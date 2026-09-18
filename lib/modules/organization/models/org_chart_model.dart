class OrgChartPersonModel {
  final int id;
  final String name;
  final String initials;
  final String avatarColor;
  final String designation;
  final int level;
  final String roleLabel;
  final String department;
  final String branchCode;
  final String branchName;
  final String? responsibility;
  final List<dynamic> managers;
  final List<dynamic> dotted;

  const OrgChartPersonModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.designation,
    required this.level,
    required this.roleLabel,
    required this.department,
    required this.branchCode,
    required this.branchName,
    this.responsibility,
    this.managers = const [],
    this.dotted = const [],
  });

  factory OrgChartPersonModel.fromJson(Map<String, dynamic> json) {
    return OrgChartPersonModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      avatarColor: json['avatar_color'] as String? ?? '#132a50',
      designation: json['designation'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      roleLabel: json['role_label'] as String? ?? '',
      department: json['department'] as String? ?? '',
      branchCode: json['branch_code'] as String? ?? '',
      branchName: json['branch_name'] as String? ?? '',
      responsibility: json['responsibility'] as String?,
      managers: (json['managers'] as List<dynamic>?) ?? [],
      dotted: (json['dotted'] as List<dynamic>?) ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initials': initials,
        'avatar_color': avatarColor,
        'designation': designation,
        'level': level,
        'role_label': roleLabel,
        'department': department,
        'branch_code': branchCode,
        'branch_name': branchName,
        'responsibility': responsibility,
        'managers': managers,
        'dotted': dotted,
      };
}

class OrgChartLevelModel {
  final int level;
  final String label;
  final List<OrgChartPersonModel> people;

  const OrgChartLevelModel({
    required this.level,
    required this.label,
    required this.people,
  });

  factory OrgChartLevelModel.fromJson(Map<String, dynamic> json) {
    return OrgChartLevelModel(
      level: json['level'] as int? ?? 1,
      label: json['label'] as String? ?? '',
      people: (json['people'] as List<dynamic>?)
              ?.map((p) => OrgChartPersonModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'label': label,
        'people': people.map((p) => p.toJson()).toList(),
      };
}

class OrgChartEdgeModel {
  final int userId;
  final int managerId;
  final String kind;

  const OrgChartEdgeModel({
    required this.userId,
    required this.managerId,
    required this.kind,
  });

  factory OrgChartEdgeModel.fromJson(Map<String, dynamic> json) {
    return OrgChartEdgeModel(
      userId: json['user_id'] as int? ?? 0,
      managerId: json['manager_id'] as int? ?? 0,
      kind: json['kind'] as String? ?? 'primary',
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'manager_id': managerId,
        'kind': kind,
      };
}

class OrgChartResponseModel {
  final int total;
  final List<OrgChartLevelModel> levels;
  final List<OrgChartEdgeModel> edges;

  const OrgChartResponseModel({
    required this.total,
    required this.levels,
    required this.edges,
  });

  factory OrgChartResponseModel.fromJson(Map<String, dynamic> json) {
    return OrgChartResponseModel(
      total: json['total'] as int? ?? 0,
      levels: (json['levels'] as List<dynamic>?)
              ?.map((l) => OrgChartLevelModel.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => OrgChartEdgeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'levels': levels.map((l) => l.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };
}
