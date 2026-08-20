class LookupAssigneeModel {
  final int id;
  final String name;
  final String initials;
  final String avatarColor;
  final String department;
  final bool isTaskCreator;

  LookupAssigneeModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.department,
    required this.isTaskCreator,
  });

  factory LookupAssigneeModel.fromJson(Map<String, dynamic> json) {
    return LookupAssigneeModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      avatarColor: json['avatar_color'] as String? ?? '#3866d6',
      department: json['department'] as String? ?? '',
      isTaskCreator: json['is_task_creator'] as bool? ?? false,
    );
  }
}

class EnumPriorityItem {
  final String value;
  final String label;
  final String hint;
  final String color;

  EnumPriorityItem({
    required this.value,
    required this.label,
    required this.hint,
    required this.color,
  });

  factory EnumPriorityItem.fromJson(Map<String, dynamic> json) {
    return EnumPriorityItem(
      value: json['value'] as String? ?? '',
      label: json['label'] as String? ?? '',
      hint: json['hint'] as String? ?? '',
      color: json['color'] as String? ?? '#3866d6',
    );
  }
}

class EnumStatusItem {
  final String value;
  final String label;

  EnumStatusItem({
    required this.value,
    required this.label,
  });

  factory EnumStatusItem.fromJson(Map<String, dynamic> json) {
    return EnumStatusItem(
      value: json['value'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }
}

class LookupEnumsModel {
  final List<EnumPriorityItem> priorities;
  final List<EnumStatusItem> statuses;

  LookupEnumsModel({
    required this.priorities,
    required this.statuses,
  });

  factory LookupEnumsModel.fromJson(Map<String, dynamic> json) {
    return LookupEnumsModel(
      priorities: (json['priorities'] as List<dynamic>?)
              ?.map((e) => EnumPriorityItem.fromJson(e))
              .toList() ??
          [],
      statuses: (json['statuses'] as List<dynamic>?)
              ?.map((e) => EnumStatusItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
