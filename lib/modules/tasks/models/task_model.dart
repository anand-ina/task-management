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
    final activeVal = json['active'];
    final isActive = activeVal is bool
        ? activeVal
        : (activeVal == 1 || activeVal == '1' || activeVal == 'true' || activeVal == null);
    final nameStr = json['name']?.toString() ?? '';
    String initStr = json['initials']?.toString() ?? '';
    if (initStr.isEmpty && nameStr.isNotEmpty) {
      final parts = nameStr.trim().split(RegExp(r'\s+'));
      if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        initStr = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (nameStr.isNotEmpty) {
        initStr = nameStr.substring(0, 1).toUpperCase();
      }
    }
    final rawId = json['id'];
    final int idVal = rawId is num ? rawId.toInt() : (int.tryParse(rawId?.toString() ?? '') ?? 0);
    return TaskAssigneeModel(
      id: idVal,
      name: nameStr,
      initials: initStr,
      color: json['color']?.toString() ?? json['avatar_color']?.toString() ?? '#3866d6',
      active: isActive,
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
    String actorName = '';
    if (json['actor'] is Map) {
      final aMap = json['actor'] as Map;
      actorName = aMap['name']?.toString() ??
          aMap['username']?.toString() ??
          aMap['user_name']?.toString() ??
          '';
    } else if (json['actor'] != null) {
      actorName = json['actor'].toString();
    }
    final rawId = json['id'];
    final int idVal = rawId is num ? rawId.toInt() : (int.tryParse(rawId?.toString() ?? '') ?? 0);
    return TaskTimelineItem(
      id: idVal,
      kind: json['kind']?.toString() ?? json['action']?.toString() ?? '',
      note: json['note']?.toString() ?? json['description']?.toString() ?? json['message']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',
      actor: actorName,
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
  final String? legacyTaskNo;
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
  final int? ticketId;
  final String? ticketNo;
  final int subtasksTotal;
  final int subtasksCompleted;
  final int? parentTaskId;
  final String? parentTaskNo;
  final String? parentTitle;

  bool get isSubtask => parentTaskId != null || (parentTaskNo != null && parentTaskNo!.isNotEmpty);

  TaskItemModel({
    required this.id,
    required this.taskNo,
    this.legacyTaskNo,
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
    this.ticketId,
    this.ticketNo,
    this.subtasksTotal = 0,
    this.subtasksCompleted = 0,
    this.parentTaskId,
    this.parentTaskNo,
    this.parentTitle,
  });

  factory TaskItemModel.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    bool safeBool(dynamic value, [bool defaultValue = false]) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value == 1 || value == '1' || value == 'true') return true;
      if (value == 0 || value == '0' || value == 'false') return false;
      return defaultValue;
    }

    int totalSubtasks = 0;
    int doneSubtasks = 0;
    if (json['checklist'] is List) {
      final list = json['checklist'] as List;
      totalSubtasks = list.length;
      doneSubtasks = list.where((e) => e is Map && (e['is_completed'] == true || e['completed'] == true || e['status'] == 'completed' || e['done'] == true || e['is_completed'] == 1 || e['completed'] == 1)).length;
    } else if (json['subtasks'] is List) {
      final list = json['subtasks'] as List;
      totalSubtasks = list.length;
      doneSubtasks = list.where((e) => e is Map && (e['is_completed'] == true || e['completed'] == true || e['status'] == 'completed' || e['done'] == true || e['is_completed'] == 1 || e['completed'] == 1)).length;
    } else {
      totalSubtasks = safeInt(json['subtasks_total'] ?? json['subtask_count'] ?? json['subtasks_count']);
      doneSubtasks = safeInt(json['subtasks_completed'] ?? json['subtask_completed_count'] ?? json['subtasks_completed_count']);
    }

    String? ticketNumber = json['ticket_no']?.toString() ??
        (json['ticket'] is Map ? json['ticket']['ticket_no']?.toString() ?? json['ticket']['code']?.toString() : null) ??
        json['ticket_code']?.toString();
    int? ticketIdentifier;
    if (json['ticket_id'] != null) {
      ticketIdentifier = safeInt(json['ticket_id']);
    } else if (json['ticket'] is Map && json['ticket']['id'] != null) {
      ticketIdentifier = safeInt(json['ticket']['id']);
    }
    if (ticketNumber == null && ticketIdentifier != null && ticketIdentifier > 0) {
      ticketNumber = 'TKT-$ticketIdentifier';
    }

    return TaskItemModel(
      id: safeInt(json['id']),
      taskNo: json['task_no']?.toString() ?? json['taskNo']?.toString() ?? '',
      legacyTaskNo: json['legacy_task_no']?.toString(),
      fy: json['fy']?.toString() ?? '2025-26',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      priority: json['priority']?.toString() ?? 'high',
      status: json['status']?.toString() ?? 'to_be_started',
      progress: safeInt(json['progress']),
      location: json['location']?.toString(),
      entryDate: json['entry_date']?.toString() ?? json['entryDate']?.toString() ?? '',
      dueDate: json['due_date']?.toString() ?? json['dueDate']?.toString() ?? '',
      completedDate: json['completed_date']?.toString() ?? json['completedDate']?.toString(),
      remarks: json['remarks']?.toString(),
      isConfidential: safeBool(json['is_confidential'] ?? json['isConfidential']),
      blockReason: json['block_reason']?.toString() ?? json['blockReason']?.toString(),
      reviewComment: json['review_comment']?.toString() ?? json['reviewComment']?.toString(),
      assignedByText: json['assigned_by_text']?.toString() ?? json['assignedByText']?.toString() ?? '',
      assignedByUserId: safeInt(json['assigned_by_user_id'] ?? json['assignedByUserId']),
      assignedByName: json['assigned_by_name']?.toString() ?? json['assignedByName']?.toString() ?? '',
      branchId: safeInt(json['branch_id'] ?? json['branchId']),
      branchCode: json['branch_code']?.toString() ?? json['branchCode']?.toString() ?? '',
      branchName: json['branch_name']?.toString() ?? json['branchName']?.toString() ?? '',
      assignees: json['assignees'] is List
          ? (json['assignees'] as List)
              .map((e) => e is Map
                  ? TaskAssigneeModel.fromJson(Map<String, dynamic>.from(e))
                  : null)
              .whereType<TaskAssigneeModel>()
              .toList()
          : [],
      ticketId: ticketIdentifier,
      ticketNo: ticketNumber,
      subtasksTotal: totalSubtasks,
      subtasksCompleted: doneSubtasks,
      parentTaskId: json['parent_task_id'] != null
          ? safeInt(json['parent_task_id'])
          : (json['parentTaskId'] != null ? safeInt(json['parentTaskId']) : null),
      parentTaskNo: json['parent_task_no']?.toString() ?? json['parentTaskNo']?.toString(),
      parentTitle: json['parent_title']?.toString() ?? json['parentTitle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'task_no': taskNo,
        'legacy_task_no': legacyTaskNo,
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
        'ticket_id': ticketId,
        'ticket_no': ticketNo,
        'subtasks_total': subtasksTotal,
        'subtasks_completed': subtasksCompleted,
        'parent_task_id': parentTaskId,
        'parent_task_no': parentTaskNo,
        'parent_title': parentTitle,
      };
}

