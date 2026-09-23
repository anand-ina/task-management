/// Models for the Clone Task feature.
/// All data comes from real API responses — no dummy data.

// ---------------------------------------------------------------------------
// Assignee Model — GET /api/lookups/assignees
// ---------------------------------------------------------------------------
class AssigneeModel {
  final int id;
  final String name;
  final String initials;
  final String avatarColor;
  final String? department;
  final bool isTaskCreator;

  const AssigneeModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    this.department,
    required this.isTaskCreator,
  });

  factory AssigneeModel.fromJson(Map<String, dynamic> json) {
    return AssigneeModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      initials: json['initials']?.toString() ?? '',
      avatarColor: json['avatar_color']?.toString() ?? '#8B5CF6',
      department: json['department']?.toString(),
      isTaskCreator: json['is_task_creator'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initials': initials,
        'avatar_color': avatarColor,
        if (department != null) 'department': department,
        'is_task_creator': isTaskCreator,
      };
}

// ---------------------------------------------------------------------------
// Branch Model — GET /api/lookups/branches
// ---------------------------------------------------------------------------
class BranchModel {
  final int id;
  final String code;
  final String name;
  final bool isAll;

  const BranchModel({
    required this.id,
    required this.code,
    required this.name,
    required this.isAll,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
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

// ---------------------------------------------------------------------------
// Enum Priority Model — from GET /api/lookups/enums → priorities[]
// ---------------------------------------------------------------------------
class EnumPriorityModel {
  final String value;
  final String label;
  final String? hint;
  final String? color;

  const EnumPriorityModel({
    required this.value,
    required this.label,
    this.hint,
    this.color,
  });

  factory EnumPriorityModel.fromJson(Map<String, dynamic> json) {
    return EnumPriorityModel(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      hint: json['hint']?.toString(),
      color: json['color']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------
// Enum Status Model — from GET /api/lookups/enums → statuses[]
// ---------------------------------------------------------------------------
class EnumStatusModel {
  final String value;
  final String label;

  const EnumStatusModel({required this.value, required this.label});

  factory EnumStatusModel.fromJson(Map<String, dynamic> json) {
    return EnumStatusModel(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Next Task ID Model — GET /api/tasks/next-id[?branchId=X]
// ---------------------------------------------------------------------------
class NextTaskIdModel {
  final String taskNo;

  const NextTaskIdModel({required this.taskNo});

  factory NextTaskIdModel.fromJson(Map<String, dynamic> json) {
    return NextTaskIdModel(taskNo: json['taskNo']?.toString() ?? '');
  }
}

// ---------------------------------------------------------------------------
// Lookup bundle — holds everything fetched for the Clone Task dialog
// ---------------------------------------------------------------------------
class CloneTaskLookupsModel {
  final List<AssigneeModel> assignees;
  final List<BranchModel> branches;
  final List<EnumPriorityModel> priorities;
  final List<EnumStatusModel> statuses;
  final String nextTaskNo;

  const CloneTaskLookupsModel({
    required this.assignees,
    required this.branches,
    required this.priorities,
    required this.statuses,
    required this.nextTaskNo,
  });
}
