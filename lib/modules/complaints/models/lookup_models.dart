class LookupDepartmentModel {
  final int id;
  final String name;
  final int? staff;

  const LookupDepartmentModel({
    required this.id,
    required this.name,
    this.staff,
  });

  factory LookupDepartmentModel.fromJson(Map<String, dynamic> json) {
    return LookupDepartmentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      staff: json['staff'] is int ? json['staff'] : int.tryParse(json['staff']?.toString() ?? ''),
    );
  }
}

class LookupBranchModel {
  final int id;
  final String code;
  final String name;
  final bool isAll;

  const LookupBranchModel({
    required this.id,
    required this.code,
    required this.name,
    this.isAll = false,
  });

  factory LookupBranchModel.fromJson(Map<String, dynamic> json) {
    return LookupBranchModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isAll: json['is_all'] == true || json['is_all'] == 1,
    );
  }
}

class LookupAssigneeModel {
  final int id;
  final String name;
  final String initials;
  final String avatarColor;
  final String? department;
  final bool isTaskCreator;

  const LookupAssigneeModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    this.department,
    this.isTaskCreator = false,
  });

  factory LookupAssigneeModel.fromJson(Map<String, dynamic> json) {
    return LookupAssigneeModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      initials: json['initials']?.toString() ?? '',
      avatarColor: json['avatar_color']?.toString() ?? '#132a50',
      department: json['department']?.toString(),
      isTaskCreator: json['is_task_creator'] == true || json['is_task_creator'] == 1,
    );
  }
}
