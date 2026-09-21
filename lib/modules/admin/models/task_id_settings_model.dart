class TaskCounterBranch {
  final int branchId;
  final String code;
  final String name;
  final int lastNo;
  final String next;
  final String? resetAt;
  final String? resetBy;

  const TaskCounterBranch({
    required this.branchId,
    required this.code,
    required this.name,
    required this.lastNo,
    required this.next,
    this.resetAt,
    this.resetBy,
  });

  factory TaskCounterBranch.fromJson(Map<String, dynamic> json) {
    return TaskCounterBranch(
      branchId: json['branchId'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      lastNo: json['lastNo'] as int? ?? 0,
      next: json['next'] as String? ?? '',
      resetAt: json['resetAt'] as String?,
      resetBy: json['resetBy']?.toString(),
    );
  }

  TaskCounterBranch copyWith({
    int? branchId,
    String? code,
    String? name,
    int? lastNo,
    String? next,
    String? resetAt,
    String? resetBy,
  }) {
    return TaskCounterBranch(
      branchId: branchId ?? this.branchId,
      code: code ?? this.code,
      name: name ?? this.name,
      lastNo: lastNo ?? this.lastNo,
      next: next ?? this.next,
      resetAt: resetAt ?? this.resetAt,
      resetBy: resetBy ?? this.resetBy,
    );
  }
}

class TaskCounterResponse {
  final List<TaskCounterBranch> branches;
  final String? periodStart;
  final int max;

  const TaskCounterResponse({
    required this.branches,
    this.periodStart,
    required this.max,
  });

  factory TaskCounterResponse.fromJson(Map<String, dynamic> json) {
    final list = json['branches'] as List<dynamic>? ?? [];
    return TaskCounterResponse(
      branches: list
          .map((b) => TaskCounterBranch.fromJson(b as Map<String, dynamic>))
          .toList(),
      periodStart: json['periodStart'] as String?,
      max: json['max'] as int? ?? 9999,
    );
  }
}

class TicketBranchSetting {
  final int branchId;
  final String code;
  final String name;
  final int? defaultOwnerId;
  final String? defaultOwnerName;
  final String effectiveOwner;

  const TicketBranchSetting({
    required this.branchId,
    required this.code,
    required this.name,
    this.defaultOwnerId,
    this.defaultOwnerName,
    required this.effectiveOwner,
  });

  factory TicketBranchSetting.fromJson(Map<String, dynamic> json) {
    return TicketBranchSetting(
      branchId: json['branchId'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      defaultOwnerId: json['defaultOwnerId'] as int?,
      defaultOwnerName: json['defaultOwnerName'] as String?,
      effectiveOwner: json['effectiveOwner'] as String? ?? '',
    );
  }

  TicketBranchSetting copyWith({
    int? branchId,
    String? code,
    String? name,
    int? defaultOwnerId,
    String? defaultOwnerName,
    String? effectiveOwner,
  }) {
    return TicketBranchSetting(
      branchId: branchId ?? this.branchId,
      code: code ?? this.code,
      name: name ?? this.name,
      defaultOwnerId: defaultOwnerId ?? this.defaultOwnerId,
      defaultOwnerName: defaultOwnerName ?? this.defaultOwnerName,
      effectiveOwner: effectiveOwner ?? this.effectiveOwner,
    );
  }
}

class TicketSettingsResponse {
  final List<TicketBranchSetting> branches;
  final int? defaultOwnerId;
  final String? defaultOwnerName;
  final String effectiveFallback;

  const TicketSettingsResponse({
    required this.branches,
    this.defaultOwnerId,
    this.defaultOwnerName,
    required this.effectiveFallback,
  });

  factory TicketSettingsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['branches'] as List<dynamic>? ?? [];
    return TicketSettingsResponse(
      branches: list
          .map((b) => TicketBranchSetting.fromJson(b as Map<String, dynamic>))
          .toList(),
      defaultOwnerId: json['defaultOwnerId'] as int?,
      defaultOwnerName: json['defaultOwnerName'] as String?,
      effectiveFallback: json['effectiveFallback'] as String? ?? '',
    );
  }

  TicketSettingsResponse copyWith({
    List<TicketBranchSetting>? branches,
    int? defaultOwnerId,
    String? defaultOwnerName,
    String? effectiveFallback,
  }) {
    return TicketSettingsResponse(
      branches: branches ?? this.branches,
      defaultOwnerId: defaultOwnerId ?? this.defaultOwnerId,
      defaultOwnerName: defaultOwnerName ?? this.defaultOwnerName,
      effectiveFallback: effectiveFallback ?? this.effectiveFallback,
    );
  }
}

class AssigneeLookupItem {
  final int id;
  final String name;
  final String initials;
  final String avatarColor;
  final String department;
  final bool isTaskCreator;

  const AssigneeLookupItem({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.department,
    required this.isTaskCreator,
  });

  factory AssigneeLookupItem.fromJson(Map<String, dynamic> json) {
    return AssigneeLookupItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      avatarColor: json['avatar_color'] as String? ?? '#132a50',
      department: json['department'] as String? ?? '',
      isTaskCreator: json['is_task_creator'] as bool? ?? false,
    );
  }
}