class TaskDetailModel extends TaskItemModel {
  final List<TaskTimelineItem> timeline;
  final List<dynamic> attachments;
  final List<dynamic> checklist;
  final List<TaskItemModel> subtasks;
  final String? ticketType;

  TaskDetailModel({
    required super.id,
    required super.taskNo,
    super.legacyTaskNo,
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
    super.ticketId,
    super.ticketNo,
    this.ticketType,
    super.subtasksTotal,
    super.subtasksCompleted,
    super.parentTaskId,
    super.parentTaskNo,
    super.parentTitle,
    required this.timeline,
    required this.attachments,
    required this.checklist,
    this.subtasks = const [],
  });

  factory TaskDetailModel.fromJson(dynamic rawData) {
    Map<String, dynamic> json;
    if (rawData is Map<String, dynamic>) {
      json = rawData;
    } else if (rawData is Map) {
      json = Map<String, dynamic>.from(rawData);
    } else {
      json = {};
    }
    if (json['data'] is Map) {
      json = Map<String, dynamic>.from(json['data'] as Map);
    } else if (json['task'] is Map) {
      json = Map<String, dynamic>.from(json['task'] as Map);
    }

    final baseTask = TaskItemModel.fromJson(json);
    final String? ticketNumber = baseTask.ticketNo ?? json['ticket_no']?.toString();
    final int? ticketIdentifier = baseTask.ticketId ??
        (json['ticket_id'] is num
            ? (json['ticket_id'] as num).toInt()
            : int.tryParse(json['ticket_id']?.toString() ?? ''));
    final String? tType = json['ticket_type']?.toString();

    return TaskDetailModel(
      id: baseTask.id,
      taskNo: baseTask.taskNo,
      legacyTaskNo: baseTask.legacyTaskNo,
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
      ticketId: ticketIdentifier,
      ticketNo: ticketNumber,
      ticketType: tType,
      subtasksTotal: baseTask.subtasksTotal,
      subtasksCompleted: baseTask.subtasksCompleted,
      parentTaskId: baseTask.parentTaskId,
      parentTaskNo: baseTask.parentTaskNo,
      timeline: json['timeline'] is List
          ? (json['timeline'] as List)
              .map((e) => e is Map
                  ? TaskTimelineItem.fromJson(Map<String, dynamic>.from(e))
                  : null)
              .whereType<TaskTimelineItem>()
              .toList()
          : [],
      attachments: json['attachments'] is List ? (json['attachments'] as List) : [],
      checklist: json['checklist'] is List ? (json['checklist'] as List) : [],
      subtasks: json['subtasks'] is List
          ? (json['subtasks'] as List)
              .map((e) => e is Map
                  ? TaskItemModel.fromJson(Map<String, dynamic>.from(e))
                  : null)
              .whereType<TaskItemModel>()
              .toList()
          : [],
    );
  }

