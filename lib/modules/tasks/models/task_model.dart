class TaskAssigneeModel {
  final int id;
  final String name;
  final String initials;
  final String color;
  final bool active;

  TaskAssigneeModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
    required this.active,
  });

  factory TaskAssigneeModel.fromJson(Map<String, dynamic> json) {
    return TaskAssigneeModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      color: json['color'] as String? ?? '#3866d6',
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initials': initials,
        'color': color,
        'active': active,
      };
}

class TaskTimelineItem {
  final int id;
  final String kind;
  final String note;
  final String createdAt;
  final String actor;

  TaskTimelineItem({
    required this.id,
    required this.kind,
    required this.note,
    required this.createdAt,
    required this.actor,
  });

  factory TaskTimelineItem.fromJson(Map<String, dynamic> json) {
    return TaskTimelineItem(
      id: json['id'] as int? ?? 0,
      kind: json['kind'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      actor: json['actor'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'note': note,
        'created_at': createdAt,
        'actor': actor,
      };
}

class TaskItemModel {
  final int id;
  final String taskNo;
  final String fy;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final int progress;
  final String? location;
  final String entryDate;
  final String dueDate;
  final String? completedDate;
  final String? remarks;
  final bool isConfidential;
  final String? blockReason;
  final String? reviewComment;
  final String assignedByText;
  final int assignedByUserId;
  final String assignedByName;
  final int branchId;
  final String branchCode;
  final String branchName;
  final List<TaskAssigneeModel> assignees;

  TaskItemModel({
    required this.id,
    required this.taskNo,
    required this.fy,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.progress,
    this.location,
    required this.entryDate,
    required this.dueDate,
    this.completedDate,
    this.remarks,
    required this.isConfidential,
    this.blockReason,
    this.reviewComment,
    required this.assignedByText,
    required this.assignedByUserId,
    required this.assignedByName,
    required this.branchId,
    required this.branchCode,
    required this.branchName,
    required this.assignees,
  });

  factory TaskItemModel.fromJson(Map<String, dynamic> json) {
    return TaskItemModel(
      id: json['id'] as int? ?? 0,
      taskNo: json['task_no'] as String? ?? '',
      fy: json['fy'] as String? ?? '2025-26',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      priority: json['priority'] as String? ?? 'high',
      status: json['status'] as String? ?? 'in_progress',
      progress: json['progress'] as int? ?? 0,
      location: json['location'] as String?,
      entryDate: json['entry_date'] as String? ?? '',
      dueDate: json['due_date'] as String? ?? '',
      completedDate: json['completed_date'] as String?,
      remarks: json['remarks'] as String?,
      isConfidential: json['is_confidential'] as bool? ?? false,
      blockReason: json['block_reason'] as String?,
      reviewComment: json['review_comment'] as String?,
      assignedByText: json['assigned_by_text'] as String? ?? '',
      assignedByUserId: json['assigned_by_user_id'] as int? ?? 0,
      assignedByName: json['assigned_by_name'] as String? ?? '',
      branchId: json['branch_id'] as int? ?? 0,
      branchCode: json['branch_code'] as String? ?? '',
      branchName: json['branch_name'] as String? ?? '',
      assignees: (json['assignees'] as List<dynamic>?)
              ?.map((e) => TaskAssigneeModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'task_no': taskNo,
        'fy': fy,
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'status': status,
        'progress': progress,
        'location': location,
        'entry_date': entryDate,
        'due_date': dueDate,
        'completed_date': completedDate,
        'remarks': remarks,
        'is_confidential': isConfidential,
        'block_reason': blockReason,
        'review_comment': reviewComment,
        'assigned_by_text': assignedByText,
        'assigned_by_user_id': assignedByUserId,
        'assigned_by_name': assignedByName,
        'branch_id': branchId,
        'branch_code': branchCode,
        'branch_name': branchName,
        'assignees': assignees.map((e) => e.toJson()).toList(),
      };
}

class TaskDetailModel extends TaskItemModel {
  final List<TaskTimelineItem> timeline;
  final List<dynamic> attachments;
  final List<dynamic> checklist;

  TaskDetailModel({
    required super.id,
    required super.taskNo,
    required super.fy,
    required super.title,
    required super.description,
    required super.category,
    required super.priority,
    required super.status,
    required super.progress,
    super.location,
    required super.entryDate,
    required super.dueDate,
    super.completedDate,
    super.remarks,
    required super.isConfidential,
    super.blockReason,
    super.reviewComment,
    required super.assignedByText,
    required super.assignedByUserId,
    required super.assignedByName,
    required super.branchId,
    required super.branchCode,
    required super.branchName,
    required super.assignees,
    required this.timeline,
    required this.attachments,
    required this.checklist,
  });

  factory TaskDetailModel.fromJson(Map<String, dynamic> json) {
    final baseTask = TaskItemModel.fromJson(json);
    return TaskDetailModel(
      id: baseTask.id,
      taskNo: baseTask.taskNo,
      fy: baseTask.fy,
      title: baseTask.title,
      description: baseTask.description,
      category: baseTask.category,
      priority: baseTask.priority,
      status: baseTask.status,
      progress: baseTask.progress,
      location: baseTask.location,
      entryDate: baseTask.entryDate,
      dueDate: baseTask.dueDate,
      completedDate: baseTask.completedDate,
      remarks: baseTask.remarks,
      isConfidential: baseTask.isConfidential,
      blockReason: baseTask.blockReason,
      reviewComment: baseTask.reviewComment,
      assignedByText: baseTask.assignedByText,
      assignedByUserId: baseTask.assignedByUserId,
      assignedByName: baseTask.assignedByName,
      branchId: baseTask.branchId,
      branchCode: baseTask.branchCode,
      branchName: baseTask.branchName,
      assignees: baseTask.assignees,
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => TaskTimelineItem.fromJson(e))
              .toList() ??
          [],
      attachments: json['attachments'] as List<dynamic>? ?? [],
      checklist: json['checklist'] as List<dynamic>? ?? [],
    );
  }
}

class TasksResponseModel {
  final List<TaskItemModel> items;
  final int total;
  final int limit;
  final int offset;

  TasksResponseModel({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory TasksResponseModel.fromJson(Map<String, dynamic> json) {
    return TasksResponseModel(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => TaskItemModel.fromJson(e))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 50,
      offset: json['offset'] as int? ?? 0,
    );
  }
}