  TaskDetailModel copyWithSubtasks(List<TaskItemModel> newSubtasks) {
    return TaskDetailModel(
      id: id,
      taskNo: taskNo,
      legacyTaskNo: legacyTaskNo,
      fy: fy,
      title: title,
      description: description,
      category: category,
      priority: priority,
      status: status,
      progress: progress,
      location: location,
      entryDate: entryDate,
      dueDate: dueDate,
      completedDate: completedDate,
      remarks: remarks,
      isConfidential: isConfidential,
      blockReason: blockReason,
      reviewComment: reviewComment,
      assignedByText: assignedByText,
      assignedByUserId: assignedByUserId,
      assignedByName: assignedByName,
      branchId: branchId,
      branchCode: branchCode,
      branchName: branchName,
      assignees: assignees,
      ticketId: ticketId,
      ticketNo: ticketNo,
      ticketType: ticketType,
      subtasksTotal: newSubtasks.length,
      subtasksCompleted: newSubtasks.where((s) => s.status == 'completed').length,
      parentTaskId: parentTaskId,
      parentTaskNo: parentTaskNo,
      parentTitle: parentTitle,
      timeline: timeline,
      attachments: attachments,
      checklist: checklist,
      subtasks: newSubtasks,
    );
  }
}

class TasksResponseModel {
  final List<TaskItemModel> items;
  final int total;
  final int inProgress;
  final int needsAction;
  final int needsReview;
  final int overdue;
  final int completed;
  final int dropped;
  final int limit;
  final int offset;

  TasksResponseModel({
    required this.items,
    required this.total,
    this.inProgress = 0,
    this.needsAction = 0,
    this.needsReview = 0,
    this.overdue = 0,
    this.completed = 0,
    this.dropped = 0,
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
      inProgress: json['inProgress'] as int? ?? json['in_progress'] as int? ?? 0,
      needsAction: json['needsAction'] as int? ?? json['needs_action'] as int? ?? json['to_be_started'] as int? ?? 0,
      needsReview: json['needsReview'] as int? ?? json['needs_review'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      dropped: json['dropped'] as int? ?? 0,
      limit: json['limit'] as int? ?? 80,
      offset: json['offset'] as int? ?? 0,
    );
  }
}
